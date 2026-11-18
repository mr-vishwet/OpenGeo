"""The HTTP surface.

Thin on purpose: routes normalize input, call the deterministic geography layer,
and wrap the result in the documented envelope. No route contains a predicate
implementation.
"""

from __future__ import annotations

import time
import uuid
from collections.abc import AsyncIterator, Callable
from contextlib import asynccontextmanager
from re import compile as compile_pattern
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from shapely.geometry import mapping

from .. import __version__
from ..capabilities import CapabilityManifest, build_manifest
from ..geo import (
    DistanceMethod,
    GeometryError,
    predicate,
    validate_geometry,
)
from ..geo import (
    distance as compute_distance,
)
from ..geo.units import DistanceUnit, convert
from .dataset import Feature, FeatureStore, load_default_store
from .errors import ApiError, ErrorCode
from .models import (
    MAX_RADIUS_M,
    ContainsRequest,
    DistanceRequest,
    DistanceResult,
    Envelope,
    IntersectsRequest,
    Meta,
    NearbyRequest,
    PlaceSummary,
    PredicateResult,
    Provenance,
    SpatialRequest,
)

API_VERSION = "v1"

# 8-64 characters of an id-safe alphabet: enough to correlate, nothing that can
# escape into a log line.
_REQUEST_ID = compile_pattern(r"[A-Za-z0-9._-]{8,64}")


def _meta(request: Request, store: FeatureStore | None = None) -> Meta:
    started: float = getattr(request.state, "started", time.perf_counter())
    return Meta(
        request_id=getattr(request.state, "request_id", "unknown"),
        api_version=API_VERSION,
        dataset_version=store.dataset_version if store else None,
        execution_ms=round((time.perf_counter() - started) * 1000, 3),
    )


def _envelope(
    request: Request,
    data: Any,
    store: FeatureStore,
    *,
    warnings: list[dict[str, str]] | None = None,
) -> dict[str, Any]:
    return {
        "data": data,
        "meta": _meta(request, store),
        "provenance": Provenance(
            sources=list(store.sources)
        ),
        "warnings": warnings or [],
    }


def _geometry_or_reject(value: dict[str, Any], *, field: str):
    try:
        return validate_geometry(value, path=field)
    except GeometryError as exc:
        raise ApiError(
            ErrorCode.INVALID_INPUT,
            exc.message,
            field=exc.path or field,
            details={"geometry_code": exc.code.value},
        ) from exc


def _place_summary(feature: Feature, store: FeatureStore, distance_m: float | None) -> PlaceSummary:
    return PlaceSummary(
        id=feature.id,
        name=feature.name,
        category=feature.category,
        geometry=mapping(feature.geometry),
        distance_m=None if distance_m is None else round(distance_m, 3),
        dataset_version=store.dataset_version,
        source=store.sources[0].name,
    )


def create_app(store_factory: Callable[[], FeatureStore] = load_default_store) -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        app.state.store = store_factory()
        yield

    app = FastAPI(
        title="OpenGeo API",
        version=__version__,
        description=(
            "Deterministic geospatial services. Coordinates are EPSG:4326, "
            "longitude first. Distances are metres with an explicit method."
        ),
        lifespan=lifespan,
    )

    @app.middleware("http")
    async def stamp_request(request: Request, call_next):
        # Echo a caller-supplied id so a client report and a log line meet, but
        # only in a shape that cannot inject into a log.
        supplied = request.headers.get("x-request-id", "")
        request.state.request_id = (
            supplied if _REQUEST_ID.fullmatch(supplied) else uuid.uuid4().hex
        )
        request.state.started = time.perf_counter()
        response = await call_next(request)
        response.headers["X-Request-Id"] = request.state.request_id
        return response

    @app.exception_handler(ApiError)
    async def handle_api_error(request: Request, exc: ApiError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.http_status,
            content={
                "data": None,
                "meta": _meta(request).model_dump(mode="json"),
                "errors": [exc.as_body()],
            },
        )

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        first = exc.errors()[0] if exc.errors() else {}
        location = ".".join(str(part) for part in first.get("loc", ()) if part != "body")
        return JSONResponse(
            status_code=422,
            content={
                "data": None,
                "meta": _meta(request).model_dump(mode="json"),
                "errors": [
                    {
                        "code": ErrorCode.INVALID_INPUT.value,
                        "message": first.get("msg", "invalid request"),
                        "field": location or None,
                    }
                ],
            },
        )

    def store(request: Request) -> FeatureStore:
        return request.app.state.store

    @app.get("/healthz", tags=["ops"])
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/readyz", tags=["ops"])
    async def readyz(request: Request) -> dict[str, Any]:
        current = store(request)
        ready = len(current.features()) > 0
        is_postgres = getattr(current, "region", None) is not None
        return {
            "status": "ready" if ready else "degraded",
            "checks": {
                "feature_store": "ok" if ready else "empty",
                "spatial_index": "configured" if is_postgres else "not_configured",
                "database": "attached" if is_postgres else "not_attached",
            },
        }

    @app.get("/v1/capabilities", response_model=CapabilityManifest, tags=["meta"])
    async def capabilities(request: Request) -> CapabilityManifest:
        return build_manifest(store(request))

    @app.get("/v1/datasets", tags=["meta"])
    async def datasets(request: Request) -> dict[str, Any]:
        current = store(request)
        return _envelope(
            request,
            [
                {
                    "region": "Pune, Maharashtra (synthetic fixture)",
                    "dataset_version": current.dataset_version,
                    "feature_count": len(current.features()),
                }
            ],
            current,
        )

    @app.get("/v1/places/{feature_id}", tags=["places"])
    async def get_place(request: Request, feature_id: str) -> dict[str, Any]:
        current = store(request)
        feature = current.get(feature_id)
        if feature is None:
            raise ApiError(ErrorCode.NOT_FOUND, f"no place with id '{feature_id}'")
        return _envelope(request, _place_summary(feature, current, None), current)

    @app.post("/v1/nearby", tags=["spatial"])
    async def nearby(request: Request, body: NearbyRequest) -> dict[str, Any]:
        current = store(request)
        radius_m = body.radius.metres
        if radius_m > MAX_RADIUS_M:
            raise ApiError(
                ErrorCode.INVALID_INPUT,
                f"radius {radius_m:.0f} m exceeds the {MAX_RADIUS_M} m maximum",
                field="radius",
                hint="request a smaller radius or use a tiled query for large areas",
            )

        hits = current.nearby(
            body.center.as_lonlat(), radius_m, body.categories
        )[: body.limit]
        data = []
        for feature_id, metres in hits:
            feature = current.get(feature_id)
            if feature is not None:
                data.append(_place_summary(feature, current, metres))
        return _envelope(request, data, current)

    @app.post("/v1/spatial/distance", response_model=Envelope[DistanceResult], tags=["spatial"])
    async def spatial_distance(request: Request, body: DistanceRequest) -> dict[str, Any]:
        current = store(request)
        if body.method is DistanceMethod.NETWORK_TRAVEL:
            raise ApiError(
                ErrorCode.UNSUPPORTED_CAPABILITY,
                "network travel distance is unavailable",
                hint="no routing engine is configured in this deployment",
            )
        try:
            metres = compute_distance(
                body.origin.as_lonlat(), body.destination.as_lonlat(), method=body.method
            )
        except ValueError as exc:
            raise ApiError(ErrorCode.UNSUPPORTED_CAPABILITY, str(exc)) from exc

        result = DistanceResult(
            value=round(convert(metres, DistanceUnit.METRE, body.unit), 3),
            unit=body.unit,
            method=body.method,
        )
        return _envelope(request, result.model_dump(mode="json"), current)

    def _resolve_container(request: Request, body: SpatialRequest):
        current = store(request)
        if body.container is not None:
            return _geometry_or_reject(body.container, field="container")
        if body.container_feature_id is not None:
            feature = current.get(body.container_feature_id)
            if feature is None:
                raise ApiError(
                    ErrorCode.NOT_FOUND,
                    f"no feature with id '{body.container_feature_id}'",
                    field="container_feature_id",
                )
            return feature.geometry
        raise ApiError(
            ErrorCode.INVALID_INPUT,
            "container or container_feature_id is required",
            field="container",
        )

    @app.post("/v1/spatial/contains", tags=["spatial"])
    async def spatial_contains(request: Request, body: ContainsRequest) -> dict[str, Any]:
        current = store(request)
        container = _resolve_container(request, body)
        if body.candidate_position is not None:
            candidate = {
                "type": "Point",
                "coordinates": [
                    body.candidate_position.longitude,
                    body.candidate_position.latitude,
                ],
            }
        elif body.candidate is not None:
            candidate = body.candidate
        else:
            raise ApiError(
                ErrorCode.INVALID_INPUT,
                "candidate or candidate_position is required",
                field="candidate",
            )
        result = predicate(
            body.boundary_rule, container, _geometry_or_reject(candidate, field="candidate")
        )
        return _envelope(
            request,
            PredicateResult(
                predicate=body.boundary_rule, result=result, boundary_rule=body.boundary_rule
            ).model_dump(mode="json"),
            current,
        )

    @app.post("/v1/spatial/intersects", tags=["spatial"])
    async def spatial_intersects(request: Request, body: IntersectsRequest) -> dict[str, Any]:
        current = store(request)
        container = _resolve_container(request, body)
        if body.candidate is None:
            raise ApiError(
                ErrorCode.INVALID_INPUT, "candidate geometry is required", field="candidate"
            )
        result = predicate(
            "intersects", container, _geometry_or_reject(body.candidate, field="candidate")
        )
        return _envelope(
            request,
            PredicateResult(predicate="intersects", result=result).model_dump(mode="json"),
            current,
        )

    return app


app = create_app()

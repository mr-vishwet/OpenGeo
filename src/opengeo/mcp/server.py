"""The MCP server.

Transport and session handling live here; geography does not. Each tool calls
the same validation, predicate and store code the HTTP service calls, so an
answer cannot differ between REST and MCP.

Run with stdio (what an MCP host expects):

    python -m opengeo.mcp.server
"""

from __future__ import annotations

import asyncio
from typing import Any

from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError

from .. import __version__
from ..api.dataset import FeatureStore, load_default_store
from ..api.models import MAX_LIMIT, MAX_RADIUS_M, Position, Radius
from ..geo import DistanceMethod, GeometryError, predicate, validate_geometry, within_radius
from ..geo.predicates import distance as compute_distance
from ..geo.units import DistanceUnit, convert

INSTRUCTIONS = (
    "OpenGeo serves deterministic geography. Coordinates are EPSG:4326 with longitude "
    "first. Distances are straight-line metres unless a unit is requested; there is no "
    "routing engine, so travel time and road distance are unavailable and must not be "
    "substituted with straight-line distance. Every geometry you pass is validated "
    "before it is used. Report the dataset_version you receive with any answer that "
    "depends on place data."
)

NEARBY_DESCRIPTION = (
    "Find points of interest within a radius of a position, nearest first. Returns "
    "distance_m per place. Not a routing or travel-time answer."
)

DISTANCE_DESCRIPTION = (
    "Straight-line distance between two positions. This is not travel distance."
)

CONTAINS_DESCRIPTION = (
    "Whether a candidate geometry lies inside a container geometry. boundary_rule "
    "'contains' excludes the boundary, 'covers' includes it. Do not guess; call it."
)

INTERSECTS_DESCRIPTION = "Whether two geometries share any point."


def _geometry(value: dict[str, Any], field: str):
    try:
        return validate_geometry(value, path=field)
    except GeometryError as exc:
        raise ToolError(f"{exc.code.value}: {exc.message}") from exc


def build_server(store: FeatureStore | None = None) -> MCPServer:
    feature_store = store if store is not None else load_default_store()

    server = MCPServer(
        name="opengeo",
        title="OpenGeo",
        version=__version__,
        instructions=INSTRUCTIONS,
    )

    @server.tool(name="geo.nearby", description=NEARBY_DESCRIPTION)
    async def geo_nearby(
        center: Position,
        radius: Radius,
        categories: list[str] | None = None,
        limit: int = 20,
    ) -> dict[str, Any]:
        radius_m = radius.metres
        if radius_m > MAX_RADIUS_M:
            raise ToolError(
                f"invalid_input: radius {radius_m:.0f} m exceeds the {MAX_RADIUS_M} m maximum"
            )
        if limit < 1 or limit > MAX_LIMIT:
            raise ToolError(f"invalid_input: limit must be between 1 and {MAX_LIMIT}")

        wanted = {category.lower() for category in (categories or [])}
        candidates = [
            (feature.id, feature.geometry)
            for feature in feature_store.features()
            if feature.geometry.geom_type == "Point"
            and (not wanted or (feature.category or "").lower() in wanted)
        ]
        hits = within_radius(center.as_lonlat(), radius_m, candidates)[:limit]

        places = []
        for feature_id, metres in hits:
            feature = feature_store.get(feature_id)
            if feature is None:
                continue
            address = {
                key: feature.properties[key]
                for key in ("house_number", "street", "locality", "region", "postal_code")
                if key in feature.properties
            }
            places.append(
                {
                    "id": feature.id,
                    "name": feature.name,
                    "category": feature.category,
                    "longitude": feature.geometry.x,
                    "latitude": feature.geometry.y,
                    "distance_m": round(metres, 3),
                    "address": address,
                }
            )
        return {
            "places": places,
            "radius_m": radius_m,
            "dataset_version": feature_store.dataset_version,
            "source": feature_store.sources[0].name,
        }

    @server.tool(name="geo.distance", description=DISTANCE_DESCRIPTION)
    async def geo_distance(
        origin: Position,
        destination: Position,
        unit: DistanceUnit = DistanceUnit.METRE,
    ) -> dict[str, Any]:
        try:
            metres = compute_distance(
                origin.as_lonlat(), destination.as_lonlat(), method=DistanceMethod.GEODESIC
            )
        except ValueError as exc:  # pragma: no cover - geodesy only raises on bad input
            raise ToolError(f"invalid_input: {exc}") from exc
        return {
            "value": round(convert(metres, DistanceUnit.METRE, unit), 3),
            "unit": unit.value,
            "method": DistanceMethod.GEODESIC.value,
        }

    @server.tool(name="geo.contains", description=CONTAINS_DESCRIPTION)
    async def geo_contains(
        container: dict[str, Any],
        candidate: dict[str, Any],
        boundary_rule: str = "covers",
    ) -> dict[str, Any]:
        if boundary_rule not in {"contains", "covers"}:
            raise ToolError("invalid_input: boundary_rule must be 'contains' or 'covers'")
        result = predicate(
            boundary_rule,
            _geometry(container, "container"),
            _geometry(candidate, "candidate"),
        )
        return {"predicate": boundary_rule, "result": result}

    @server.tool(name="geo.intersects", description=INTERSECTS_DESCRIPTION)
    async def geo_intersects(
        a: dict[str, Any], b: dict[str, Any]
    ) -> dict[str, Any]:
        return {
            "predicate": "intersects",
            "result": predicate("intersects", _geometry(a, "a"), _geometry(b, "b")),
        }

    return server


def main() -> None:
    asyncio.run(build_server().run_stdio_async())


if __name__ == "__main__":
    main()

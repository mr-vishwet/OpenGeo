"""Capability manifest.

The manifest exists so an agent or client never infers that a capability works
because an endpoint or a tool name exists. Every entry states what is actually
true of this deployment, including the parts that are missing.
"""

from __future__ import annotations

from enum import StrEnum

from pydantic import BaseModel

from . import __version__
from .api.dataset import FeatureStore
from .api.models import MAX_LIMIT, MAX_RADIUS_M


class CapabilityState(StrEnum):
    IMPLEMENTED = "implemented"
    CONFIGURED = "configured"
    REGION_AVAILABLE = "region_available"
    REQUIRES_MODULE = "requires_optional_module"
    REQUIRES_EXTERNAL = "requires_external_provider"
    PLANNED = "planned"
    UNAVAILABLE = "unavailable"


class Capability(BaseModel):
    name: str
    state: CapabilityState
    note: str | None = None


class RegionCoverage(BaseModel):
    region: str
    dataset_version: str | None
    feature_count: int
    categories: list[str]
    authoritative_store: str


class CapabilityManifest(BaseModel):
    service: str = "opengeo-api"
    version: str
    api_versions: list[str]
    coordinate_systems: list[str]
    regions: list[RegionCoverage]
    routing_modes: list[str]
    tile_formats: list[str]
    offline_support: bool
    limits: dict[str, str]
    auth: str
    attribution: list[str]
    capabilities: list[Capability]
    warnings: list[str]


def build_manifest(store: FeatureStore) -> CapabilityManifest:
    features = list(store.features())
    categories = sorted({f.category for f in features if f.category})

    capabilities = [
        Capability(
            name="spatial.distance",
            state=CapabilityState.IMPLEMENTED,
            note="Ellipsoidal WGS84 distance. Network distance needs a routing engine.",
        ),
        Capability(
            name="spatial.contains",
            state=CapabilityState.IMPLEMENTED,
            note="Boundary excluded. Reference path runs on GEOS, not on an index.",
        ),
        Capability(
            name="spatial.covers",
            state=CapabilityState.IMPLEMENTED,
            note="Boundary included. Reference path runs on GEOS, not on an index.",
        ),
        Capability(
            name="spatial.intersects",
            state=CapabilityState.IMPLEMENTED,
            note="Reference path runs on GEOS, not on an index.",
        ),
        Capability(
            name="nearby",
            state=CapabilityState.IMPLEMENTED,
            note="Linear scan over the fixture store; no spatial index until PostGIS is attached.",
        ),
        Capability(
            name="places.get",
            state=CapabilityState.IMPLEMENTED,
        ),
        Capability(
            name="postgis",
            state=CapabilityState.UNAVAILABLE,
            note="No database attached. ADR-0003 makes PostGIS the served authority.",
        ),
        Capability(
            name="search",
            state=CapabilityState.UNAVAILABLE,
            note="No search or geocoding engine is configured.",
        ),
        Capability(
            name="geocoding",
            state=CapabilityState.UNAVAILABLE,
            note="Candidate engine (Pelias) not yet evaluated. See ADR-0005.",
        ),
        Capability(
            name="routing",
            state=CapabilityState.REQUIRES_EXTERNAL,
            note="RoutingProvider contract defined; no engine attached.",
        ),
        Capability(
            name="tiles",
            state=CapabilityState.REQUIRES_MODULE,
            note="Tile delivery is a separate module and dataset release.",
        ),
        Capability(
            name="offline",
            state=CapabilityState.REQUIRES_MODULE,
            note="Offline packs are planned; no pack is published.",
        ),
        Capability(
            name="mcp",
            state=CapabilityState.REQUIRES_MODULE,
            note="stdio server publishes four spatial tools; no network transport is deployed.",
        ),
    ]

    return CapabilityManifest(
        version=__version__,
        api_versions=["v1"],
        coordinate_systems=["EPSG:4326"],
        regions=[
            RegionCoverage(
                region="Pune, Maharashtra (synthetic fixture)",
                dataset_version=store.dataset_version,
                feature_count=len(features),
                categories=categories,
                authoritative_store="geojson-fixture",
            )
        ],
        routing_modes=[],
        tile_formats=[],
        offline_support=False,
        limits={
            "max_radius_m": str(MAX_RADIUS_M),
            "max_result_limit": str(MAX_LIMIT),
            "coordinate_order": "longitude, latitude (EPSG:4326)",
        },
        auth="none: local development deployment, no protected operation exposed",
        attribution=[
            source.attribution for source in store.sources
        ],
        capabilities=capabilities,
        warnings=[
            "This deployment serves a synthetic fixture, not a regional extract.",
            "No spatial index is in use. Latency and result quality claims are not valid here.",
        ],
    )

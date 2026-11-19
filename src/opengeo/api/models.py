"""Request and response models.

Positions are named objects, never bare arrays, so a client cannot swap
longitude and latitude without the schema rejecting it.
"""

from __future__ import annotations

from typing import Any, Generic, Literal, TypeVar

from pydantic import BaseModel, ConfigDict, Field, model_validator

from ..geo import LonLat
from ..geo.units import DistanceMethod, DistanceUnit

T = TypeVar("T")

MAX_RADIUS_M = 50_000
MAX_LIMIT = 100


class Position(BaseModel):
    model_config = ConfigDict(extra="forbid")

    longitude: float = Field(..., ge=-180, le=180)
    latitude: float = Field(..., ge=-90, le=90)
    altitude: float | None = None

    def as_lonlat(self) -> LonLat:
        return LonLat(self.longitude, self.latitude)


class Radius(BaseModel):
    model_config = ConfigDict(extra="forbid")

    value: float = Field(..., gt=0)
    unit: DistanceUnit = DistanceUnit.METRE

    @property
    def metres(self) -> float:
        from ..geo.units import to_metres

        return to_metres(self.value, self.unit)


class SourceAttribution(BaseModel):
    name: str
    license: str
    url: str | None = None
    attribution: str


class Provenance(BaseModel):
    sources: list[SourceAttribution] = []


class Meta(BaseModel):
    request_id: str
    api_version: str = "v1"
    dataset_version: str | None = None
    execution_ms: float


class Warning_(BaseModel):
    code: str
    message: str


class Envelope(BaseModel, Generic[T]):
    data: T
    meta: Meta
    provenance: Provenance = Provenance()
    warnings: list[Warning_] = []


class NearbyRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    center: Position
    radius: Radius
    categories: list[str] = Field(default_factory=list)
    limit: int = Field(20, ge=1, le=MAX_LIMIT)


class PlaceSummary(BaseModel):
    """Response shape for a place reference. Kept as a model so the contract is
    generated, not hand-written."""

    id: str
    name: str | None = None
    category: str | None = None
    geometry: dict[str, Any]
    distance_m: float | None = None
    dataset_version: str | None = None
    source: str | None = None


class DistanceRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    origin: Position
    destination: Position
    method: DistanceMethod = DistanceMethod.GEODESIC
    unit: DistanceUnit = DistanceUnit.METRE


class DistanceResult(BaseModel):
    value: float
    unit: DistanceUnit
    method: DistanceMethod


class SpatialRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    container: dict[str, Any] | None = None
    container_feature_id: str | None = None
    candidate: dict[str, Any] | None = None
    candidate_position: Position | None = None

    @model_validator(mode="after")
    def _reject_ambiguous_input(self) -> SpatialRequest:
        """Two ways to name one input is an ambiguity, not a precedence rule.

        Picking one silently would answer a question the caller did not ask.
        """
        if self.container is not None and self.container_feature_id is not None:
            raise ValueError("container and container_feature_id are mutually exclusive")
        if self.candidate is not None and self.candidate_position is not None:
            raise ValueError("candidate and candidate_position are mutually exclusive")
        return self


class ContainsRequest(SpatialRequest):
    boundary_rule: Literal["contains", "covers"] = "covers"


class IntersectsRequest(SpatialRequest):
    pass


class PredicateResult(BaseModel):
    predicate: str
    result: bool
    boundary_rule: str | None = None


class SearchRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    query: str
    limit: int = Field(10, ge=1, le=100)
    bounds: list[float] | None = Field(None, min_length=4, max_length=4)


class SearchResult(BaseModel):
    label: str
    longitude: float
    latitude: float
    source: str
    confidence: float | None = None


class RouteRequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    origin: Position
    destination: Position
    profile: str = "car"


class RouteResultModel(BaseModel):
    distance_m: float
    duration_s: float
    geometry: list[list[float]]
    source: str


class TileRequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    z: int = Field(ge=0, le=22)
    x: int = Field(ge=0)
    y: int = Field(ge=0)


class TileResultModel(BaseModel):
    data: str  # base64-encoded MVT
    content_type: str = "application/vnd.mapbox-vector-tile"

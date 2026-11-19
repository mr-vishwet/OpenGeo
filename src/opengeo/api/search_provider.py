"""Search / geocoding provider interface.

Implementations wrap an external geocoding service (Pelias, Photon, Nominatim,
open-geocode-rs, …) and translate between OpenGeo's request/response shapes and
the provider's API. Until an engine is attached, `UnimplementedSearchProvider`
refuses every request with `unsupported_capability`.

See ADR-0005 for the provider selection decision.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass

from ..api.errors import ApiError, ErrorCode


@dataclass(frozen=True)
class GeocodeRequest:
    query: str
    limit: int = 10
    bounds: tuple[float, float, float, float] | None = None  # west, south, east, north


@dataclass(frozen=True)
class GeocodeResult:
    label: str
    longitude: float
    latitude: float
    source: str
    confidence: float | None = None


class SearchProvider(ABC):
    """Geocoding / search provider interface."""

    @abstractmethod
    def geocode(self, request: GeocodeRequest) -> list[GeocodeResult]:
        """Forward-geocode a free-text query to a list of results."""


class UnimplementedSearchProvider(SearchProvider):
    """Search provider that refuses every request until an engine is attached."""

    def geocode(self, request: GeocodeRequest) -> list[GeocodeResult]:
        raise ApiError(
            ErrorCode.UNSUPPORTED_CAPABILITY,
            "search is unavailable",
            hint="no search or geocoding engine is configured. See ADR-0005.",
        )

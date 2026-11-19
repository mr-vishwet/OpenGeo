"""Routing provider interface and implementations.

Implementations wrap an external routing engine (OSRM, Valhalla, GraphHopper,
…) and translate between OpenGeo's request/response shapes and the provider's
API. Until an engine is attached, `UnimplementedRoutingProvider` refuses every
request with `unsupported_capability`.

See ADR-0005 for the provider selection decision.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass

from ..api.errors import ApiError, ErrorCode


@dataclass(frozen=True)
class RouteRequest:
    origin_longitude: float
    origin_latitude: float
    destination_longitude: float
    destination_latitude: float
    profile: str = "car"  # car, foot, bicycle, truck


@dataclass(frozen=True)
class RouteResult:
    distance_m: float
    duration_s: float
    geometry: list[tuple[float, float]]  # [(lon, lat), ...] polyline
    source: str


class RoutingProvider(ABC):
    """Routing provider interface."""

    @abstractmethod
    def route(self, request: RouteRequest) -> RouteResult:
        """Compute a route between origin and destination."""


class UnimplementedRoutingProvider(RoutingProvider):
    """Routing provider that refuses every request until an engine is attached."""

    def route(self, request: RouteRequest) -> RouteResult:
        raise ApiError(
            ErrorCode.UNSUPPORTED_CAPABILITY,
            "routing is unavailable",
            hint="no routing engine is configured. See ADR-0005.",
        )

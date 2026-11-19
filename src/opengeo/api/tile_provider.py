"""Tile provider interface and implementations.

Implementations wrap an external tile server (Martin, Tegola, …) or generate
vector tiles directly from PostGIS (via ST_AsMVT). Until an engine is attached,
`UnimplementedTileProvider` refuses every request with
`unsupported_capability`.

See ADR-0004 for the tile delivery decision.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass

from ..api.errors import ApiError, ErrorCode


@dataclass(frozen=True)
class TileRequest:
    z: int
    x: int
    y: int


@dataclass(frozen=True)
class TileResult:
    data: bytes  # Mapbox Vector Tile (MVT) payload
    content_type: str = "application/vnd.mapbox-vector-tile"


class TileProvider(ABC):
    """Tile provider interface."""

    @abstractmethod
    def tile(self, request: TileRequest) -> TileResult:
        """Return a vector tile for the given zoom/x/y."""


class UnimplementedTileProvider(TileProvider):
    """Tile provider that refuses every request until a tile server is attached."""

    def tile(self, request: TileRequest) -> TileResult:
        raise ApiError(
            ErrorCode.UNSUPPORTED_CAPABILITY,
            "tiles are unavailable",
            hint="tile delivery is a separate module and dataset release.",
        )

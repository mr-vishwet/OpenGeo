"""A position in EPSG:4326, longitude first.

Named fields rather than positional floats so that a swap is visible at the call
site. Range checking happens in :mod:`opengeo.geo.validation`.
"""

from __future__ import annotations

from typing import NamedTuple


class LonLat(NamedTuple):
    longitude: float
    latitude: float

    def __str__(self) -> str:  # pragma: no cover - diagnostics only
        return f"({self.longitude}, {self.latitude})"

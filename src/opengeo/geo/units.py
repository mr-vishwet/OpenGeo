"""Units and measurement methods.

A distance without a unit and a method is not a distance. `networkTravel`
cannot be converted to metres because it is already a path length produced by a
routing engine.
"""

from __future__ import annotations

from enum import StrEnum


class DistanceUnit(StrEnum):
    METRE = "m"
    KILOMETRE = "km"
    MILE = "mi"
    NAUTICAL_MILE = "nmi"


METRES_PER_UNIT: dict[DistanceUnit, float] = {
    DistanceUnit.METRE: 1.0,
    DistanceUnit.KILOMETRE: 1000.0,
    DistanceUnit.MILE: 1609.344,
    DistanceUnit.NAUTICAL_MILE: 1852.0,
}


class DistanceMethod(StrEnum):
    """How a distance was produced. Never inferred, always reported."""

    GEODESIC = "geodesic"
    PROJECTED_PLANAR = "projected_planar"
    NETWORK_TRAVEL = "network_travel"


def to_metres(value: float, unit: DistanceUnit) -> float:
    if value != value or value in (float("inf"), float("-inf")):
        raise ValueError("distance value must be finite")
    return value * METRES_PER_UNIT[unit]


def convert(value: float, unit: DistanceUnit, target: DistanceUnit) -> float:
    return to_metres(value, unit) / METRES_PER_UNIT[target]

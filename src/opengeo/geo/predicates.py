"""Deterministic spatial operations.

Semantics match PostGIS so the reference path and the database path cannot
disagree:

``contains``   boundary excluded (ST_Contains)
``covers``     boundary included (ST_Covers)
``intersects`` any shared point (ST_Intersects)

The reference path here runs on GEOS through shapely. When a dataset is
attached, PostGIS is authoritative and this module is used for validation, plan
checking and tests.
"""

from __future__ import annotations

from collections.abc import Iterable

from shapely.geometry.base import BaseGeometry

from .coordinates import LonLat
from .geodesy import haversine, vincenty_inverse
from .units import DistanceMethod


def geodesic_distance(a: LonLat, b: LonLat, *, ellipsoidal: bool = True) -> float:
    """Distance in metres between two positions.

    Ellipsoidal by default so the number matches a consumer map application.
    Spherical only when a caller asks for cheap candidate filtering.
    """
    if ellipsoidal:
        try:
            return vincenty_inverse(a.longitude, a.latitude, b.longitude, b.latitude)
        except ValueError:
            return haversine(a.longitude, a.latitude, b.longitude, b.latitude)
    return haversine(a.longitude, a.latitude, b.longitude, b.latitude)


def distance(a: LonLat, b: LonLat, *, method: DistanceMethod = DistanceMethod.GEODESIC) -> float:
    """Metres between two positions under the declared method."""
    if method is DistanceMethod.PROJECTED_PLANAR:
        raise ValueError(
            "projected_planar distance needs a projected CRS and an explicit unit; "
            "it cannot be computed from degrees"
        )
    if method is DistanceMethod.NETWORK_TRAVEL:
        raise ValueError("network_travel distance requires a routing engine")
    return geodesic_distance(a, b)


def contains(container: BaseGeometry, candidate: BaseGeometry) -> bool:
    """True when candidate lies inside container, excluding the boundary."""
    return bool(container.contains(candidate))


def covers(container: BaseGeometry, candidate: BaseGeometry) -> bool:
    """True when candidate lies inside container, including the boundary."""
    return bool(container.covers(candidate))


def intersects(a: BaseGeometry, b: BaseGeometry) -> bool:
    return bool(a.intersects(b))


def predicate(name: str, container: BaseGeometry, candidate: BaseGeometry) -> bool:
    """Dispatch a public predicate name. Unknown names are an error, never a
    silent False."""
    match name:
        case "contains":
            return contains(container, candidate)
        case "covers":
            return covers(container, candidate)
        case "intersects":
            return intersects(container, candidate)
        case _:
            raise ValueError(f"unsupported predicate '{name}'")


def within_radius(
    center: LonLat,
    radius_m: float,
    candidates: Iterable[tuple[str, BaseGeometry]],
    *,
    boundary: str = "covers",
) -> list[tuple[str, float]]:
    """Point features within ``radius_m`` of ``center``, nearest first.

    ``boundary="covers"`` includes features exactly on the radius;
    ``boundary="contains"`` excludes them.

    shortcut: candidates must be Points. Polygonal proximity needs PostGIS
    ``ST_DWithin(geography)``, which measures to the nearest point of a shape.
    Upgrade when features other than POIs are radius-searched.
    """
    if radius_m <= 0:
        raise ValueError("radius must be positive")
    if boundary not in ("contains", "covers"):
        raise ValueError(f"unsupported radius boundary '{boundary}'")
    hits: list[tuple[str, float]] = []
    for feature_id, geometry in candidates:
        if geometry.geom_type != "Point":
            raise ValueError("within_radius reference path accepts Point geometries only")
        metres = geodesic_distance(center, LonLat(geometry.x, geometry.y))
        if metres < radius_m or (boundary == "covers" and metres == radius_m):
            hits.append((feature_id, metres))
    hits.sort(key=lambda hit: hit[1])
    return hits


def nearest(
    center: LonLat, candidates: Iterable[tuple[str, BaseGeometry]]
) -> tuple[str, float] | None:
    """Nearest point feature and its distance in metres, or None when empty."""
    best: tuple[str, float] | None = None
    for feature_id, geometry in candidates:
        if geometry.geom_type != "Point":
            raise ValueError("nearest reference path accepts Point geometries only")
        metres = geodesic_distance(center, LonLat(geometry.x, geometry.y))
        if best is None or metres < best[1]:
            best = (feature_id, metres)
    return best

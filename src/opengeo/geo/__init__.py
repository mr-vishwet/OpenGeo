"""Deterministic geography. No HTTP, no renderer, no database session."""

from .coordinates import LonLat
from .geodesy import haversine, vincenty_inverse
from .predicates import (
    contains,
    covers,
    distance,
    geodesic_distance,
    intersects,
    nearest,
    predicate,
    within_radius,
)
from .units import DistanceMethod, DistanceUnit, convert, to_metres
from .validation import (
    GeoErrorCode,
    GeometryError,
    as_lonlat,
    validate_feature,
    validate_geometry,
)

__all__ = [
    "DistanceMethod",
    "DistanceUnit",
    "GeoErrorCode",
    "GeometryError",
    "LonLat",
    "as_lonlat",
    "contains",
    "convert",
    "covers",
    "distance",
    "geodesic_distance",
    "haversine",
    "intersects",
    "nearest",
    "predicate",
    "to_metres",
    "validate_feature",
    "validate_geometry",
    "vincenty_inverse",
    "within_radius",
]

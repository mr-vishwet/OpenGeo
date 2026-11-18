"""The geometry trust boundary.

Everything that arrives from a client, an ingest extract, an asset manifest or a
model-generated plan passes through here before any predicate touches it. Codes
are stable and snake_case so an SDK can branch on them without reading prose.

GEOS does the validity decision. This module adds the checks GEOS does not make:
coordinate order and range, ring closure as authored, and position arity.
"""

from __future__ import annotations

from collections.abc import Mapping
from enum import StrEnum
from math import isfinite
from typing import Any

from shapely.errors import GEOSException
from shapely.geometry import shape
from shapely.geometry.base import BaseGeometry
from shapely.validation import explain_validity

from .coordinates import LonLat

RING_CLOSURE_EPSILON = 1e-9


class GeoErrorCode(StrEnum):
    INVALID_COORDINATE = "invalid_coordinate"
    INVALID_GEOMETRY = "invalid_geometry"
    INVALID_RING = "invalid_ring"
    DEGENERATE_RING = "degenerate_ring"
    EMPTY_GEOMETRY = "empty_geometry"
    UNSUPPORTED_GEOMETRY_TYPE = "unsupported_geometry_type"
    MALFORMED_GEOJSON = "malformed_geojson"
    UNSUPPORTED_CRS = "unsupported_crs"


class GeometryError(ValueError):
    """A rejected input, carrying a stable code and the failing JSON path."""

    def __init__(self, code: GeoErrorCode, message: str, *, path: str | None = None):
        self.code = code
        self.message = message
        self.path = path
        super().__init__(f"{code.value}: {message}" + (f" at {path}" if path else ""))

    def as_error(self) -> dict[str, Any]:
        error: dict[str, Any] = {"code": self.code.value, "message": self.message}
        if self.path:
            error["path"] = self.path
        return error


_POSITION_GEOMETRIES = ("Point", "MultiPoint", "LineString", "MultiLineString",
                        "Polygon", "MultiPolygon")
_SUPPORTED = {*_POSITION_GEOMETRIES, "GeometryCollection"}


def _check_position(raw: Any, path: str) -> None:
    if not isinstance(raw, (list, tuple)):
        raise GeometryError(GeoErrorCode.MALFORMED_GEOJSON, "position must be an array", path=path)
    if len(raw) < 2 or len(raw) > 3:
        raise GeometryError(
            GeoErrorCode.MALFORMED_GEOJSON,
            f"position needs 2 or 3 numbers, got {len(raw)}",
            path=path,
        )
    for value in raw:
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise GeometryError(
                GeoErrorCode.MALFORMED_GEOJSON, "position members must be numbers", path=path
            )
        if not isfinite(value):
            raise GeometryError(
                GeoErrorCode.INVALID_COORDINATE, "coordinate must be finite", path=path
            )
    longitude, latitude = float(raw[0]), float(raw[1])
    if not -180 <= longitude <= 180:
        raise GeometryError(
            GeoErrorCode.INVALID_COORDINATE,
            f"longitude {longitude} outside [-180, 180]; a value near ±90 usually means the "
            "pair is swapped",
            path=path,
        )
    if not -90 <= latitude <= 90:
        raise GeometryError(
            GeoErrorCode.INVALID_COORDINATE,
            f"latitude {latitude} outside [-90, 90]; a value near ±180 usually means the "
            "pair is swapped",
            path=path,
        )


def _check_ring(ring: Any, path: str) -> None:
    if not isinstance(ring, (list, tuple)) or len(ring) < 4:
        raise GeometryError(
            GeoErrorCode.INVALID_RING,
            f"a linear ring needs at least 4 positions, got {len(ring or [])}",
            path=path,
        )
    for index, position in enumerate(ring):
        _check_position(position, f"{path}[{index}]")
    first, last = ring[0], ring[-1]
    if abs(first[0] - last[0]) > RING_CLOSURE_EPSILON or (
        abs(first[1] - last[1]) > RING_CLOSURE_EPSILON
    ):
        raise GeometryError(
            GeoErrorCode.INVALID_RING,
            "ring is not closed: first and last position differ",
            path=path,
        )


def _check_rings(rings: Any, path: str) -> None:
    if not isinstance(rings, (list, tuple)) or not rings:
        raise GeometryError(GeoErrorCode.INVALID_RING, "polygon needs a shell ring", path=path)
    for index, ring in enumerate(rings):
        _check_ring(ring, f"{path}[{index}]")


def _check_coordinates(geometry_type: str, coordinates: Any, path: str) -> None:
    match geometry_type:
        case "Point":
            _check_position(coordinates, path)
        case "MultiPoint" | "LineString":
            _check_positions(coordinates, path)
            if geometry_type == "LineString" and len(coordinates) < 2:
                raise GeometryError(
                    GeoErrorCode.INVALID_GEOMETRY, "LineString needs at least 2 positions",
                    path=path,
                )
        case "MultiLineString" | "Polygon":
            if geometry_type == "Polygon":
                _check_rings(coordinates, path)
            elif not isinstance(coordinates, (list, tuple)) or not coordinates:
                raise GeometryError(
                    GeoErrorCode.INVALID_GEOMETRY, "MultiLineString needs at least one line",
                    path=path,
                )
            else:
                for index, line in enumerate(coordinates):
                    _check_positions(line, f"{path}[{index}]")
                    if len(line) < 2:
                        raise GeometryError(
                            GeoErrorCode.INVALID_GEOMETRY,
                            "each line needs at least 2 positions",
                            path=f"{path}[{index}]",
                        )
        case "MultiPolygon":
            if not isinstance(coordinates, (list, tuple)) or not coordinates:
                raise GeometryError(
                    GeoErrorCode.INVALID_GEOMETRY, "MultiPolygon needs at least one polygon",
                    path=path,
                )
            for index, polygon in enumerate(coordinates):
                _check_rings(polygon, f"{path}[{index}]")


def _check_positions(raw: Any, path: str) -> None:
    if not isinstance(raw, (list, tuple)) or not raw:
        raise GeometryError(
            GeoErrorCode.INVALID_GEOMETRY, "expected a non-empty array of positions", path=path
        )
    for index, position in enumerate(raw):
        _check_position(position, f"{path}[{index}]")


def validate_geometry(value: Mapping[str, Any], *, path: str = "geometry") -> BaseGeometry:
    """Validate a GeoJSON geometry and return it as a GEOS geometry.

    Raises :class:`GeometryError` with a stable code. Never repairs input: a
    silently closed ring or pulled-in vertex hides a producer bug.
    """
    if not isinstance(value, Mapping):
        raise GeometryError(GeoErrorCode.MALFORMED_GEOJSON, "geometry must be an object", path=path)

    geometry_type = value.get("type")
    if not isinstance(geometry_type, str):
        raise GeometryError(
            GeoErrorCode.MALFORMED_GEOJSON, 'geometry needs a string "type" member', path=path
        )
    if geometry_type not in _SUPPORTED:
        raise GeometryError(
            GeoErrorCode.UNSUPPORTED_GEOMETRY_TYPE,
            f'unsupported geometry type "{geometry_type}"',
            path=path,
        )

    if geometry_type == "GeometryCollection":
        members = value.get("geometries")
        if not isinstance(members, (list, tuple)) or not members:
            raise GeometryError(
                GeoErrorCode.EMPTY_GEOMETRY, "GeometryCollection needs at least one member",
                path=path,
            )
        for index, member in enumerate(members):
            validate_geometry(member, path=f"{path}.geometries[{index}]")
    else:
        if "coordinates" not in value:
            raise GeometryError(
                GeoErrorCode.MALFORMED_GEOJSON, 'geometry needs a "coordinates" member', path=path
            )
        _check_coordinates(geometry_type, value["coordinates"], f"{path}.coordinates")

    if value.get("crs") is not None:
        raise GeometryError(
            GeoErrorCode.UNSUPPORTED_CRS,
            'per-object "crs" is not accepted: GeoJSON interchange is EPSG:4326 only',
            path=path,
        )

    try:
        geometry = shape(value)
    except (GEOSException, TypeError, ValueError) as exc:
        raise GeometryError(
            GeoErrorCode.MALFORMED_GEOJSON, f"could not parse geometry: {exc}", path=path
        ) from exc

    if geometry.is_empty:
        raise GeometryError(GeoErrorCode.EMPTY_GEOMETRY, "geometry is empty", path=path)
    if not geometry.is_valid:
        raise GeometryError(
            GeoErrorCode.INVALID_GEOMETRY, explain_validity(geometry), path=path
        )
    return geometry


def validate_feature(
    value: Mapping[str, Any], *, path: str = "feature"
) -> tuple[BaseGeometry, dict]:
    """Validate a GeoJSON Feature and return its geometry and properties."""
    if value.get("type") != "Feature":
        raise GeometryError(GeoErrorCode.MALFORMED_GEOJSON, 'feature must have type "Feature"',
                            path=path)
    geometry_value = value.get("geometry")
    if not isinstance(geometry_value, Mapping):
        raise GeometryError(
            GeoErrorCode.MALFORMED_GEOJSON,
            "feature needs a geometry object",
            path=f"{path}.geometry",
        )
    geometry = validate_geometry(geometry_value, path=f"{path}.geometry")
    properties = value.get("properties") or {}
    if not isinstance(properties, Mapping):
        raise GeometryError(
            GeoErrorCode.MALFORMED_GEOJSON,
            "properties must be an object",
            path=f"{path}.properties",
        )
    return geometry, dict(properties)


def as_lonlat(geometry: BaseGeometry) -> LonLat:
    """Return the single position of a point-like geometry."""
    if geometry.geom_type != "Point":
        raise GeometryError(
            GeoErrorCode.INVALID_GEOMETRY,
            f"expected Point, got {geometry.geom_type}",
        )
    return LonLat(geometry.x, geometry.y)

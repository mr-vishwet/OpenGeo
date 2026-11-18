import pytest

from opengeo.geo import GeoErrorCode, GeometryError, validate_feature, validate_geometry


def point(lon: float = 73.8567, lat: float = 18.5204) -> dict:
    return {"type": "Point", "coordinates": [lon, lat]}


def square(lon: float = 73.85, lat: float = 18.52, size: float = 0.01) -> list:
    return [
        [lon, lat],
        [lon + size, lat],
        [lon + size, lat + size],
        [lon, lat + size],
        [lon, lat],
    ]


def code_of(exc: pytest.ExceptionInfo[GeometryError]) -> GeoErrorCode:
    return exc.value.code


def test_accepts_a_valid_point():
    geometry = validate_geometry(point())
    assert geometry.geom_type == "Point"
    assert geometry.x == 73.8567


def test_accepts_a_polygon_with_a_hole():
    geometry = validate_geometry(
        {
            "type": "Polygon",
            "coordinates": [square(), square(73.855, 18.525, size=0.002)],
        }
    )
    assert geometry.geom_type == "Polygon"
    assert len(geometry.interiors) == 1


def test_rejects_longitude_out_of_range():
    with pytest.raises(GeometryError) as exc:
        validate_geometry(point(lon=181))
    assert code_of(exc) is GeoErrorCode.INVALID_COORDINATE


def test_rejects_latitude_out_of_range():
    with pytest.raises(GeometryError) as exc:
        validate_geometry(point(lat=91))
    assert code_of(exc) is GeoErrorCode.INVALID_COORDINATE


def test_rejects_a_swapped_pair_that_exceeds_the_latitude_limit():
    with pytest.raises(GeometryError) as exc:
        validate_geometry(point(lon=18.5204, lat=99.0))
    assert code_of(exc) is GeoErrorCode.INVALID_COORDINATE
    assert "swapped" in exc.value.message


def test_rejects_an_open_ring():
    open_ring = square()[:-1]
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Polygon", "coordinates": [open_ring]})
    assert code_of(exc) is GeoErrorCode.INVALID_RING


def test_rejects_a_ring_with_too_few_positions():
    with pytest.raises(GeometryError) as exc:
        validate_geometry(
            {"type": "Polygon", "coordinates": [[[0, 0], [1, 0], [0, 0]]]}
        )
    assert code_of(exc) is GeoErrorCode.INVALID_RING


def test_rejects_a_self_intersecting_ring():
    bowtie = [[0, 0], [2, 2], [2, 0], [0, 1], [0, 0]]
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Polygon", "coordinates": [bowtie]})
    assert code_of(exc) is GeoErrorCode.SELF_INTERSECTING_RING


def test_rejects_a_collinear_ring_as_degenerate():
    line_ring = [[0, 0], [1, 1], [2, 2], [0, 0]]
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Polygon", "coordinates": [line_ring]})
    assert code_of(exc) is GeoErrorCode.DEGENERATE_RING


def test_rejects_a_hole_outside_its_shell():
    outside_hole = square(74.0, 18.6, size=0.001)
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Polygon", "coordinates": [square(), outside_hole]})
    assert code_of(exc) is GeoErrorCode.HOLE_OUTSIDE_SHELL


def test_rejects_an_unsupported_type():
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Circle", "coordinates": []})
    assert code_of(exc) is GeoErrorCode.UNSUPPORTED_GEOMETRY_TYPE


def test_rejects_a_per_object_crs():
    with pytest.raises(GeometryError) as exc:
        validate_geometry({**point(), "crs": {"type": "name", "properties": {"name": "EPSG:3857"}}})
    assert code_of(exc) is GeoErrorCode.UNSUPPORTED_CRS


def test_rejects_a_position_with_the_wrong_arity():
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Point", "coordinates": [73.8, 18.5, 560, 1]})
    assert code_of(exc) is GeoErrorCode.MALFORMED_GEOJSON


def test_rejects_a_boolean_masquerading_as_a_number():
    # bool is a subclass of int in Python; a JSON true is not a coordinate.
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Point", "coordinates": [True, 18.5]})
    assert code_of(exc) is GeoErrorCode.MALFORMED_GEOJSON


def test_rejects_a_non_finite_coordinate():
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Point", "coordinates": [float("nan"), 18.5]})
    assert code_of(exc) is GeoErrorCode.INVALID_COORDINATE


def test_rejects_a_geometry_without_coordinates():
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Point"})
    assert code_of(exc) is GeoErrorCode.MALFORMED_GEOJSON


def test_rejects_an_empty_geometry_collection():
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "GeometryCollection", "geometries": []})
    assert code_of(exc) is GeoErrorCode.EMPTY_GEOMETRY


def test_accepts_a_nested_geometry_collection():
    geometry = validate_geometry(
        {
            "type": "GeometryCollection",
            "geometries": [point(), {"type": "LineString", "coordinates": [[0, 0], [1, 1]]}],
        }
    )
    assert geometry.geom_type == "GeometryCollection"
    assert len(geometry.geoms) == 2


def test_error_carries_a_path_for_diagnostics():
    with pytest.raises(GeometryError) as exc:
        validate_geometry({"type": "Polygon", "coordinates": [square()[:-1]]})
    assert exc.value.path == "geometry.coordinates[0]"


def test_validate_feature_returns_properties():
    geometry, properties = validate_feature(
        {
            "type": "Feature",
            "geometry": point(),
            "properties": {"name": "Shaniwar Wada", "name:mr": "शनिवार वाडा"},
        }
    )
    assert geometry.geom_type == "Point"
    assert properties["name:mr"] == "शनिवार वाडा"


def test_validate_feature_rejects_a_missing_geometry():
    with pytest.raises(GeometryError):
        validate_feature({"type": "Feature", "properties": {}})

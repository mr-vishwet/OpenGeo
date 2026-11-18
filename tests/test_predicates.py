import pytest
from shapely.geometry import LineString, Point, Polygon

from opengeo.geo import LonLat, validate_geometry
from opengeo.geo.predicates import (
    contains,
    covers,
    geodesic_distance,
    intersects,
    nearest,
    predicate,
    within_radius,
)

SQUARE = [[73.85, 18.52], [73.86, 18.52], [73.86, 18.53], [73.85, 18.53], [73.85, 18.52]]


def square() -> Polygon:
    return validate_geometry({"type": "Polygon", "coordinates": [SQUARE]})


def test_contains_excludes_the_boundary():
    assert contains(square(), Point(73.855, 18.525)) is True
    assert contains(square(), Point(73.85, 18.52)) is False


def test_covers_includes_the_boundary():
    assert covers(square(), Point(73.855, 18.525)) is True
    assert covers(square(), Point(73.85, 18.52)) is True


def test_boundary_point_falls_outside_contains_but_inside_covers():
    boundary = Point(73.86, 18.525)  # on the eastern edge
    assert contains(square(), boundary) is False
    assert covers(square(), boundary) is True


def test_intersects_accepts_a_crossing_line():
    line = LineString([(73.84, 18.525), (73.87, 18.525)])
    assert intersects(square(), line) is True


def test_intersects_rejects_a_distant_line():
    line = LineString([(0, 0), (1, 1)])
    assert intersects(square(), line) is False


def test_a_hole_is_not_covered():
    geometry = validate_geometry(
        {
            "type": "Polygon",
            "coordinates": [
                SQUARE,
                [
                    [73.853, 18.523],
                    [73.857, 18.523],
                    [73.857, 18.527],
                    [73.853, 18.527],
                    [73.853, 18.523],
                ],
            ],
        }
    )
    assert covers(geometry, Point(73.855, 18.525)) is False
    assert covers(geometry, Point(73.851, 18.521)) is True


def test_geodesic_distance_is_metres_not_degrees():
    metres = geodesic_distance(LonLat(73.8567, 18.5204), LonLat(73.8567, 18.5214))
    assert 100 < metres < 115  # one thousandth of a degree of latitude


def test_predicate_dispatch_rejects_an_unknown_name():
    with pytest.raises(ValueError):
        predicate("overlaps", square(), Point(73.855, 18.525))


def test_within_radius_orders_by_distance_and_excludes_far_points():
    center = LonLat(73.8567, 18.5204)
    near = ("near", Point(73.8570, 18.5206))
    middle = ("middle", Point(73.8580, 18.5215))
    far = ("far", Point(73.9000, 18.6000))
    hits = within_radius(center, 500, [far, middle, near])
    assert [feature_id for feature_id, _ in hits] == ["near", "middle"]


def test_within_radius_boundary_policy_is_explicit():
    center = LonLat(73.8567, 18.5204)
    target = ("target", Point(73.8567, 18.5214))
    exact_metres = geodesic_distance(center, LonLat(73.8567, 18.5214))
    included = within_radius(center, exact_metres, [target], boundary="covers")
    excluded = within_radius(center, exact_metres, [target], boundary="contains")
    assert len(included) == 1
    assert excluded == []


def test_within_radius_rejects_a_non_positive_radius():
    with pytest.raises(ValueError):
        within_radius(LonLat(0, 0), 0, [])


def test_within_radius_rejects_polygon_candidates_in_the_reference_path():
    center = LonLat(73.8567, 18.5204)
    with pytest.raises(ValueError):
        within_radius(center, 1000, [("poly", square())])


def test_nearest_returns_the_closest_point():
    center = LonLat(73.8567, 18.5204)
    result = nearest(center, [("a", Point(73.9, 18.6)), ("b", Point(73.8568, 18.5205))])
    assert result is not None
    assert result[0] == "b"
    assert result[1] < 20


def test_nearest_of_nothing_is_none():
    assert nearest(LonLat(0, 0), []) is None

from math import isfinite

import pytest

from opengeo.geo import LonLat, haversine, vincenty_inverse
from opengeo.geo.predicates import distance, geodesic_distance
from opengeo.geo.units import DistanceMethod, DistanceUnit, convert, to_metres

PUNE = (73.8567, 18.5204)
MUMBAI = (72.8777, 19.0760)


def test_one_degree_of_latitude_at_the_equator():
    # WGS84 meridian arc for 0..1 degree, published value 110574.389 m.
    assert vincenty_inverse(0, 0, 0, 1) == pytest.approx(110574.389, abs=1.0)


def test_one_degree_of_longitude_at_the_equator():
    # 2 * pi * a / 360 on the WGS84 semi-major axis.
    assert vincenty_inverse(0, 0, 1, 0) == pytest.approx(111319.491, abs=1.0)


def test_distance_is_symmetric():
    forward = vincenty_inverse(*PUNE, *MUMBAI)
    backward = vincenty_inverse(*MUMBAI, *PUNE)
    assert forward == pytest.approx(backward, rel=1e-9)


def test_pune_to_mumbai_is_about_120_km():
    metres = vincenty_inverse(*PUNE, *MUMBAI)
    assert 115_000 < metres < 125_000


def test_identical_points_are_zero():
    assert vincenty_inverse(*PUNE, *PUNE) == 0
    assert haversine(*PUNE, *PUNE) == 0


def test_haversine_agrees_with_ellipsoidal_within_half_a_percent():
    spherical = haversine(*PUNE, *MUMBAI)
    ellipsoidal = vincenty_inverse(*PUNE, *MUMBAI)
    assert abs(spherical - ellipsoidal) / ellipsoidal < 0.005


def test_near_antipodal_falls_back_instead_of_returning_a_wrong_number():
    metres = geodesic_distance(LonLat(0, 0), LonLat(179.5, 0.5))
    assert isfinite(metres)
    assert metres > 19_000_000


def test_degrees_are_not_metres():
    metres = vincenty_inverse(*PUNE, *MUMBAI)
    naive_degree_difference = abs(PUNE[0] - MUMBAI[0])
    assert metres > 100_000
    assert naive_degree_difference < 1.5


def test_units_convert_through_metres():
    assert to_metres(1.5, DistanceUnit.KILOMETRE) == 1500
    assert convert(1, DistanceUnit.MILE, DistanceUnit.METRE) == pytest.approx(1609.344)
    assert convert(1000, DistanceUnit.METRE, DistanceUnit.KILOMETRE) == pytest.approx(1)


def test_projected_planar_cannot_be_computed_from_degrees():
    with pytest.raises(ValueError):
        distance(LonLat(*PUNE), LonLat(*MUMBAI), method=DistanceMethod.PROJECTED_PLANAR)


def test_network_travel_requires_a_routing_engine():
    with pytest.raises(ValueError):
        distance(LonLat(*PUNE), LonLat(*MUMBAI), method=DistanceMethod.NETWORK_TRAVEL)

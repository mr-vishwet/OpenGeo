"""Geodesic distance on the WGS84 ellipsoid.

Haversine is offered because it is cheap and adequate for candidate filtering;
Vincenty is offered because a reported distance must match what a user's map
application would say. Both return metres. Nothing here converts degrees to
metres by scalar multiplication.
"""

from __future__ import annotations

from math import atan, atan2, cos, radians, sin, sqrt, tan

WGS84_A = 6378137.0
WGS84_F = 1 / 298.257223563
WGS84_B = (1 - WGS84_F) * WGS84_A


def haversine(lon1: float, lat1: float, lon2: float, lat2: float) -> float:
    """Spherical great-circle distance in metres (mean Earth radius)."""
    mean_radius = 6371008.8
    phi1, phi2 = radians(lat1), radians(lat2)
    d_phi = phi2 - phi1
    d_lambda = radians(lon2 - lon1)
    a = sin(d_phi / 2) ** 2 + cos(phi1) * cos(phi2) * sin(d_lambda / 2) ** 2
    return 2 * mean_radius * atan2(sqrt(a), sqrt(1 - a))


def vincenty_inverse(
    lon1: float, lat1: float, lon2: float, lat2: float, *, max_iterations: int = 200
) -> float:
    """Ellipsoidal distance in metres.

    Raises ValueError when the iteration does not converge. Convergence fails
    only for near-antipodal pairs, where a geodesic is genuinely ambiguous at
    this precision; callers must then fall back to haversine rather than
    silently return a wrong number.
    """
    if (lon1, lat1) == (lon2, lat2):
        return 0.0

    u1 = atan((1 - WGS84_F) * tan(radians(lat1)))
    u2 = atan((1 - WGS84_F) * tan(radians(lat2)))
    sin_u1, cos_u1 = sin(u1), cos(u1)
    sin_u2, cos_u2 = sin(u2), cos(u2)
    big_l = radians(lon2 - lon1)

    lam = big_l
    for _ in range(max_iterations):
        sin_lam, cos_lam = sin(lam), cos(lam)
        sin_sigma = sqrt(
            (cos_u2 * sin_lam) ** 2 + (cos_u1 * sin_u2 - sin_u1 * cos_u2 * cos_lam) ** 2
        )
        if sin_sigma == 0:
            return 0.0
        cos_sigma = sin_u1 * sin_u2 + cos_u1 * cos_u2 * cos_lam
        sigma = atan2(sin_sigma, cos_sigma)
        sin_alpha = cos_u1 * cos_u2 * sin_lam / sin_sigma
        cos_sq_alpha = 1 - sin_alpha**2
        cos_2sigma_m = (
            cos_sigma - 2 * sin_u1 * sin_u2 / cos_sq_alpha if cos_sq_alpha != 0 else 0.0
        )
        c = WGS84_F / 16 * cos_sq_alpha * (4 + WGS84_F * (4 - 3 * cos_sq_alpha))
        previous = lam
        lam = big_l + (1 - c) * WGS84_F * sin_alpha * (
            sigma + c * sin_sigma * (cos_2sigma_m + c * cos_sigma * (-1 + 2 * cos_2sigma_m**2))
        )
        if abs(lam - previous) < 1e-12:
            break
    else:
        raise ValueError("Vincenty inverse failed to converge for near-antipodal points")

    u_sq = cos_sq_alpha * (WGS84_A**2 - WGS84_B**2) / WGS84_B**2
    big_a = 1 + u_sq / 16384 * (4096 + u_sq * (-768 + u_sq * (320 - 175 * u_sq)))
    big_b = u_sq / 1024 * (256 + u_sq * (-128 + u_sq * (74 - 47 * u_sq)))
    delta_sigma = (
        big_b
        * sin_sigma
        * (
            cos_2sigma_m
            + big_b
            / 4
            * (
                cos_sigma * (-1 + 2 * cos_2sigma_m**2)
                - big_b
                / 6
                * cos_2sigma_m
                * (-3 + 4 * sin_sigma**2)
                * (-3 + 4 * cos_2sigma_m**2)
            )
        )
    )
    return WGS84_B * big_a * (sigma - delta_sigma)

"""Search / geocoding provider interface and implementations.

Implementations wrap an external geocoding service (Pelias, Photon, Nominatim,
open-geocode-rs, …) and translate between OpenGeo's request/response shapes and
the provider's API. Until an engine is attached, `UnimplementedSearchProvider`
refuses every request with `unsupported_capability`.

See ADR-0005 for the provider selection decision.
"""

from __future__ import annotations

import json
from abc import ABC, abstractmethod
from dataclasses import dataclass

from ..api.errors import ApiError, ErrorCode


@dataclass(frozen=True)
class GeocodeRequest:
    query: str
    limit: int = 10
    bounds: tuple[float, float, float, float] | None = None  # west, south, east, north


@dataclass(frozen=True)
class GeocodeResult:
    label: str
    longitude: float
    latitude: float
    source: str
    confidence: float | None = None


class SearchProvider(ABC):
    """Geocoding / search provider interface."""

    @abstractmethod
    def geocode(self, request: GeocodeRequest) -> list[GeocodeResult]:
        """Forward-geocode a free-text query to a list of results."""


class UnimplementedSearchProvider(SearchProvider):
    """Search provider that refuses every request until an engine is attached."""

    def geocode(self, request: GeocodeRequest) -> list[GeocodeResult]:
        raise ApiError(
            ErrorCode.UNSUPPORTED_CAPABILITY,
            "search is unavailable",
            hint="no search or geocoding engine is configured. See ADR-0005.",
        )


class PostgresSearchProvider(SearchProvider):
    """Postgres-backed search provider.

    Searches the `names` (multilingual name array) and `address` (jsonb
    address object) columns of `opengeo.place` using ILIKE text matching,
    filtered by an optional bounding box and ordered by relevance (exact match
    first, then prefix, then contains).

    Requires an active dataset version for the configured region.
    """

    def __init__(self, dsn: str, region: str = "pune") -> None:
        if not dsn:
            raise ValueError("OPENGEO_DATABASE_URL is required for the Postgres search provider")
        self.dsn = dsn
        self.region = region

    def geocode(self, request: GeocodeRequest) -> list[GeocodeResult]:
        import psycopg

        with psycopg.connect(self.dsn) as conn, conn.cursor() as cur:
            # Find the active dataset version for this region.
            cur.execute(
                "SELECT dataset_version FROM opengeo.dataset_version "
                "WHERE region = %s AND is_active",
                (self.region,),
            )
            row = cur.fetchone()
            if row is None:
                raise ApiError(
                    ErrorCode.UNSUPPORTED_CAPABILITY,
                    f"no active dataset version for region '{self.region}'",
                )
            dataset_version = row[0]

            # Build the query: search names and address fields with ILIKE,
            # order by relevance (exact > prefix > contains), filter by
            # bounds if provided, limit results.
            exact_json = f'[{{"value": "{request.query}", "language": ""}}]'
            query_parts: list[str] = [
                "SELECT",
                "  p.place_id,",
                "  p.names,",
                "  p.address,",
                "  ST_X(p.geom) AS longitude,",
                "  ST_Y(p.geom) AS latitude,",
                "  CASE",
                "    WHEN p.names @> %s THEN 1",  # exact name match (highest)
                "    WHEN p.names->>0 ILIKE %s THEN 2",  # first name starts with query
                "    WHEN p.names::text ILIKE %s THEN 3",  # name contains query
                "    WHEN p.address::text ILIKE %s THEN 4",  # address contains query
                "    ELSE 5",
                "  END AS rank",
                "FROM opengeo.place p",
                "WHERE p.dataset_version = %s",
            ]
            # Add params: exact match JSON array, prefix, contains, contains, dataset_version
            params: list[object] = [
                exact_json,
                f"{request.query}%",
                f"%{request.query}%",
                f"%{request.query}%",
                dataset_version,
            ]

            if request.bounds is not None:
                west, south, east, north = request.bounds
                query_parts.append(
                    "AND ST_Contains(ST_MakeEnvelope(%s, %s, %s, %s, 4326), p.geom)"
                )
                params.extend([west, south, east, north])

            query_parts.extend([
                "AND (",
                "  p.names::text ILIKE %s",
                "  OR p.address::text ILIKE %s",
                ")",
                "ORDER BY rank, p.place_id",
                "LIMIT %s",
            ])
            params.extend([
                f"%{request.query}%",
                f"%{request.query}%",
                request.limit,
            ])

            cur.execute(" ".join(query_parts), tuple(params))
            rows = cur.fetchall()

        results: list[GeocodeResult] = []
        for _place_id, names, _address, longitude, latitude, _rank in rows:
            # Prefer the default (empty language) name, fall back to first name.
            label = request.query
            if names:
                try:
                    names_list = (
                        json.loads(names) if isinstance(names, str) else names
                    )
                    for entry in names_list:
                        if isinstance(entry, dict) and entry.get("language", "") == "":
                            label = entry["value"]
                            break
                    else:
                        if names_list and isinstance(names_list[0], dict):
                            label = names_list[0].get("value", label)
                except (json.JSONDecodeError, TypeError, IndexError):
                    pass
            results.append(
                GeocodeResult(
                    label=label,
                    longitude=float(longitude),
                    latitude=float(latitude),
                    source="opengeo.postgres",
                    confidence=None,
                )
            )
        return results

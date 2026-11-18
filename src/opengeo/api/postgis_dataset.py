"""PostGIS-backed feature store.

Loads the active region's places once per process. Every row is validated at
load time with the same trust boundary the fixture uses, so a broken import
cannot reach a query.
"""

from __future__ import annotations

import json
import os
from collections.abc import Iterable, Sequence
from typing import cast

import psycopg
from shapely.geometry.base import BaseGeometry

from ..geo import LonLat, validate_geometry
from .dataset import Feature
from .models import SourceAttribution

DATABASE_URL = os.environ.get("OPENGEO_DATABASE_URL", "")


class PostgisFeatureStore:
    def __init__(self, dsn: str, *, region: str = "pune") -> None:
        if not dsn:
            raise ValueError("OPENGEO_DATABASE_URL is required for the PostGIS store")

        self.dsn = dsn
        self.region = region
        with psycopg.connect(dsn) as conn, conn.cursor() as cur:
            cur.execute(
                "SELECT dataset_version FROM opengeo.dataset_version "
                "WHERE region = %s AND is_active",
                (region,),
            )
            row = cur.fetchone()
            if row is None:
                raise ValueError(f"no active dataset version for region '{region}'")
            self.dataset_version = cast(str, row[0])

            cur.execute(
                "SELECT s.name, s.license, s.attribution, s.url "
                "FROM opengeo.source s "
                "JOIN opengeo.import_run r ON r.source_id = s.source_id "
                "JOIN opengeo.dataset_version d ON d.run_id = r.run_id "
                "WHERE d.dataset_version = %s",
                (self.dataset_version,),
            )
            rows = cur.fetchall()
            if not rows:
                raise ValueError(f"no source found for version {self.dataset_version}")
            self.sources = [
                SourceAttribution(name=r[0], license=r[1], attribution=r[2], url=r[3])
                for r in rows
            ]

            cur.execute(
                "SELECT place_id, category, names, address, properties, ST_AsGeoJSON(geom) "
                "FROM opengeo.place WHERE dataset_version = %s",
                (self.dataset_version,),
            )
            self._features: dict[str, Feature] = {}
            for place_id, category, names, address, properties, geojson in cur.fetchall():
                # validate_geometry returns a GEOS geometry or raises GeometryError
                # with the stable code; message carries the row id.
                try:
                    geometry = validate_geometry(json.loads(geojson), path=f"place {place_id}")
                except Exception as exc:
                    raise ValueError(f"{place_id}: invalid geometry in database: {exc}") from exc
                self._features[place_id] = Feature(
                    place_id,
                    geometry,
                    {
                        **(properties or {}),
                        "names": names,
                        "address": address,
                        "category": category,
                    },
                )

    def get(self, feature_id: str) -> Feature | None:
        return self._features.get(feature_id)

    def features(self) -> Sequence[Feature]:
        return tuple(self._features.values())

    def points(self) -> Iterable[tuple[str, BaseGeometry]]:
        for feature in self.features():
            if feature.geometry.geom_type == "Point":
                yield feature.id, feature.geometry

    def nearby(
        self,
        center_lonlat: LonLat,
        radius_m: float,
        categories: Iterable[str],
    ) -> Iterable[tuple[str, float]]:
        wanted = [category.lower() for category in categories]
        lon, lat = center_lonlat.longitude, center_lonlat.latitude
        with psycopg.connect(self.dsn) as conn, conn.cursor() as cur:
            cur.execute(
                """
                    SELECT p.place_id,
                           ST_Distance(
                               p.geom::geography,
                               ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography
                           ) AS distance_m
                    FROM opengeo.place p
                    WHERE p.dataset_version = %s
                      AND GeometryType(p.geom) = 'POINT'
                      AND (cardinality(%s::text[]) = 0 OR p.category = ANY(%s::text[]))
                      AND ST_DWithin(
                              p.geom::geography,
                              ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography,
                              %s
                          )
                    ORDER BY distance_m ASC
                    """,
                (lon, lat, self.dataset_version, wanted, wanted, lon, lat, radius_m),
            )
            return list(cur.fetchall())


def load_postgis_store(dsn: str | None = None) -> PostgisFeatureStore:
    return PostgisFeatureStore(dsn or DATABASE_URL)

"""The reference feature store.

A GeoJSON FeatureCollection stands in for the database until PostGIS is
attached. The store exposes the same shape a PostGIS-backed store will, so the
API does not change when the authority does: the seam is `FeatureStore`, not a
conditional inside a route.

Every feature is validated on load. A fixture that breaks a geographic
invariant fails at startup, not on the first query.
"""

from __future__ import annotations

import hashlib
import json
import os
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

from shapely.geometry.base import BaseGeometry

from ..geo import GeometryError, LonLat, validate_feature
from .models import SourceAttribution

FIXTURE_PATH = Path(
    os.environ.get(
        "OPENGEO_FIXTURE",
        Path(__file__).resolve().parents[3] / "data" / "fixtures" / "pune_places.geojson",
    )
)

SYNTHETIC_SOURCE = SourceAttribution(
    name="OpenGeo synthetic fixtures",
    license="Apache-2.0",
    attribution="Synthetic test data authored for OpenGeo. Not OpenStreetMap data.",
)


@dataclass(frozen=True)
class Feature:
    id: str
    geometry: BaseGeometry
    properties: Mapping[str, object]

    @property
    def category(self) -> str | None:
        value = self.properties.get("category")
        return value if isinstance(value, str) else None

    @property
    def name(self) -> str | None:
        value = self.properties.get("name")
        return value if isinstance(value, str) else None


class FeatureStore(Protocol):
    dataset_version: str
    sources: Sequence[SourceAttribution]

    def get(self, feature_id: str) -> Feature | None: ...

    def features(self) -> Sequence[Feature]: ...

    def nearby(
        self,
        center_lonlat: LonLat,
        radius_m: float,
        categories: Iterable[str],
    ) -> Iterable[tuple[str, float]]:
        """Point features within ``radius_m`` of ``center_lonlat``, nearest first.

        The PostGIS store refines with a GiST/geography index; the fixture scans
        in process. The signature is the seam both stores are held to.
        """
        ...


class GeoJsonFeatureStore:
    """In-memory store over a validated GeoJSON FeatureCollection."""

    def __init__(self, path: Path = FIXTURE_PATH) -> None:
        self.path = path
        raw = path.read_bytes()
        self.dataset_version = f"fixture-{hashlib.sha256(raw).hexdigest()[:12]}"
        self.sources = [SYNTHETIC_SOURCE]

        document = json.loads(raw)
        if document.get("type") != "FeatureCollection":
            raise ValueError(f"{path} is not a GeoJSON FeatureCollection")

        by_id: dict[str, Feature] = {}
        for index, entry in enumerate(document.get("features", [])):
            try:
                geometry, properties = validate_feature(entry, path=f"features[{index}]")
            except GeometryError as exc:
                raise ValueError(f"{path}: {exc}") from exc
            feature_id = properties.get("id")
            if not isinstance(feature_id, str) or not feature_id:
                raise ValueError(f"{path}: features[{index}] has no stable id")
            if feature_id in by_id:
                raise ValueError(f"{path}: duplicate feature id {feature_id}")
            by_id[feature_id] = Feature(feature_id, geometry, properties)

        self._features = by_id

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
        from ..geo.predicates import within_radius

        wanted = {category.lower() for category in categories}
        candidates = [
            (feature.id, feature.geometry)
            for feature in self.features()
            if feature.geometry.geom_type == "Point"
            and (not wanted or (feature.category or "").lower() in wanted)
        ]
        return within_radius(center_lonlat, radius_m, candidates)


def load_default_store() -> FeatureStore:
    """Choose the store from `OPENGEO_STORE`: `fixture` (default) or `postgis`.

    Tests and local runs without a database keep the fixture. The PostGIS store
    is selected only when the environment asks for it, never silently.
    """
    kind = os.environ.get("OPENGEO_STORE", "fixture").strip().lower()
    if kind == "postgis":
        from .postgis_dataset import PostgisFeatureStore

        dsn = os.environ.get("OPENGEO_DATABASE_URL")
        if not dsn:
            raise ValueError("OPENGEO_STORE=postgis requires OPENGEO_DATABASE_URL")
        return PostgisFeatureStore(dsn)
    return GeoJsonFeatureStore()

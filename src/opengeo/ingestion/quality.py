"""Data-quality gate: count what an extract contains before anything is published.

The registry decides *whether* a run may publish; this module decides *what* the
run found. Kept separate so the same gate runs on an OSM extract today and on a
database staging table later.
"""

from __future__ import annotations

import json
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from ..geo import GeometryError, validate_feature
from .manifest import Counts, ImportError_, QualityReport, Rejection


@dataclass(frozen=True)
class Assessment:
    counts: Counts
    quality: QualityReport
    rejections: list[Rejection]

    def as_report(self) -> dict[str, Any]:
        return {
            "counts": self.counts.model_dump(),
            "rejected_ratio": round(self.counts.rejected_ratio, 4),
            "quality": self.quality.model_dump(),
            "rejections": [r.model_dump() for r in self.rejections],
        }


def assess(
    path: Path, *, required_properties: tuple[str, ...] = ("id",)
) -> Assessment:
    """Validate every feature and classify what is wrong with the rest.

    Each feature is judged by the same trust boundary the API uses, so a record
    that survives ingestion is one the service can serve. Rejections are counted
    by reason, never repaired.
    """
    path = Path(path)
    if not path.is_file():
        raise ImportError_(f"source file not found: {path}")
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ImportError_(f"{path.name} is not valid JSON: {exc}") from exc

    if document.get("type") != "FeatureCollection":
        raise ImportError_(f"{path.name} is not a GeoJSON FeatureCollection")

    counts = Counts()
    quality = QualityReport()
    reasons: Counter[str] = Counter()
    seen: set[str] = set()

    for index, entry in enumerate(document.get("features") or []):
        counts.parsed += 1
        try:
            _, properties = validate_feature(entry, path=f"features[{index}]")
        except GeometryError as exc:
            counts.rejected += 1
            quality.geometry_invalid += 1
            reasons[f"geometry:{exc.code.value}"] += 1
            continue

        missing = [name for name in required_properties if not properties.get(name)]
        if missing:
            counts.rejected += 1
            quality.missing_required_metadata += 1
            reasons[f"missing_required:{','.join(missing)}"] += 1
            continue

        feature_id = properties["id"]
        if feature_id in seen:
            counts.rejected += 1
            quality.suspected_duplicates += 1
            reasons["duplicate_id"] += 1
            continue

        seen.add(feature_id)
        counts.accepted += 1

    return Assessment(
        counts=counts,
        quality=quality,
        rejections=[
            Rejection(reason=reason, count=count) for reason, count in sorted(reasons.items())
        ],
    )

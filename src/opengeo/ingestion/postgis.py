"""Import a GeoJSON FeatureCollection into the PostGIS authority.

One import is one transaction: the run is staged, the features are written, the
version is activated, and either all of it commits or none of it did. The DB
uniques enforce one active version per region on their own.
"""

from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping
from pathlib import Path
from typing import Any

import shapely
from shapely.geometry import shape

from .manifest import REJECTION_BLOCK_RATIO, Counts, ImportRun, Rejection, RunStatus, SourceRef
from .quality import assess


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(1 << 20):
            digest.update(chunk)
    return digest.hexdigest()


def _names_json(properties: Mapping[str, Any]) -> list[dict[str, str]]:
    names: list[dict[str, str]] = []
    for key, value in properties.items():
        if not key.startswith("name"):
            continue
        language = "" if key == "name" else key.split(":", 1)[1]
        if isinstance(value, str) and value:
            names.append({"language": language, "value": value})
    return names


def _address_json(properties: Mapping[str, Any]) -> dict[str, Any]:
    return {
        key: properties[key]
        for key in (
            "house_number",
            "street",
            "locality",
            "region",
            "postal_code",
            "country_code",
        )
        if key in properties
    }


def import_collection(
    conn,
    path: Path,
    *,
    region: str,
    source: SourceRef,
    parser_version: str,
    transform_version: str,
    run_id: str,
) -> ImportRun:
    """Stage, write and publish an extract. Raises instead of writing partial data."""

    assessment = assess(Path(path))
    if assessment.counts.rejected_ratio > REJECTION_BLOCK_RATIO:
        raise ValueError(
            f"{path} has {assessment.counts.rejected_ratio:.1%} rejected features "
            f"(limit {REJECTION_BLOCK_RATIO:.0%}); repair the data, not the loader"
        )

    with open(path, encoding="utf-8") as handle:
        document = json.load(handle)

    sha256 = _sha256(Path(path))
    dataset_version = f"{region}-{sha256[:12]}"

    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO opengeo.source
                (source_id, name, license, attribution, allowed_uses, url, checked_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (source_id) DO NOTHING
            """,
            (
                source.name.lower().replace(" ", "-"),
                source.name,
                source.license,
                source.attribution,
                source.allowed_uses,
                source.url,
                source.retrieved_at,
            ),
        )
        cur.execute(
            """
            INSERT INTO opengeo.import_run
                (run_id, region, source_id, source_file, source_sha256,
                 parser_version, transform_version, started_at, status,
                 parsed_count, accepted_count, rejected_count, quality)
            VALUES (%s, %s, %s, %s, %s, %s, %s, now(), 'published', %s, %s, %s, %s)
            """,
            (
                run_id,
                region,
                source.name.lower().replace(" ", "-"),
                path.name,
                sha256,
                parser_version,
                transform_version,
                assessment.counts.parsed,
                assessment.counts.accepted,
                assessment.counts.rejected,
                assessment.quality.model_dump_json(),
            ),
        )
        cur.execute(
            """
            INSERT INTO opengeo.dataset_version
                (dataset_version, region, run_id, feature_count, is_active)
            VALUES (%s, %s, %s, %s, false)
            ON CONFLICT (dataset_version) DO NOTHING
            """,
            (dataset_version, region, run_id, assessment.counts.accepted),
        )

        for feature in document["features"]:
            properties = feature["properties"]
            geometry_wkt = shapely.to_wkt(shape(feature["geometry"]))
            cur.execute(
                """
                INSERT INTO opengeo.place
                    (place_id, dataset_version, category, names, address,
                     properties, source_ids, completeness, geom)
                VALUES (%s, %s, %s, %s::jsonb, %s::jsonb, %s::jsonb, %s::jsonb, %s::jsonb,
                        ST_SetSRID(ST_GeomFromText(%s), 4326))
                ON CONFLICT (place_id) DO NOTHING
                """,
                (
                    properties["id"],
                    dataset_version,
                    properties.get("category"),
                    json.dumps(_names_json(properties), ensure_ascii=False),
                    json.dumps(_address_json(properties), ensure_ascii=False),
                    json.dumps(properties, ensure_ascii=False),
                    json.dumps([source.name], ensure_ascii=False),
                    json.dumps({"name": bool(_names_json(properties))}, ensure_ascii=False),
                    geometry_wkt,
                ),
            )

        cur.execute("SELECT opengeo.publish_dataset_version(%s)", (dataset_version,))

    return ImportRun(
        run_id=run_id,
        region=region,
        source=source,
        source_file=path.name,
        source_sha256=sha256,
        source_timestamp=source.retrieved_at,
        parser_version=parser_version,
        transform_version=transform_version,
        started_at=source.retrieved_at,
        status=RunStatus.PUBLISHED,
        counts=Counts(
            parsed=assessment.counts.parsed,
            accepted=assessment.counts.accepted,
            rejected=assessment.counts.rejected,
        ),
        rejections=[
            Rejection(reason=r.reason, count=r.count) for r in assessment.rejections
        ],
    )

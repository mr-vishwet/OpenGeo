"""Integration tests for the PostGIS ingestion pipeline.

These run against a live Postgres database started with
`docker compose -f infrastructure/compose.dev.yml --env-file .env up -d`.
They are skipped when OPENGEO_DATABASE_URL is not set or the database is
unreachable.
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path

import psycopg
import pytest

from opengeo.ingestion import SourceRef
from opengeo.ingestion.postgis import import_collection

DSN = os.environ.get("OPENGEO_DATABASE_URL")

POINT = {"type": "Point", "coordinates": [73.8567, 18.5204]}


def _feature(feature_id: str, geometry: dict) -> dict:
    return {"type": "Feature", "geometry": geometry, "properties": {"id": feature_id}}


def _collection(*features: dict) -> dict:
    return {"type": "FeatureCollection", "features": list(features)}


def _write_tmp(tmp_path, document: dict, name: str = "extract.geojson") -> Path:
    path = tmp_path / name
    path.write_text(json.dumps(document), encoding="utf-8")
    return path


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(1 << 20):
            digest.update(chunk)
    return digest.hexdigest()


def _cleanup(dsn):
    """Remove test data left by a previous run of this test.

    Matches both colon-separated (opengeo:integ:N) and hyphen-separated
    (opengeo-integ-N:N) place id styles from earlier runs.
    """
    with psycopg.connect(dsn) as conn, conn.cursor() as cur:
        cur.execute(
            "DELETE FROM opengeo.place WHERE place_id LIKE '%integ:%' "
            "OR place_id LIKE 'opengeo-integ-%'"
        )
        cur.execute(
            "DELETE FROM opengeo.dataset_version WHERE run_id LIKE '%integ%'"
        )
        cur.execute(
            "DELETE FROM opengeo.import_run WHERE run_id LIKE '%integ%'"
        )
        conn.commit()


@pytest.fixture
def dsn():
    if DSN is None:
        pytest.skip("OPENGEO_DATABASE_URL not set")
    return DSN


def test_integration_import_publishes_to_postgres(dsn, tmp_path):
    run_id = "opengeo-integ-001"
    _cleanup(dsn)

    document = _collection(
        _feature(f"{run_id}:1", POINT),
        _feature(f"{run_id}:2", POINT),
    )
    path = _write_tmp(tmp_path, document)
    sha256 = _sha256(path)

    with psycopg.connect(dsn) as conn:
        run = import_collection(
            conn,
            path,
            region="pune",
            source=SourceRef(
                name="OpenGeo integration test",
                license="Apache-2.0",
                attribution="test",
                retrieved_at="2026-11-19",
            ),
            parser_version="integ-0.1.0",
            transform_version="none",
            run_id=run_id,
        )

    assert run.status.value == "published"
    assert run.run_id == run_id
    assert run.counts.parsed == 2
    assert run.counts.accepted == 2
    assert run.dataset_version == f"pune-{sha256[:12]}"

    with psycopg.connect(dsn) as conn, conn.cursor() as cur:
        cur.execute(
            "SELECT count(*) FROM opengeo.place WHERE dataset_version = %s",
            (run.dataset_version,),
        )
        assert cur.fetchone()[0] == 2

        cur.execute(
            "SELECT dataset_version, is_active FROM opengeo.dataset_version "
            "WHERE dataset_version = %s",
            (run.dataset_version,),
        )
        row = cur.fetchone()
        assert row is not None
        assert row[1] is True  # active


def test_integration_import_refuses_rejected_features(dsn, tmp_path):
    run_id = "opengeo-integ-002"
    _cleanup(dsn)

    document = _collection(
        _feature(f"{run_id}:1", POINT),
        _feature(
            f"{run_id}:2",
            {"type": "Polygon", "coordinates": [[[0, 0], [2, 2], [2, 0], [0, 1], [0, 0]]]},
        ),
    )
    path = _write_tmp(tmp_path, document)

    with psycopg.connect(dsn) as conn, pytest.raises(ValueError, match="has rejected features"):
        import_collection(
            conn,
            path,
            region="pune",
            source=SourceRef(
                name="OpenGeo integration test",
                license="Apache-2.0",
                attribution="test",
                retrieved_at="2026-11-19",
            ),
            parser_version="integ-0.1.0",
            transform_version="none",
            run_id=run_id,
        )

    # Nothing should have been written
    with psycopg.connect(dsn) as conn, conn.cursor() as cur:
        cur.execute(
            "SELECT count(*) FROM opengeo.place WHERE place_id LIKE %s",
            (f"{run_id}%",),
        )
        assert cur.fetchone()[0] == 0

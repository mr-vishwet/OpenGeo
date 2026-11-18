"""Publication invariant smoke test against a live PostGIS database.

Requires OPENGEO_DATABASE_URL. Skips otherwise so the suite stays runnable
on a laptop without Postgres.

Validates the migration-level invariant the application cannot maintain:
at most one active dataset version per region, enforced by the database,
published only through publish_dataset_version().
"""

from __future__ import annotations

import os
from uuid import uuid4

import pytest

pytest.importorskip("psycopg", reason="psycopg is a dev dependency present in CI")

DSN = os.environ.get("OPENGEO_DATABASE_URL")


def _seed(cur, tag: str) -> str:
    run_id = str(uuid4())
    cur.execute(
        "INSERT INTO opengeo.source (source_id, name, license, attribution, checked_at) "
        "VALUES (%s, %s, 'ODbL-1.0', 'smoke', '2026-11-19') ON CONFLICT (source_id) DO NOTHING",
        (f"smoke-src-{tag}", f"Smoke {tag}"),
    )
    cur.execute(
        "INSERT INTO opengeo.import_run "
        "(run_id, region, source_id, source_file, source_sha256, parser_version, "
        "transform_version, started_at, status, parsed_count, accepted_count) "
        "VALUES (%s, 'pune', %s, 'smoke.pbf', %s, 'p1', 't1', now(), 'published', 1, 1)",
        (run_id, f"smoke-src-{tag}", "c" * 64),
    )
    return run_id


def test_publication_flips_active_version():
    if DSN is None:
        pytest.skip("OPENGEO_DATABASE_URL not set")
    import psycopg

    with psycopg.connect(DSN) as conn, conn.cursor() as cur:
        run_id = _seed(cur, "a")
        v1 = f"smoke-a-1-{uuid4().hex[:8]}"
        v2 = f"smoke-a-2-{uuid4().hex[:8]}"
        cur.execute(
            "INSERT INTO opengeo.dataset_version "
            "(dataset_version, region, run_id, feature_count, is_active) "
            "VALUES (%s, 'pune', %s, 1, false), (%s, 'pune', %s, 1, false)",
            (v1, run_id, v2, run_id),
        )
        cur.execute(f"SELECT opengeo.publish_dataset_version('{v1}')")
        cur.execute(f"SELECT opengeo.publish_dataset_version('{v2}')")
        cur.execute(
            "SELECT dataset_version, is_active FROM opengeo.dataset_version "
            "WHERE dataset_version = ANY(%s)",
            ([v1, v2],),
        )
        rows = {r[0]: r[1] for r in cur.fetchall()}
        assert rows[v1] is False
        assert rows[v2] is True


def test_second_active_is_rejected():
    if DSN is None:
        pytest.skip("OPENGEO_DATABASE_URL not set")
    import psycopg
    import psycopg.errors

    with psycopg.connect(DSN) as conn, conn.cursor() as cur:
        # Any earlier test may already hold the active slot for pune; clear it so
        # this test exercises the conflict on its own terms.
        cur.execute(
            "UPDATE opengeo.dataset_version SET is_active = false WHERE region = 'pune'"
        )
        run_id = _seed(cur, "b")
        v1 = f"smoke-b-1-{uuid4().hex[:8]}"
        v2 = f"smoke-b-2-{uuid4().hex[:8]}"
        cur.execute(
            "INSERT INTO opengeo.dataset_version "
            "(dataset_version, region, run_id, feature_count, is_active) "
            "VALUES (%s, 'pune', %s, 1, true), (%s, 'pune', %s, 1, false)",
            (v1, run_id, v2, run_id),
        )
        # Activating smoke-b-2 while smoke-b-1 is active must be rejected.
        with pytest.raises(psycopg.errors.UniqueViolation):
            cur.execute(
                f"UPDATE opengeo.dataset_version SET is_active = true "
                f"WHERE dataset_version = '{v2}'"
            )
        conn.rollback()

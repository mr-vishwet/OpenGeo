"""Unit tests for PostGIS import collection (mock-backed, no live DB needed)."""

from __future__ import annotations

import json
from unittest.mock import MagicMock, patch

import pytest

from opengeo.ingestion import SourceRef
from opengeo.ingestion.postgis import import_collection

SOURCE = SourceRef(
    name="OpenGeo synthetic fixtures",
    license="Apache-2.0",
    attribution="Synthetic test data authored for OpenGeo.",
    retrieved_at="2026-11-19",
)

POINT = {"type": "Point", "coordinates": [73.8567, 18.5204]}


def feature(feature_id: str, geometry: dict) -> dict:
    return {"type": "Feature", "geometry": geometry, "properties": {"id": feature_id}}


def collection(*features: dict) -> dict:
    return {"type": "FeatureCollection", "features": list(features)}


def _make_assessment(parsed: int, accepted: int, rejected: int) -> MagicMock:
    assessment = MagicMock()
    assessment.counts.parsed = parsed
    assessment.counts.accepted = accepted
    assessment.counts.rejected = rejected
    assessment.counts.rejected_ratio = rejected / parsed if parsed else 0.0
    assessment.rejections = []
    assessment.quality.model_dump_json.return_value = "{}"
    return assessment


def _mock_conn():
    """Mock a connection that works as a context manager (returns itself on __enter__)."""
    conn = MagicMock()
    conn.__enter__.return_value = conn
    cur = conn.cursor.return_value.__enter__.return_value
    return conn, cur


def test_import_collection_writes_source_run_version_and_features(tmp_path):
    document = collection(
        feature("opengeo:1", POINT),
        feature("opengeo:2", POINT),
    )
    path = tmp_path / "extract.geojson"
    path.write_text(json.dumps(document), encoding="utf-8")

    conn, cur = _mock_conn()

    with patch("opengeo.ingestion.postgis.assess") as mock_assess:
        mock_assess.return_value = _make_assessment(2, 2, 0)

        run = import_collection(
            conn,
            path,
            region="pune",
            source=SOURCE,
            parser_version="p1",
            transform_version="t1",
            run_id="run-001",
        )

    assert run.status.value == "published"
    assert run.run_id == "run-001"
    assert run.counts.parsed == 2
    assert run.counts.accepted == 2
    assert run.dataset_version.startswith("pune-")

    # source, import_run, dataset_version, 2 features, publish_dataset_version = 6
    assert cur.execute.call_count == 6
    publish_call = cur.execute.call_args_list[-1]
    assert "publish_dataset_version" in publish_call.args[0]


def test_import_collection_refuses_rejected_features(tmp_path):
    document = collection(feature("opengeo:1", POINT))
    path = tmp_path / "extract.geojson"
    path.write_text(json.dumps(document), encoding="utf-8")

    conn, cur = _mock_conn()

    with patch("opengeo.ingestion.postgis.assess") as mock_assess:
        mock_assess.return_value = _make_assessment(1, 0, 1)

        with pytest.raises(ValueError, match="has .* rejected features"):
            import_collection(
                conn,
                path,
                region="pune",
                source=SOURCE,
                parser_version="p1",
                transform_version="t1",
                run_id="run-001",
            )

    cur.execute.assert_not_called()


def test_import_collection_uses_source_sha256_for_version(tmp_path):
    document = collection(feature("opengeo:1", POINT))
    path = tmp_path / "extract.geojson"
    path.write_text(json.dumps(document), encoding="utf-8")

    conn, cur = _mock_conn()

    with patch("opengeo.ingestion.postgis.assess") as mock_assess:
        mock_assess.return_value = _make_assessment(1, 1, 0)

        run = import_collection(
            conn,
            path,
            region="pune",
            source=SOURCE,
            parser_version="p1",
            transform_version="t1",
            run_id="run-001",
        )

    assert run.source_sha256
    assert run.dataset_version == f"pune-{run.source_sha256[:12]}"

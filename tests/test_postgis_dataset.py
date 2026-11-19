"""Unit tests for the PostGIS-backed feature store (mock-backed, no live DB needed)."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from opengeo.api.postgis_dataset import PostgisFeatureStore


def _mock_conn(version_row, source_rows, place_rows):
    """Mock a connection that works as a context manager (returns itself on __enter__)."""
    conn = MagicMock()
    conn.__enter__.return_value = conn
    cur = conn.cursor.return_value.__enter__.return_value
    cur.fetchone.return_value = version_row
    cur.fetchall.side_effect = [source_rows, place_rows]
    return conn


def test_store_loads_active_version_and_features():
    conn = _mock_conn(
        ("pune-abc123",),
        [("OpenGeo synthetic fixtures", "Apache-2.0", "Synthetic data", None)],
        [
            (
                "opengeo:1",
                "cafe",
                '{"language": "mr", "value": "\u0915\u094d\u0930\u093e\u091a\u0947\u0928\u094d\u091f"}',
                '{"house_number": "759/75", "street": "FC Road"}',
                '{"category": "cafe"}',
                '{"type": "Point", "coordinates": [73.8567, 18.5204]}',
            ),
            (
                "opengeo:2",
                "cafe",
                None,
                None,
                '{"category": "cafe"}',
                '{"type": "Point", "coordinates": [73.8936, 18.5362]}',
            ),
        ],
    )

    with patch("psycopg.connect", return_value=conn):
        store = PostgisFeatureStore("postgresql://opengeo:opengeo@localhost:5432/opengeo")

    assert store.dataset_version == "pune-abc123"
    assert len(store.sources) == 1
    assert store.sources[0].name == "OpenGeo synthetic fixtures"

    features = {f.id: f for f in store.features()}
    assert set(features) == {"opengeo:1", "opengeo:2"}
    assert features["opengeo:1"].category == "cafe"
    assert features["opengeo:1"].geometry.geom_type == "Point"

    found = store.get("opengeo:1")
    assert found is not None
    assert found.id == "opengeo:1"

    missing = store.get("opengeo:999")
    assert missing is None


def test_store_rejects_empty_dsn():
    with pytest.raises(ValueError, match="OPENGEO_DATABASE_URL is required"):
        PostgisFeatureStore("")


def test_store_raises_when_no_active_version():
    conn = _mock_conn(None, [], [])
    with patch("psycopg.connect", return_value=conn):
        with pytest.raises(ValueError, match="no active dataset version for region"):
            PostgisFeatureStore("postgresql://opengeo:opengeo@localhost:5432/opengeo")


def test_store_points_yields_only_points():
    conn = _mock_conn(
        ("pune-abc123",),
        [("OpenGeo synthetic fixtures", "Apache-2.0", "Synthetic data", None)],
        [
            (
                "opengeo:1",
                "cafe",
                None,
                None,
                '{"category": "cafe"}',
                '{"type": "Point", "coordinates": [73.8567, 18.5204]}',
            ),
            (
                "opengeo:2",
                "polygon",
                None,
                None,
                '{"category": "region"}',
                '{"type": "Polygon", "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]]}',
            ),
        ],
    )

    with patch("psycopg.connect", return_value=conn):
        store = PostgisFeatureStore("postgresql://opengeo:opengeo@localhost:5432/opengeo")

    points = list(store.points())
    assert len(points) == 1
    assert points[0][0] == "opengeo:1"

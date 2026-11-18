import hashlib
import json
from pathlib import Path

import pytest

from opengeo.ingestion import ImportError_, assess
from opengeo.ingestion.cli import main

POINT = {"type": "Point", "coordinates": [73.8567, 18.5204]}
SQUARE = [
    [73.85, 18.52],
    [73.86, 18.52],
    [73.86, 18.53],
    [73.85, 18.53],
    [73.85, 18.52],
]
BOWTIE = [[0, 0], [2, 2], [2, 0], [0, 1], [0, 0]]


def feature(feature_id: str | None, geometry: dict) -> dict:
    properties = {} if feature_id is None else {"id": feature_id}
    return {"type": "Feature", "geometry": geometry, "properties": properties}


def collection(*features: dict) -> dict:
    return {"type": "FeatureCollection", "features": list(features)}


def write(tmp_path, document: dict, name: str = "extract.geojson"):
    path = tmp_path / name
    path.write_text(json.dumps(document), encoding="utf-8")
    return path


def test_the_shipped_fixture_passes_cleanly():
    assessment = assess(Path("data/fixtures/pune_places.geojson"))
    assert assessment.counts.parsed == 13
    assert assessment.counts.accepted == 13
    assert assessment.counts.rejected == 0
    assert assessment.quality.geometry_invalid == 0


def test_each_rejection_is_counted_by_reason(tmp_path):
    document = collection(
        feature("opengeo:1", POINT),
        feature("opengeo:2", {"type": "Polygon", "coordinates": [BOWTIE]}),
        feature(None, POINT),
        feature("opengeo:1", POINT),
    )
    assessment = assess(write(tmp_path, document))

    assert assessment.counts.parsed == 4
    assert assessment.counts.accepted == 1
    assert assessment.counts.rejected == 3
    assert assessment.quality.geometry_invalid == 1
    assert assessment.quality.missing_required_metadata == 1
    assert assessment.quality.suspected_duplicates == 1
    assert {r.reason: r.count for r in assessment.rejections} == {
        "duplicate_id": 1,
        "geometry:self_intersecting_ring": 1,
        "missing_required:id": 1,
    }


def test_a_file_that_is_not_a_feature_collection_is_refused(tmp_path):
    path = write(tmp_path, {"type": "Feature", "geometry": POINT})
    with pytest.raises(ImportError_):
        assess(path)


def test_invalid_json_is_refused_with_the_path_limit_in_the_message(tmp_path):
    path = tmp_path / "broken.geojson"
    path.write_text("{not json", encoding="utf-8")
    with pytest.raises(ImportError_):
        assess(path)


def test_cli_refuses_an_extract_over_the_rejection_limit(tmp_path):
    document = collection(
        feature("opengeo:1", POINT),
        feature("opengeo:2", {"type": "Polygon", "coordinates": [BOWTIE]}),
        feature("opengeo:3", {"type": "Polygon", "coordinates": [BOWTIE]}),
    )
    assert main(["--source", str(write(tmp_path, document)), "--json"]) == 1


def test_cli_passes_an_acceptable_extract(tmp_path):
    document = collection(feature("opengeo:1", POINT), feature("opengeo:2", POINT))
    assert main(["--source", str(write(tmp_path, document))]) == 0


def test_cli_verifies_the_checksum_before_reading(tmp_path):
    path = write(tmp_path, collection(feature("opengeo:1", POINT)))
    good = hashlib.sha256(path.read_bytes()).hexdigest()

    assert main(["--source", str(path), "--sha256", good]) == 0
    assert main(["--source", str(path), "--sha256", "0" * 64]) == 2

"""Cross-surface parity: the Dart SDK must judge geometry exactly as the service does.

Both suites read `tests/parity/geometry_vectors.json`. The verdicts are written
by hand, so neither implementation defines the expected answer.
"""

import json
from pathlib import Path

import pytest

from opengeo.geo import GeometryError, validate_geometry

VECTORS = json.loads(
    (Path(__file__).parent / "parity" / "geometry_vectors.json").read_text(encoding="utf-8")
)["vectors"]


@pytest.mark.parametrize("vector", VECTORS, ids=[v["name"] for v in VECTORS])
def test_python_matches_the_shared_vectors(vector):
    if vector["code"] is None:
        validate_geometry(vector["geometry"])
        return
    with pytest.raises(GeometryError) as exc:
        validate_geometry(vector["geometry"])
    assert exc.value.code.value == vector["code"]

import hashlib

import pytest

from opengeo.ingestion import (
    Counts,
    DatasetRegistry,
    ImportError_,
    ImportRun,
    Rejection,
    SourceRef,
    verify_source,
)

OSM = SourceRef(
    name="Geofabrik Maharashtra extract",
    url="https://download.geofabrik.de/asia/india/maharashtra-latest.osm.pbf",
    license="ODbL-1.0",
    attribution="© OpenStreetMap contributors, ODbL 1.0",
    retrieved_at="2026-11-19",
)


def run(run_id: str = "run-001", *, accepted: int = 100, rejected: int = 0) -> ImportRun:
    return ImportRun(
        run_id=run_id,
        region="pune",
        source=OSM,
        source_file="maharashtra-latest.osm.pbf",
        source_sha256="a" * 64,
        source_timestamp="2026-11-18T00:00:00Z",
        parser_version="pyosmium-4",
        transform_version="0.1.0",
        started_at="2026-11-19T09:00:00Z",
        counts=Counts(parsed=accepted + rejected, accepted=accepted, rejected=rejected),
        rejections=[Rejection(reason="invalid_geometry", count=rejected)] if rejected else [],
    )


def test_checksum_matches(tmp_path):
    source = tmp_path / "extract.osm.pbf"
    source.write_bytes(b"not really an osm file")
    expected = hashlib.sha256(b"not really an osm file").hexdigest()
    assert verify_source(source, expected) == expected


def test_checksum_mismatch_is_refused(tmp_path):
    source = tmp_path / "extract.osm.pbf"
    source.write_bytes(b"tampered")
    with pytest.raises(ImportError_) as exc:
        verify_source(source, "b" * 64)
    assert "checksum mismatch" in str(exc.value)


def test_missing_source_is_refused(tmp_path):
    with pytest.raises(ImportError_):
        verify_source(tmp_path / "absent.osm.pbf", "a" * 64)


def test_dataset_version_is_derived_from_region_and_checksum():
    assert run().dataset_version == "pune-aaaaaaaaaaaa"


def test_staged_run_is_not_served():
    registry = DatasetRegistry()
    registry.stage(run())
    assert registry.active is None


def test_publish_makes_the_run_served():
    registry = DatasetRegistry()
    registry.stage(run())
    version = registry.publish("run-001")
    assert version.dataset_version == "pune-aaaaaaaaaaaa"
    assert version.feature_count == 100
    assert version.license == "ODbL-1.0"
    assert registry.active is not None
    assert registry.active.run_id == "run-001"


def test_a_failed_run_leaves_the_active_dataset_untouched():
    registry = DatasetRegistry()
    registry.stage(run("run-001"))
    registry.publish("run-001")
    active_before = registry.active

    registry.stage(run("run-002"))
    registry.fail("run-002", "parse error at record 4102")

    assert registry.active == active_before
    assert registry.run("run-002").status == "failed"


def test_a_failed_run_cannot_be_published():
    registry = DatasetRegistry()
    registry.stage(run("run-001"))
    registry.fail("run-001", "checksum mismatch")
    with pytest.raises(ImportError_) as exc:
        registry.publish("run-001")
    assert "not staged" in str(exc.value)


def test_publishing_an_unknown_run_is_refused():
    with pytest.raises(ImportError_):
        DatasetRegistry().publish("ghost")


def test_a_run_cannot_be_staged_twice():
    registry = DatasetRegistry()
    registry.stage(run("run-001"))
    with pytest.raises(ImportError_):
        registry.stage(run("run-001"))


def test_a_run_with_too_many_rejections_is_not_published():
    registry = DatasetRegistry()
    registry.stage(run(rejected=40, accepted=60))
    with pytest.raises(ImportError_) as exc:
        registry.publish("run-001")
    assert "rejected" in str(exc.value)
    assert registry.active is None


def test_rollback_returns_to_the_previous_version():
    registry = DatasetRegistry()
    registry.stage(run("run-001"))
    first = registry.publish("run-001")

    second_run = run("run-002").model_copy(update={"source_sha256": "b" * 64})
    registry.stage(second_run)
    second = registry.publish("run-002")
    assert registry.active.dataset_version == second.dataset_version

    restored = registry.rollback()
    assert restored.dataset_version == first.dataset_version
    assert registry.active.dataset_version == first.dataset_version
    assert registry.run("run-002").status == "rolled_back"


def test_rollback_without_history_is_refused():
    with pytest.raises(ImportError_):
        DatasetRegistry().rollback()


def test_rejection_summary_groups_reasons():
    registry = DatasetRegistry()
    staged = run().model_copy(
        update={
            "rejections": [
                Rejection(reason="invalid_geometry", count=3),
                Rejection(reason="missing_metadata", count=2),
            ]
        }
    )
    registry.stage(staged)
    assert registry.run("run-001").reject_summary() == {
        "invalid_geometry": 3,
        "missing_metadata": 2,
    }


def test_rejected_ratio_of_an_empty_import_is_zero():
    assert Counts(parsed=0).rejected_ratio == 0

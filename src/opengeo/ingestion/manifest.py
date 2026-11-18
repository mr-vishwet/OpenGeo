"""Import runs, dataset versions and atomic publication.

An import is a transaction against a publication pointer, not an in-place
rewrite. A failed run must leave the served dataset untouched, and a published
dataset must be traceable to the exact source file, checksum and transformation
version that produced it.
"""

from __future__ import annotations

import hashlib
from datetime import UTC, datetime
from enum import StrEnum
from pathlib import Path

from pydantic import BaseModel, Field


class RunStatus(StrEnum):
    STAGED = "staged"
    PUBLISHED = "published"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class SourceRef(BaseModel):
    name: str
    url: str | None = None
    license: str
    attribution: str
    retrieved_at: str
    allowed_uses: list[str] = Field(default_factory=list)


class Counts(BaseModel):
    parsed: int = 0
    accepted: int = 0
    rejected: int = 0

    @property
    def rejected_ratio(self) -> float:
        return 0.0 if self.parsed == 0 else self.rejected / self.parsed


class Rejection(BaseModel):
    reason: str
    count: int


class QualityReport(BaseModel):
    geometry_invalid: int = 0
    missing_required_metadata: int = 0
    suspected_duplicates: int = 0
    stale_timestamp: int = 0
    notes: list[str] = Field(default_factory=list)


class ImportRun(BaseModel):
    run_id: str
    region: str
    source: SourceRef
    source_file: str
    source_sha256: str
    source_timestamp: str
    parser_version: str
    transform_version: str
    started_at: str
    finished_at: str | None = None
    status: RunStatus = RunStatus.STAGED
    counts: Counts = Field(default_factory=Counts)
    rejections: list[Rejection] = Field(default_factory=list)
    quality: QualityReport = Field(default_factory=QualityReport)

    @property
    def dataset_version(self) -> str:
        return f"{self.region}-{self.source_sha256[:12]}"

    def reject_summary(self) -> dict[str, int]:
        return {rejection.reason: rejection.count for rejection in self.rejections}


class DatasetVersion(BaseModel):
    dataset_version: str
    region: str
    run_id: str
    published_at: str
    source_sha256: str
    feature_count: int
    license: str
    attribution: str


class ImportError_(Exception):
    """Import refused. The message names the reason; the active dataset is untouched."""


REJECTION_BLOCK_RATIO = 0.20
REJECTION_WARN_RATIO = 0.05


def sha256_of(path: Path, *, chunk_size: int = 1 << 20) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(chunk_size):
            digest.update(chunk)
    return digest.hexdigest()


def verify_source(path: Path, expected_sha256: str) -> str:
    """Return the file's checksum, or refuse when it does not match.

    A mismatched extract is the cheapest possible place to stop: every later
    stage would otherwise publish unverified data under a trusted version.
    """
    if not path.is_file():
        raise ImportError_(f"source file not found: {path}")
    actual = sha256_of(path)
    if actual != expected_sha256:
        raise ImportError_(
            f"checksum mismatch for {path.name}: expected {expected_sha256[:12]}…, "
            f"got {actual[:12]}…"
        )
    return actual


def _now() -> str:
    return datetime.now(UTC).isoformat(timespec="seconds")


class DatasetRegistry:
    """Publication pointer plus history.

    Publishing is atomic: either the active version becomes the new one, or it
    does not change at all.
    """

    def __init__(self) -> None:
        self._runs: dict[str, ImportRun] = {}
        self._versions: dict[str, DatasetVersion] = {}
        self._active: str | None = None
        self._history: list[str] = []

    # ── staging ────────────────────────────────────────────────────────────

    def stage(self, run: ImportRun) -> ImportRun:
        if run.run_id in self._runs:
            raise ImportError_(f"run '{run.run_id}' already exists")
        staged = run.model_copy(update={"status": RunStatus.STAGED, "finished_at": _now()})
        self._runs[run.run_id] = staged
        return staged

    def fail(self, run_id: str, reason: str) -> ImportRun:
        run = self._require_run(run_id)
        failed = run.model_copy(
            update={
                "status": RunStatus.FAILED,
                "finished_at": _now(),
                "rejections": [*run.rejections, Rejection(reason=reason, count=1)],
            }
        )
        self._runs[run_id] = failed
        return failed

    # ── publication ────────────────────────────────────────────────────────

    def publish(self, run_id: str) -> DatasetVersion:
        run = self._require_run(run_id)
        if run.status is not RunStatus.STAGED:
            raise ImportError_(f"run '{run_id}' is {run.status.value}, not staged")

        ratio = run.counts.rejected_ratio
        if ratio > REJECTION_BLOCK_RATIO:
            raise ImportError_(
                f"refusing to publish: {ratio:.0%} of parsed records were rejected "
                f"(limit {REJECTION_BLOCK_RATIO:.0%})"
            )

        version = DatasetVersion(
            dataset_version=run.dataset_version,
            region=run.region,
            run_id=run.run_id,
            published_at=_now(),
            source_sha256=run.source_sha256,
            feature_count=run.counts.accepted,
            license=run.source.license,
            attribution=run.source.attribution,
        )
        self._versions[version.dataset_version] = version
        if self._active is not None:
            self._history.append(self._active)
        self._active = version.dataset_version
        self._runs[run_id] = run.model_copy(
            update={"status": RunStatus.PUBLISHED, "finished_at": _now()}
        )
        return version

    def rollback(self) -> DatasetVersion:
        """Return to the previously published version."""
        if not self._history:
            raise ImportError_("no previous dataset version to roll back to")
        previous = self._history.pop()
        if self._active is not None:
            self._runs_active_to_rolled_back()
        self._active = previous
        return self._versions[previous]

    def _runs_active_to_rolled_back(self) -> None:
        for version in self._versions.values():
            if version.dataset_version == self._active:
                run = self._runs.get(version.run_id)
                if run is not None:
                    self._runs[version.run_id] = run.model_copy(
                        update={"status": RunStatus.ROLLED_BACK}
                    )

    # ── queries ────────────────────────────────────────────────────────────

    @property
    def active(self) -> DatasetVersion | None:
        return None if self._active is None else self._versions[self._active]

    def version(self, dataset_version: str) -> DatasetVersion | None:
        return self._versions.get(dataset_version)

    def run(self, run_id: str) -> ImportRun | None:
        return self._runs.get(run_id)

    def history(self) -> list[DatasetVersion]:
        return [self._versions[version] for version in self._history]

    def _require_run(self, run_id: str) -> ImportRun:
        run = self._runs.get(run_id)
        if run is None:
            raise ImportError_(f"unknown run '{run_id}'")
        return run

"""`opengeo-ingest`: measure an extract and refuse it when it is mostly garbage.

    # Measure only (gate):
    opengeo-ingest --source data/raw/pune.osm.geojson --sha256 <hex> --json

    # Measure and publish to PostGIS:
    opengeo-ingest publish --source data/raw/pune.osm.geojson --dsn <dsn> \
        --region pune --run-id run-001

Exit code 0 means the extract is fit to stage; 1 means the rejection ratio is
over the publication limit; 2 means the extract could not be read.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .manifest import REJECTION_BLOCK_RATIO, ImportError_, sha256_of
from .postgis import import_collection
from .quality import assess


def _cmd_assess(args: argparse.Namespace) -> int:
    try:
        if args.sha256 and sha256_of(args.source) != args.sha256:
            raise ImportError_(
                f"checksum mismatch for {args.source.name}: nothing was read beyond the hash"
            )
        assessment = assess(args.source)
    except ImportError_ as exc:
        print(f"refused: {exc}", file=sys.stderr)
        return 2

    report = assessment.as_report()
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        counts = report["counts"]
        print(
            f"{args.source}: parsed={counts['parsed']} accepted={counts['accepted']} "
            f"rejected={counts['rejected']} ({report['rejected_ratio']:.1%})"
        )
        for rejection in report["rejections"]:
            print(f"  {rejection['reason']}: {rejection['count']}")

    if assessment.counts.rejected_ratio > REJECTION_BLOCK_RATIO:
        print(
            f"refused: {assessment.counts.rejected_ratio:.0%} rejected, over the "
            f"{REJECTION_BLOCK_RATIO:.0%} publication limit",
            file=sys.stderr,
        )
        return 1
    return 0


def _cmd_publish(args: argparse.Namespace) -> int:
    from opengeo.ingestion import SourceRef

    try:
        if args.sha256 and sha256_of(args.source) != args.sha256:
            raise ImportError_(
                f"checksum mismatch for {args.source.name}: nothing was read beyond the hash"
            )
    except ImportError_ as exc:
        print(f"refused: {exc}", file=sys.stderr)
        return 2

    source = SourceRef(
        name=args.source_name or args.source.stem,
        license=args.license,
        attribution=args.attribution,
        retrieved_at=args.retrieved_at,
    )

    import psycopg

    try:
        with psycopg.connect(args.dsn) as conn:
            run = import_collection(
                conn,
                args.source,
                region=args.region,
                source=source,
                parser_version=args.parser_version,
                transform_version=args.transform_version,
                run_id=args.run_id,
            )
    except ImportError_ as exc:
        print(f"refused: {exc}", file=sys.stderr)
        return 2
    except Exception as exc:  # noqa: BLE001 - database errors are operational
        print(f"publish failed: {exc}", file=sys.stderr)
        return 3

    print(
        f"published run={run.run_id} version={run.dataset_version} "
        f"accepted={run.counts.accepted} rejected={run.counts.rejected}"
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    assess_p = sub.add_parser("assess", help="measure an extract without publishing")
    assess_p.add_argument("--source", type=Path, required=True, help="GeoJSON FeatureCollection")
    assess_p.add_argument("--sha256", help="expected checksum; refuses the file when it differs")
    assess_p.add_argument("--json", action="store_true", help="print the report as JSON")
    assess_p.set_defaults(func=_cmd_assess)

    publish_p = sub.add_parser("publish", help="measure and publish to PostGIS")
    publish_p.add_argument("--source", type=Path, required=True, help="GeoJSON FeatureCollection")
    publish_p.add_argument("--sha256", help="expected checksum; refuses the file when it differs")
    publish_p.add_argument("--dsn", required=True, help="PostgreSQL connection string")
    publish_p.add_argument("--region", required=True, help="region name, e.g. pune")
    publish_p.add_argument("--run-id", required=True, help="unique import run id")
    publish_p.add_argument(
        "--source-name", help="source name (defaults to source file stem)"
    )
    publish_p.add_argument("--license", default="ODbL-1.0", help="source license")
    publish_p.add_argument("--attribution", default="", help="source attribution")
    publish_p.add_argument("--retrieved-at", default="", help="source retrieval timestamp")
    publish_p.add_argument("--parser-version", default="opengeo-ingest 0.1.0")
    publish_p.add_argument("--transform-version", default="none")
    publish_p.set_defaults(func=_cmd_publish)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())

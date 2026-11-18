"""`opengeo-ingest`: measure an extract and refuse it when it is mostly garbage.

    opengeo-ingest --source data/raw/pune.osm.geojson --sha256 <hex> --json

Exit code 0 means the extract is fit to stage; 1 means the rejection ratio is
over the publication limit, so staging it would only waste a run.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .manifest import REJECTION_BLOCK_RATIO, ImportError_, sha256_of
from .quality import assess


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="GeoJSON FeatureCollection")
    parser.add_argument("--sha256", help="expected checksum; refuses the file when it differs")
    parser.add_argument("--json", action="store_true", help="print the report as JSON")
    args = parser.parse_args(argv)

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
        print(f"{args.source}: parsed={counts['parsed']} accepted={counts['accepted']} "
              f"rejected={counts['rejected']} ({report['rejected_ratio']:.1%})")
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


if __name__ == "__main__":
    raise SystemExit(main())

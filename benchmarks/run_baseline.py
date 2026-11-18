"""OpenGeoBench baseline: measure before claiming anything.

Records the environment that produced the numbers, because a latency figure
without commit, dataset version, hardware and warm/cold state is not evidence.

    python benchmarks/run_baseline.py --iterations 2000
"""

from __future__ import annotations

import argparse
import json
import platform
import statistics
import subprocess
import sys
import time
from datetime import UTC, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from fastapi.testclient import TestClient  # noqa: E402

from opengeo import __version__  # noqa: E402
from opengeo.api.app import create_app  # noqa: E402
from opengeo.api.dataset import load_default_store  # noqa: E402
from opengeo.geo import LonLat  # noqa: E402
from opengeo.geo.predicates import geodesic_distance, within_radius  # noqa: E402
from opengeo.mcp import validate_plan  # noqa: E402

PUNE = LonLat(73.8567, 18.5204)
MUMBAI = LonLat(72.8777, 19.0760)


def percentiles(samples: list[float]) -> dict[str, float]:
    ordered = sorted(samples)
    return {
        "p50_ms": round(statistics.median(ordered) * 1000, 3),
        "p95_ms": round(ordered[int(len(ordered) * 0.95) - 1] * 1000, 3),
        "p99_ms": round(ordered[int(len(ordered) * 0.99) - 1] * 1000, 3),
        "mean_ms": round(statistics.fmean(ordered) * 1000, 3),
    }


def git_commit() -> str:
    try:
        return subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"


def environment(store) -> dict:
    import shapely

    return {
        "measured_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "opengeo_version": __version__,
        "commit": git_commit(),
        "python": sys.version.split()[0],
        "shapely": shapely.__version__,
        "os": f"{platform.system()} {platform.release()}",
        "machine": platform.machine(),
        "cpu_count": __import__("os").cpu_count(),
        "dataset_version": store.dataset_version,
        "dataset_features": len(store.features()),
        "authoritative_store": "geojson-fixture (no PostGIS, no spatial index)",
    }


def bench_pure_python(iterations: int) -> dict:
    geodesic: list[float] = []
    for _ in range(iterations):
        started = time.perf_counter()
        geodesic_distance(PUNE, MUMBAI)
        geodesic.append(time.perf_counter() - started)

    store = load_default_store()
    points = list(store.points())
    nearby: list[float] = []
    for _ in range(max(1, iterations // 20)):
        started = time.perf_counter()
        within_radius(PUNE, 2000, points)
        nearby.append(time.perf_counter() - started)

    plan = {
        "operation": "nearby",
        "center": {"longitude": 73.8567, "latitude": 18.5204},
        "radius": {"value": 1200},
    }
    validation: list[float] = []
    for _ in range(max(1, iterations // 10)):
        started = time.perf_counter()
        validate_plan(plan)
        validation.append(time.perf_counter() - started)

    return {
        "geodesic_distance": percentiles(geodesic),
        "nearby_scan_fixture_features": percentiles(nearby),
        "plan_validation": percentiles(validation),
    }


def bench_http(iterations: int) -> dict:
    app = create_app(store_factory=load_default_store)
    with TestClient(app) as client:
        cold_started = time.perf_counter()
        client.post(
            "/v1/nearby",
            json={
                "center": {"longitude": 73.8794, "latitude": 18.5158},
                "radius": {"value": 2, "unit": "km"},
            },
        )
        cold_ms = (time.perf_counter() - cold_started) * 1000

        samples: list[float] = []
        for _ in range(iterations):
            started = time.perf_counter()
            response = client.post(
                "/v1/nearby",
                json={
                    "center": {"longitude": 73.8794, "latitude": 18.5158},
                    "radius": {"value": 2, "unit": "km"},
                    "limit": 10,
                },
            )
            samples.append(time.perf_counter() - started)
            if response.status_code != 200:
                raise SystemExit(f"nearby failed with {response.status_code}")

        distance_samples: list[float] = []
        for _ in range(iterations):
            started = time.perf_counter()
            client.post(
                "/v1/spatial/distance",
                json={
                    "origin": {"longitude": 73.8567, "latitude": 18.5204},
                    "destination": {"longitude": 72.8777, "latitude": 19.076},
                    "unit": "km",
                },
            )
            distance_samples.append(time.perf_counter() - started)

    return {
        "nearby_http_cold_ms": round(cold_ms, 3),
        "nearby_http": percentiles(samples),
        "distance_http": percentiles(distance_samples),
        "note": "in-process ASGI client; excludes network and TLS",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iterations", type=int, default=1000)
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()

    store = load_default_store()
    report = {
        "environment": environment(store),
        "pure_python": bench_pure_python(args.iterations),
        "http": bench_http(max(10, args.iterations // 10)),
        "limits": [
            "Fixture store, no spatial index, no database.",
            "Numbers describe this laptop, not a deployment.",
        ],
    }

    payload = json.dumps(report, indent=2)
    print(payload)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(payload + "\n", encoding="utf-8")
        print(f"\nwritten to {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

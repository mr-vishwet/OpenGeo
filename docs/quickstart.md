# Quickstart

## Run the API locally

```bash
python -m venv .venv
.venv/Scripts/activate          # Windows
pip install -e ".[dev]"

opengeo-api                     # http://127.0.0.1:8080
```

Or run it without installing the entry point:

```bash
uvicorn opengeo.api.app:app --reload --port 8080
```

Interactive schema: <http://127.0.0.1:8080/docs>

## Check what this deployment can actually do

```bash
curl -s http://127.0.0.1:8080/v1/capabilities
```

Read `state` on each capability before trusting a feature. `postgis`,
`geocoding`, `routing`, `tiles` and `offline` are not available in the
reference deployment, and the manifest says so.

## Nearby search

```bash
curl -s -X POST http://127.0.0.1:8080/v1/nearby \
  -H 'content-type: application/json' \
  -d '{
    "center": {"longitude": 73.8794, "latitude": 18.5158},
    "radius": {"value": 2, "unit": "km"},
    "categories": ["cafe"],
    "limit": 5
  }'
```

Every response carries `meta.request_id`, `meta.dataset_version`,
`provenance.sources` and `warnings`. Distances are metres with a declared
method; `distance_m: null` means unknown, never zero.

## Straight-line distance

```bash
curl -s -X POST http://127.0.0.1:8080/v1/spatial/distance \
  -H 'content-type: application/json' \
  -d '{
    "origin": {"longitude": 73.8567, "latitude": 18.5204},
    "destination": {"longitude": 72.8777, "latitude": 19.076},
    "unit": "km"
  }'
```

`network_travel` is refused with `unsupported_capability`: no routing engine is
configured, and a straight line must not be returned in its place.

## Containment with explicit boundary rules

```bash
curl -s -X POST http://127.0.0.1:8080/v1/spatial/contains \
  -H 'content-type: application/json' \
  -d '{
    "container_feature_id": "opengeo:fixture:region:0001",
    "candidate_position": {"longitude": 73.855, "latitude": 18.525},
    "boundary_rule": "covers"
  }'
```

`contains` excludes the boundary, `covers` includes it. Two predicates, not one
ambiguous boolean.

## Serve a real region

Blocked on the prerequisites in `.docs/PREREQUISITES.md`: Docker, PostGIS and a
regional extract. When those exist:

```bash
cp .env.example .env            # set POSTGRES_PASSWORD
docker compose -f infrastructure/compose.dev.yml up -d
```

The migration in `infrastructure/db/migrations/0001_init.sql` enforces one active
dataset version per region and rejects invalid geometry at insert time.

## Tests

```bash
pytest                                   # Python: 93 tests
cd packages/geo_types && dart test       # Dart: 47 tests
```

## Measure

```bash
python benchmarks/run_baseline.py --iterations 1000
```

The report records commit, dataset version, dependency versions and hardware.
A number without that context is not a benchmark.

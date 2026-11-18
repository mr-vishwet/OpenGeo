# OpenGeo

A modular, self-hostable geospatial platform: one spatial engine, multiple rendering
environments, on-demand geographic data, modular capabilities for apps, agents and games.

Implementation baseline: `OpenGeo PRD & Technical Implementation Specification v2.0`
(18 Nov 2026). Planning material, ADR drafts and research notes live in `.docs/`, which is
never committed.

## Status

Phase 1 — the spatial core runs and is tested; the data plane is not installed.

Working today:

- **HTTP service** (`opengeo-api`): capability manifest, dataset metadata, place lookup,
  nearby search, geodesic distance, `contains`/`covers` and `intersects` predicates. Every
  response carries request id, dataset version, provenance and warnings.
- **MCP server** (`opengeo-mcp`, stdio): the four spatial tools this build can actually
  honour. Routing, geocoding and isochrones are absent rather than stubbed.
- **Dart SDK** (`packages/geo_types`): coordinate, CRS, bounding box, distance and the seven
  geometry types, validated at construction.

Not installed: Docker, PostGIS, a regional OSM extract, any search, geocoding or routing
engine, and any tile stack. `GET /v1/capabilities` is the authority on what runs, and
[`docs/known-limitations.md`](docs/known-limitations.md) says what does not.

No feature counts as complete until it has tests, docs and an observable failure mode.

## Layout

The tree is grown phase by phase rather than scaffolded empty. Directories appear when
their milestone starts.

```
src/opengeo/            the single Python distribution
  api/                  FastAPI service: routes, envelope, errors, fixture store
  geo/                  units, geodesy, validation boundary, predicates
  ingestion/            checksummed manifests, atomic publish, rollback
  mcp/                  tool catalogue, plan validator, stdio server
packages/geo_types/     canonical coordinate, CRS, bbox and geometry types (Dart)
tests/                  Python suite plus the shared parity vectors
infrastructure/         Compose, PostGIS migration, API image
benchmarks/             OpenGeoBench baseline runner
docs/                   public documentation
adr/                    architecture decision records
```

Rules that hold across every package: a package declares ownership, public API, dependencies,
supported platforms, stability, license and test command; `geo_types` must never depend on a
renderer, a database or an HTTP client.

## Prerequisites

See `.docs/PREREQUISITES.md` for the full inventory, measured host readiness and the ordered
acquisition plan. The short version: Git, Dart/Flutter and Python 3.13 are present; Docker,
PostGIS, a regional OSM extract and every search/routing/tile engine are not.

## Development

```bash
# Python: API, MCP server, tests
py -3.13 -m venv .venv
.venv/Scripts/activate
pip install -e ".[dev]"
pytest
ruff check src tests

# Dart SDK
cd packages/geo_types && dart pub get && dart test
```

`tests/parity/geometry_vectors.json` is validated by both suites, so the SDK and the service
cannot drift apart silently.

Core services (requires Docker, not present on this host yet):

```bash
cp .env.example .env            # set POSTGRES_PASSWORD
docker compose -f infrastructure/compose.dev.yml up -d
```

## Licensing

Code: **Apache-2.0** ([ADR-0009](adr/0009-apache-2-license.md)). OSM-derived data stays under
ODbL and remains separate from the code; attribution must stay visible in every client. Do not
redistribute a derived database without reviewing
[`DATA_SOURCES.md`](DATA_SOURCES.md) and [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

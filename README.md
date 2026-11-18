# OpenGeo

A modular, self-hostable geospatial platform: one spatial engine, multiple rendering
environments, on-demand geographic data, modular capabilities for apps, agents and games.

Implementation baseline: `OpenGeo PRD & Technical Implementation Specification v2.0`
(18 Nov 2026). Planning material, ADR drafts and research notes live in `.docs/`, which is
never committed.

## Status

Phase 0 — repository baseline. No feature is complete until it has tests, docs and an
observable failure mode.

## Layout

The tree is grown phase by phase rather than scaffolded empty. Directories appear when
their milestone starts.

```
packages/geo_types/     canonical coordinate, CRS, bbox and geometry types (Dart)
packages/               shared contracts: geo-query, geo-context, provider-contracts, client-core
apps/api/               spatial + search + routing HTTP service
apps/mcp/               MCP adapter over the same application services
apps/ingestion/         OSM extract → normalized, versioned dataset
services/               spatial, search, geocoding, routing, tiles
sdk/                    flutter, android, ios, web
integrations/           unity, unreal
infrastructure/         Compose, CI, deployment
benchmarks/             OpenGeoBench tracks and fixtures
docs/                   public documentation
adr/                    architecture decision records
```

Rules that hold across every package: a package declares ownership, public API, dependencies,
supported platforms, stability, license and test command; `geo_types` must never depend on a
renderer, a database or an HTTP client.

## Prerequisites

See `.docs/PREREQUISITES.md` for the full inventory, measured host readiness and the ordered
acquisition plan. The short version: Git, Dart/Flutter and Python are present; Docker,
PostGIS, a regional OSM extract and the backend-language decision are not.

## Development

```bash
# Dart packages
dart pub get
dart test

# Python tooling
python -m venv .venv && .venv/Scripts/activate
pip install -r requirements-dev.txt

# Core services (requires Docker)
docker compose -f infrastructure/compose.dev.yml up -d
```

## Licensing

Not yet decided — see PRD §44/§55. OSM-derived data carries ODbL obligations; attribution must
remain visible in every client. Do not redistribute derived databases without review.

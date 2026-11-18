# OpenGeo

[![CI status](https://img.shields.io/github/actions/workflow/status/mr-vishwet/OpenGeo/.github/workflows/ci.yml?branch=main&label=CI)](https://github.com/mr-vishwet/OpenGeo/actions)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Python 3.13](https://img.shields.io/badge/Python-3.13-blue)](https://python.org)
[![Dart 3.14](https://img.shields.io/badge/Dart-3.14-blue)](https://dart.dev)
[![Data: ODbL](https://img.shields.io/badge/Data-ODbL-green)](DATA_SOURCES.md)

OpenGeo is a modular, self-hostable geospatial platform: one spatial engine, multiple rendering environments, on-demand geographic data, and modular capabilities for apps, agents and games.

Coordinates are **EPSG:4326, longitude first**. Distances carry an explicit **unit and method**. Bad geometry is rejected with a **stable error code** — never silently repaired. One geography implementation powers every surface (HTTP API, MCP server, Dart SDK), so an answer cannot differ between REST and MCP.

## What OpenGeo does

- **HTTP API** (`opengeo-api`) — place lookup, nearby search, geodesic distance, `contains`/`covers`/`intersects` predicates. Every response carries request id, dataset version, provenance and warnings.
- **MCP server** (`opengeo-mcp`, stdio) — publishes `geo.nearby`, `geo.distance`, `geo.contains`, `geo.intersects` to AI agents. Only what this build can actually serve; routing and geocoding are absent, not stubbed.
- **Dart SDK** (`packages/geo_types`) — `Coordinate`, `Crs`, `BoundingBox`, `Distance`, and seven GeoJSON geometry types with validation. No renderer, database or HTTP dependency.
- **Ingestion gate** (`opengeo-ingest`) — checksum-verified extracts, import runs, atomic publication with rollback, refusal above a 20 % rejection ratio.

```mermaid
flowchart TD
    subgraph Surfaces
        API[HTTP API • FastAPI]
        MCP[MCP server • stdio]
        SDK[Dart SDK • geo_types]
    end

    subgraph Application["Application & trust boundary"]
        Store[Feature store • validates geometry via GEOS/shapely]
    end

    subgraph Data["Data plane"]
        Fixture[GeoJSON fixture • Pune, 13 places]
        PostGIS[PostGIS 16 • geography GiST index]
    end

    API --> Store
    MCP --> Store
    Store --> Fixture
    Store -.->|OPENGEO_STORE=postgis| PostGIS
```

## Quickstart

### Run the API

```bash
python -m venv .venv
.venv/Scripts/activate        # Windows
pip install -e ".[dev]"

opengeo-api                   # http://127.0.0.1:8080
```

Interactive schema: <http://127.0.0.1:8080/docs>

### Nearby search around Pune

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

### Dart SDK

```bash
cd packages/geo_types
dart pub get
dart test
dart analyze
```

### MCP server (for AI agents)

```bash
opengeo-mcp        # stdio transport; publishes exactly 4 spatial tools
```

### Serve a real database (PostGIS)

```bash
cp .env.example .env            # set POSTGRES_PASSWORD
docker compose -f infrastructure/compose.dev.yml --env-file .env up -d

OPENGEO_STORE=postgis \
OPENGEO_DATABASE_URL=postgresql://opengeo:<password>@localhost:5432/opengeo \
opengeo-api
```

### Import a real extract

```bash
opengeo-ingest --source data/raw/pune.osm.geojson --sha256 <hex> --json
```

The gate validates every feature through the API's trust boundary and refuses when more than 20 % of records fail. Nothing is repaired silently.

## Tests

```bash
pytest                                   # Python suite
cd packages/geo_types && dart test       # Dart suite
ruff check src tests                     # lint
dart analyze                             # Dart analyzer
```

## Use cases

| | | | |
|---|---|---|---|
| ![1](docs/images/usecase-01.png)<br>**1. Nearby POI search**<br>“What cafés are within 2 km of Shivajinagar?” | ![2](docs/images/usecase-02.png)<br>**2. Straight-line distance**<br>“How far is Cafe Goodluck from Pune Junction?” | ![3](docs/images/usecase-03.png)<br>**3. Point-in-region check**<br>“Is this address inside the Pune municipal boundary?” | ![4](docs/images/usecase-04.png)<br>**4. Line-region intersection**<br>“Does this delivery route cross the restricted zone?” |
| ![5](docs/images/usecase-05.png)<br>**5. Dataset versioning**<br>“Serve the Pune extract from 14 Nov; roll back if bad.” | ![6](docs/images/usecase-06.png)<br>**6. Boundary-in vs boundary-on**<br>“`contains` excludes the edge; `covers` includes it.” | ![7](docs/images/usecase-07.png)<br>**7. Multi-region rollout**<br>“Pune first, then Bengaluru — one active version per region.” | ![8](docs/images/usecase-08.png)<br>**8. Agent tool access**<br>“MCP server lets an AI agent call `geo.nearby` over stdio.” |
| ![9](docs/images/usecase-09.png)<br>**9. Extract ingestion gate**<br>“Reject an OSM extract if >20 % of features fail validation.” | ![10](docs/images/usecase-10.png)<br>**10. Stable error codes**<br>“`invalid_ring` vs `self_intersecting_ring` — branch on code, not message.” | ![11](docs/images/usecase-11.png)<br>**11. Capability manifest**<br>“`GET /v1/capabilities` tells a client what this deployment refuses.” | ![12](docs/images/usecase-12.png)<br>**12. Latency baseline**<br>“`benchmarks/run_baseline.py` records p50/p95/p99 with commit + hardware.” |
| ![13](docs/images/usecase-13.png)<br>**13. Cross-surface parity**<br>“Python and Dart judge the same 29 geometry vectors identically.” | ![14](docs/images/usecase-14.png)<br>**14. PostGIS authority**<br>“Serve from PostGIS via `OPENGEO_STORE=postgis`; GiST index on geography.” | ![15](docs/images/usecase-15.png)<br>**15. Atomic publication**<br>“`publish_dataset_version()` flips the active version in one transaction.” | ![16](docs/images/usecase-16.png)<br>**16. Indian metros roadmap**<br>“Pune → Bengaluru → other metros (ADR-0010, Pune first).” |

Drop your 16 reference screenshots into `docs/images/usecase-01.png` … `usecase-16.png` and they render here automatically.

## License

Code: **Apache-2.0**. OSM-derived data stays under ODbL and remains separate from the code; attribution stays visible in every client.

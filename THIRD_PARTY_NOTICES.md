# Third-party notices

OpenGeo code is Apache-2.0 (see `LICENSE`). This file records third-party
components and their licenses. It is a working inventory, not a completed legal
review: every entry must be re-verified against the installed version before a
release.

## Python runtime dependencies

| Component | Role | License | Notes |
|---|---|---|---|
| FastAPI | HTTP framework | MIT | |
| Pydantic | Boundary validation and schemas | MIT | |
| Uvicorn | ASGI server | BSD-3-Clause | |
| jsonschema | Tool and plan schema validation | MIT | |
| Shapely | GEOS binding used by the reference path | BSD-3-Clause | Wraps GEOS |

## Python development dependencies

| Component | Role | License |
|---|---|---|
| pytest | Test runner | MIT |
| httpx | HTTP client for tests | BSD-3-Clause |
| ruff | Lint and format | MIT |

## Dart

| Component | Role | License |
|---|---|---|
| `test` | Dart test runner (dev only) | BSD-3-Clause |

`packages/geo_types` has no runtime dependencies by design.

## Planned integrations (not yet pinned)

| Component | Role | License | Status |
|---|---|---|---|
| PostgreSQL / PostGIS | Authoritative spatial store | PostgreSQL License / GPL-2.0 | not installed |
| GEOS | Geometry engine | LGPL-2.1 | via Shapely/PostGIS |
| PROJ | CRS transforms | MIT-style (X/MIT) | not installed |
| MapLibre Flutter | 2D renderer adapter | BSD-2-Clause | not pinned |
| Valhalla | Routing engine | MIT (Apache-2.0 for some parts — verify) | not evaluated |
| Pelias | Geocoding engine | Apache-2.0 | not evaluated |
| PMTiles | Tile archive delivery | BSD-3-Clause | not evaluated |
| H3 | Hierarchical indexing | Apache-2.0 | not used |

License compatibility with Apache-2.0 distribution must be confirmed before a
dependency is pinned. A component with an incompatible license requires an ADR,
not a quiet addition.

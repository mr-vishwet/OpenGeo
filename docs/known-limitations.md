# Known limitations

Read this before relying on anything. Every entry is a fact about the current
commit, not a roadmap aspiration.

## Data

- The served dataset is a **13-feature synthetic fixture** around Pune. It is not
  OpenStreetMap data and not a place database.
- No regional OSM extract has been imported yet. Fetching one needs osmium/PBF
  tooling (not available on this Windows host without a C++ toolchain) or an
  Overpass→GeoJSON conversion step. The import pipeline
  (`opengeo.ingestion.postgis.import_collection`, `opengeo-ingest`) is built and
  proven against the fixture; pointing it at a real extract is the remaining step.
- Indian address data in OSM is uneven. A search baseline measured against Pune
  measures coverage as much as engine quality.

## Services

- PostGIS 16 is attached and the dev stack serves the imported Pune fixture
  through a geography GiST expression index; `nearby` uses `ST_DWithin(geography)`.
  The API defaults to the GeoJSON fixture and only uses PostGIS when
  `OPENGEO_STORE=postgis` is set.
- `network_travel` distance, routing, isochrones and map matching are unavailable
  and are refused with `unsupported_capability` rather than approximated.
- Geocoding and search are unavailable. No engine has been evaluated (OG-009).
- Tiles, offline packs and 3D streaming are not implemented.
- The MCP server runs over stdio only. It is not deployed behind a network
  transport, and it serves the four spatial tools this build can honour; no
  other tool is published.
- No authentication, rate limiting or quota exists yet. This build is a local
  development deployment and must not be exposed publicly.

## Client surfaces

- `packages/geo_types` (Dart) is the only SDK surface. There is no map widget, no
  Android/iOS/web SDK and no Unity or Unreal integration.
- MapLibre has not been pinned or compatibility-tested (ADR-0004 remains a
  decision without a spike).

## Correctness limits that are by design

- A mid-latitude longitude/latitude swap cannot be detected from range alone.
  Only a bounding-box or dataset-extent check catches it.
- `within_radius` in the reference path accepts Point features only. Polygonal
  proximity needs `ST_DWithin(geography)`.
- Bounding boxes computed from geometry straddling the antimeridian span nearly
  the whole world; wrapped boxes are only correct when authored directly.
- A `MultiPolygon` whose members overlap is not rejected in the Dart validator;
  PostGIS `ST_IsValid` catches it at insert. Python rejects it earlier, reporting
  `invalid_geometry`, so the two surfaces disagree on that one input class and
  the parity vectors do not cover it.
- Validation errors reach HTTP clients as `invalid_input` with the finer code in
  `details.geometry_code`. A client that branches only on the top-level `code`
  learns less than one using the SDK.

## Operations

- The dev stack runs on this host: Docker Desktop 4.99 + WSL2 (Ubuntu). PostGIS
  16 is healthy and migration `0001_init.sql` applies on a fresh volume. The
  stack is started with `docker compose -f infrastructure/compose.dev.yml
  --env-file .env up -d`. The atomic-publication invariant was smoke-verified:
  `publish_dataset_version()` flips the active version per region, and a direct
  update forcing two active versions is rejected by the
  `dataset_version_one_active_per_region` index.
- The API defaults to the GeoJSON fixture; set `OPENGEO_STORE=postgis` and
  `OPENGEO_DATABASE_URL` to serve the active PostGIS dataset version instead.
  The running dev stack is configured this way and serves the imported Pune
  fixture through a geography GiST index.
- No backup/restore has been performed.
- CI configuration has not executed on a remote runner. It is written against
  the commands that pass locally, including a PostGIS service job that applies
  the migration and runs the publication smoke test.

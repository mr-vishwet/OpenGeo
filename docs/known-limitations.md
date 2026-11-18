# Known limitations

Read this before relying on anything. Every entry is a fact about the current
commit, not a roadmap aspiration.

## Data

- The served dataset is a **13-feature synthetic fixture** around Pune. It is not
  OpenStreetMap data and not a place database.
- No regional OSM extract has been imported. There is no search index, no
  routing graph and no tile archive.
- Indian address data in OSM is uneven. A search baseline measured against Pune
  measures coverage as much as engine quality.

## Services

- PostGIS is not attached. Predicates run on GEOS in-process, with no spatial
  index: `nearby` is a linear scan.
- `network_travel` distance, routing, isochrones and map matching are unavailable
  and are refused with `unsupported_capability` rather than approximated.
- Geocoding and search are unavailable. No engine has been evaluated (OG-009).
- Tiles, offline packs and 3D streaming are not implemented.
- The MCP transport adapter is not deployed. Tool schemas and the plan validator
  exist and are tested; no server is running.
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
  PostGIS `ST_IsValid` catches it at insert.

## Operations

- `infrastructure/compose.dev.yml` has never been run: this machine has no Docker
  and no WSL2. Treat the first `up` as untested.
- No backup/restore has been performed, because there is no database yet.
- CI configuration has not executed on a remote runner. It is written against
  the commands that pass locally.

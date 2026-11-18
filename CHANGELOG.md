# Changelog

All observable changes are recorded here. Format follows Keep a Changelog;
versioning follows semantic versioning once a public package is published.

## [0.1.0] — 2026-11-19

First vertical slice. Everything below is backed by tests; nothing is claimed
beyond what the capability manifest reports.

### Added

- `packages/geo_types` (Dart, no runtime dependencies): `Coordinate` with named
  longitude/latitude, `Crs` with explicit axis order, antimeridian-aware
  `BoundingBox`, `Distance` with unit and method, and the seven GeoJSON geometry
  types with ring closure, degeneracy, self-intersection and hole containment
  validation.
- `opengeo.geo`: geometry validation boundary with stable snake_case codes,
  WGS84 geodesic distance (Vincenty with a documented haversine fallback), and
  PostGIS-aligned predicates (`contains` excludes the boundary, `covers`
  includes it).
- `opengeo.api`: versioned HTTP contract with the `data`/`meta`/`provenance`/
  `warnings` envelope, request ids, stable error codes, `/healthz`, `/readyz`,
  `/v1/capabilities`, `/v1/datasets`, `/v1/places/{id}`, `/v1/nearby`,
  `/v1/spatial/distance`, `/v1/spatial/contains`, `/v1/spatial/intersects`, and
  OpenAPI generated from the implementation.
- `opengeo.mcp`: tool catalogue with strict JSON Schemas, units, bounds,
  permissions and examples, plus a server-side plan validator enforcing
  operation, schema, permissioned context references, bounds and step budget.
  An `opengeo-mcp` stdio server publishes the four tools this build can honour.
- `opengeo.ingestion`: checksum-verified source files, import runs with quality
  counters, atomic dataset publication with rollback, an `opengeo-ingest` gate
  that counts rejections by reason, and refusal above a 20 % rejected-record
  ratio.
- Cross-surface parity: `tests/parity/geometry_vectors.json` is validated by both
  the Python suite and the Dart suite, and geometry error codes carry the same
  wire spelling on both sides (`GeoErrorCode.wireCode`).
- HTTP validation failures carry `details.geometry_code`, and a caller-supplied
  `x-request-id` is echoed when it is id-safe.
- PostGIS schema enforcing one active dataset version per region and rejecting
  invalid or empty geometry at insert time.
- Compose development stack, API image, CI workflow, issue and pull request
  templates, `DATA_SOURCES.md`, `THIRD_PARTY_NOTICES.md`.
- OpenGeoBench baseline script recording commit, dataset version, dependency
  versions and hardware with p50/p95/p99.

### Known limitations

See `docs/known-limitations.md`. The short version: synthetic 13-feature
fixture, no PostGIS attached, no geocoder, no routing engine, no tiles, no
authentication, no map widget.

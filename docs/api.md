# HTTP contract

Shapes live in the OpenAPI document (`GET /openapi.json`); this page states the
behaviour a shape cannot: what a number means, what a failure means, and what
this deployment refuses to answer.

## Envelope

Every response is `{ data, meta, provenance, warnings }`.

- `meta.request_id` echoes `x-request-id` when the caller supplies one and is
  always present, so a log line and a client report can be matched.
- `meta.dataset_version` is the hash of the loaded extract. Two answers with
  different versions are not comparable.
- `provenance.sources` names the origin and licence of the data behind the
  answer. A source without a licence entry is a bug.
- `warnings` is empty when nothing needs qualifying. A warning is never used to
  excuse a wrong answer; those are errors.

`null` means unknown. It never means zero, and it never means "cheap stand-in".

## Errors

`{ errors: [{ code, message, hint?, field?, details? }] }` with the HTTP status
derived from `code`. `code` is stable and machine-readable; `message` is prose
and may change.

| code | status | meaning |
| --- | --- | --- |
| `invalid_input` | 422 | The request itself is wrong. Fix it before retrying. |
| `not_found` | 404 | The identifier does not exist in this dataset version. |
| `unsupported_capability` | 400 | This deployment cannot answer that, and will not approximate it. |
| `unavailable_service` | 503 | A dependency is configured but not reachable. Retry may work. |
| `stale_dataset` | 409 | The request names a dataset version that is no longer active. No route emits it yet; it is reserved. |
| `quota_exhausted` | 429 | Slow down. |
| `permission_denied` | 403 | The caller is not allowed to do that. |
| `timeout` | 504 | A dependency exceeded its deadline. |
| `cancelled` | 499 | The caller went away. |
| `malformed_provider_response` | 502 | An upstream answered something unusable. Ours to fix. |
| `internal` | 500 | A bug. |

Geometry rejections are `invalid_input` with `details.geometry_code` carrying
the finer, stable reason — `invalid_coordinate`, `invalid_ring`,
`degenerate_ring`, `self_intersecting_ring`, `hole_outside_shell`,
`empty_geometry`, `unsupported_geometry_type`, `unsupported_crs`,
`malformed_geojson`, `invalid_geometry`. The same codes ship in the Dart SDK as
`GeoErrorCode.wireCode`, and both surfaces are held to
`tests/parity/geometry_vectors.json`.

`field` names the offending JSON path (`radius`, `container.coordinates[0]`), so
a client can attach an error to an input instead of showing a banner.

## Distance

Every distance carries a unit and a method.

- `geodesic` is the ellipsoidal distance (Vincenty, haversine fallback at the
  poles). It ignores roads, one-ways and water.
- `network_travel` requires a routing engine. This deployment has none, so the
  request is refused with `unsupported_capability` instead of returning a
  straight line under a different label.
- `projected_planar` is only meaningful inside the projection it was computed
  in, and is not offered over HTTP.

## Predicates

Two predicates, not one ambiguous boolean: `contains` excludes the boundary,
`covers` includes it. `boundary_rule` selects which one the caller gets, and the
answer states the rule it used.

## Refusals

`GET /v1/capabilities` is the authority on what works. `state: "implemented"`
means a request to that path is exercised by the test suite; `"configured"` and
`"region_available"` are reserved for deployments that attach a real backend;
`"requires_optional_module"` and `"requires_external_provider"` mean the path
exists but the dependency is absent, so the call is refused;
`"unavailable"` and `"planned"` mean there is nothing to call. A capability is
never reported as implemented because a dependency might be installed later.

# OpenGeo

![OpenGeo](docs/images/hero.png)

OpenGeo is a modular, self-hostable geospatial platform: one spatial engine, multiple rendering environments, on-demand geographic data, and modular capabilities for apps, agents and games.

Coordinates are EPSG:4326, longitude first. Distances carry an explicit unit and method. Bad geometry is rejected with a stable error code — never silently repaired.

## Use cases

- Nearby POI search — what cafés are within 2 km of Shivajinagar?
- Straight-line distance — how far is Cafe Goodluck from Pune Junction?
- Point-in-region check — is this address inside the Pune municipal boundary?
- Line-region intersection — does this delivery route cross the restricted zone?
- Dataset versioning — serve the Pune extract from 14 Nov; roll back if bad.
- Boundary-in vs boundary-on — contains excludes the edge; covers includes it.
- Multi-region rollout — Pune first, then Bengaluru — one active version per region.
- Agent tool access — MCP server lets an AI agent call geo.nearby over stdio.
- Extract ingestion gate — reject an OSM extract if more than 20 % of features fail validation.
- Stable error codes — invalid_ring vs self_intersecting_ring — branch on code, not message.
- Capability manifest — tells a client what this deployment refuses.
- Latency baseline — records p50/p95/p99 with commit and hardware.
- Cross-surface parity — Python and Dart judge the same geometry vectors identically.
- PostGIS authority — serve from PostGIS with a GiST index on geography.
- Atomic publication — publish_dataset_version() flips the active version in one transaction.
- Indian metros roadmap — Pune → Bengaluru → other metros, Pune first.

Drop your header image at `docs/images/hero.png` and it renders at the top.

## License

Code: Apache-2.0. OSM-derived data stays under ODbL and remains separate from the code; attribution stays visible in every client.

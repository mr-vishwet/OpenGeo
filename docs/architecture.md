# Architecture

One geography implementation, several surfaces that never re-implement it.

```
                 MCP client (Claude, agent, IDE)
                          |
                     opengeo-mcp ---- stdio only today
                          |
Agents, Flutter, CLI ------+
       (HTTP)              |
   +-----------------------v---------------------+
   |  opengeo-api (FastAPI)                      |
   |  request id -> envelope -> error taxonomy   |
   +-----------+-----------------+----------------+
               |                 |
      validation boundary   dataset store
      (GEOS + shapely)      (GeoJSON fixture)
               |                 |
               +-------+---------+
                       |
                 ./tests, parity vectors
```

The diagram deliberately omits PostGIS, Pelias, Valhalla and tile serving: none
of them is running. `GET /v1/capabilities` is the authority on what exists.

## The one rule that keeps surfaces honest

Every input from a client, an extract, an SDK or a model plan passes the same
validation boundary and the same error-code catalogue. `tests/parity/` holds
hand-written verdicts that the Python service and the Dart SDK both validate.
Wrong geometry is never repaired, only rejected with a stable code.

## Layers

1. **Value types** — `packages/geo_types` (Dart) and `opengeo.geo` (Python). No
   database, no HTTP, no renderer. A geometry that exists has passed its checks.
2. **Operations** — geodesy, predicates and unit conversion. Network distance,
   routing and geocoding are absent, not stubbed.
3. **Application** — request → validate → answer. No business logic leaks into
   the transport adapters.
4. **Surfaces** — HTTP API and MCP server. Both call the same store and the
   same validators, so an answer cannot differ between them.
5. **Ingestion** — checksums, import runs, atomic publication with rollback.
   Nothing publishes above a 20% rejection ratio.

## What it is not (yet)

A database-backed deployment with spatial indexing, routing, geocoding, tiles,
offline packs or authenticated users. Those need Docker + PostGIS + a regional
extract and an engine evaluation first; see `docs/known-limitations.md`.

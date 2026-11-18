# ADR-0003: PostGIS is the authoritative spatial store

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

Spatial predicates must be deterministic and indexed. H3 and other hierarchical indexes are
useful for bucketing and coarse candidate selection, but they cannot answer containment,
intersection or boundary-inclusion questions.

## Decision

PostGIS is the authoritative engine for spatial queries in the first backend implementation.
`GiST` indexes are the default spatial index. Proximity search uses an indexed candidate query
(bbox or `ST_DWithin`) followed by an exact final distance evaluation. H3 is used only for
aggregation and coarse candidate selection where measurement shows a benefit, never as a
replacement for exact geometry.

Every predicate has documented boundary semantics: `contains` excludes the boundary, `covers`
includes it. `ST_Contains` and `ST_Covers` are mapped to distinct public predicates rather than
collapsed into one boolean.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| In-process GEOS only, no database | No durable dataset, no concurrent access, no indexing story |
| Elasticsearch geo queries as authority | Search-oriented, weaker predicate semantics, no single source of truth |
| H3-only spatial index | Cannot answer exact containment or intersection |

## Consequences

**Positive.** Proven predicate semantics, real indexes, and a dataset version we can publish
atomically.

**Negative.** A stateful service in every deployment. Local development needs a container.

**Follow-ups.** Compose service, migrations, connection pooling, and adversarial geometry tests
in CI on a clean database.

## Review trigger

A measured workload where PostGIS cannot meet the latency budget after proper indexing, or a
deployment target that forbids a stateful database.

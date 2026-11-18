# ADR-0001: Modular monorepo

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

The platform ships one canonical geographic model to Flutter, Android, iOS, web, Unity, Unreal,
REST and MCP consumers. Those surfaces must agree on coordinate order, units, error codes and
geometry semantics. Separate repositories would let each surface drift, and a drift in
coordinate order is a silent, dangerous bug.

## Decision

One repository holds contracts, SDKs, services, integrations, infrastructure and benchmarks.
Language-specific build systems stay independent — a Dart package is not built by the Python
toolchain, and nothing is forced into one build runner. Shared schemas live as language-neutral
artifacts (OpenAPI for HTTP, JSON Schema for tool inputs, GeoJSON/OGC structures for geometry)
and are generated from the implementation, then contract-tested.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Per-surface repositories with published packages | Contract drift, cross-repo version pinning, and no single PR can prove cross-surface parity |
| One polyglot build tool for everything | Fights each ecosystem's tooling for no benefit |

## Consequences

**Positive.** A contract change and every consumer of it land in one reviewable change. Cross-
surface parity tests are cheap. One CI can prove the whole slice.

**Negative.** CI must be path-filtered or it becomes slow. Repository size grows.

**Follow-ups.** Path-filtered workflows; a parity test that runs the same distance/nearby/
contains operation through REST and the Dart client.

## Review trigger

If CI duration exceeds ten minutes for a single-package change, or a surface needs an
independent release cadence that the monorepo cannot provide.

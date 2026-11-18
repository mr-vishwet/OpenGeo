# ADR-0008: Python + FastAPI for the first service implementation

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

PRD §11 leaves the backend language open and suggests a strongly typed language for API
orchestration. The first milestone is a regional vertical slice that must be built and tested on
a 5.9 GB Windows machine with no Docker yet. Python 3.13 is already installed; Go is not.

## Decision

The first API and ingestion implementation is Python 3.13 with FastAPI, Pydantic v2 and Uvicorn.
Types are enforced at the boundary by Pydantic models, and OpenAPI is generated from those models
so the Dart SDK consumes a contract produced by the implementation rather than a parallel
document.

The service layer is deliberately thin: geography is executed by PostGIS and, later, by provider
adapters. Nothing in the Python layer re-implements a predicate that PostGIS can answer.

Go remains a candidate for the hot path later; replacing it does not change the public contract
because the contract is OpenAPI plus behaviour, not a language binding.

## Alternatives considered

| Alternative | Why rejected now |
|---|---|
| Go | Requires an install, and geo logic would be written twice (Go services + Dart SDK) |
| Dart on the server | One language, but thin PostGIS/routing ecosystem and slower to reach a slice |
| Node/TypeScript | Not installed; weaker geospatial data tooling |

## Consequences

**Positive.** Working slice today. Ingestion tooling and services share one language and one
schema layer. Generated OpenAPI keeps the client honest.

**Negative.** Python throughput is lower than Go for CPU-bound work; GIL constrains concurrency
without care. Type safety depends on discipline at internal boundaries.

**Follow-ups.** Load test with OpenGeoBench before any capacity claim. Keep predicate execution
inside PostGIS so the language choice never becomes a correctness variable.

## Review trigger

Measured p95 latency above the agreed budget after indexing, or a CPU-bound path that dominates
total request time.

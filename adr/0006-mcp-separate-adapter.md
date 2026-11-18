# ADR-0006: MCP is a separate adapter over application services

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

AI clients need discoverable, schema-described tools. The same operations already exist as REST
endpoints. Duplicating geographic logic inside a tool server would create two sources of truth
for distance, containment and provenance.

## Decision

`src/opengeo/mcp` is a separately runnable process that calls the same application service
interfaces as REST. It contains no geographic business logic. Every tool has a narrow purpose, a
strict JSON Schema, declared units, bounds, defaults, permission requirements, example calls and
an output limit. Tool names and schemas are versioned and pinned to one MCP protocol version.

The server must be tested against at least two independent MCP clients. Model output is proposed
as a typed plan and validated server-side against schema, coordinate order, CRS, units, radius
bounds, result limits, enabled capabilities, authorization, context freshness and cost budget
before execution.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| MCP inside the REST service | Couples protocol churn to the HTTP release and blurs trust boundaries |
| Tool logic calling the database directly | Two implementations of the same geography, unbounded queries |
| Free-form SQL or query tool | Unrestricted SQL is never exposed to a model |

## Consequences

**Positive.** One geography implementation, independent scaling, and a protocol boundary that can
change without touching HTTP contracts.

**Negative.** An extra deployable, and latency between the adapter and the services.

**Follow-ups.** Conformance tests against two clients; plan validator test suite; capability
manifest exposed as an MCP resource.

**Open.** The server is exercised through the official `mcp` SDK only. Conformance against a
second independent client, and the capability-manifest resource, are not done.

## Review trigger

A protocol change that the adapter cannot absorb without altering public tool semantics.

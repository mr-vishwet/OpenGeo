# ADR-0005: Geocoding and routing behind provider adapters

- **Status:** proposed — requires a spike before acceptance
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

Pelias offers modular importers and a geocoder architecture built on geographic data plus text
search. Valhalla exposes routes, matrix, isochrones, map matching and multimodal costing. Both
are candidates, not mandates: the PRD requires a written comparison, not a default choice.

## Decision

Define `GeocodingProvider` and `RoutingProvider` contracts first, then implement adapters.
Adapters translate provider payloads into OpenGeo semantics and never leak provider parameter
names into the public contract. Unhonourable options return a warning or an
`unsupported_option` error; they are never silently dropped.

Provider-specific extras may appear only under a namespaced extension field. Each adapter ships
with a conformance suite that proves it satisfies the same public invariants as every other
adapter.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Commit to Pelias + Valhalla directly | Locks the contract to two heavy engines before measuring them |
| Build our own geocoder/routing engine | Explicitly a non-goal for the first release |
| Nominatim as the production backend | Public endpoint; rate-limited and not ours to scale |

## Consequences

**Positive.** A second provider can be onboarded by configuration plus an adapter. Provider
failure modes become explicit capability states instead of crashes.

**Negative.** Two layers to maintain, and normalized output is lossier than raw provider JSON.

**Follow-ups.** OG-009 (Pelias vs PostGIS full-text) and OG-010 (Valhalla) spike reports with
quality, operational cost and license findings. Pin engine versions only after they pass.

## Review trigger

A spike shows a materially better fit (quality, footprint or licence), or a provider cannot meet
the regional evaluation baseline.

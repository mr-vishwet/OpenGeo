# ADR-0004: Integrate MapLibre instead of building a renderer

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

Rendering 2D maps well requires years of work on text placement, collision detection, tile
decoding, GPU pipelines and platform graphics integration. OpenGeo's value is the spatial engine
and the contracts, not the rasterizer.

## Decision

MapLibre is the default 2D rendering integration, consumed through map style, source and tile
contracts. The map widget is an optional module. Map lifecycle is explicit: uninitialized,
loading style, loading sources, ready, degraded, disposed. A disposed controller cannot receive
camera updates or network callbacks.

Renderer objects never appear in the canonical domain model, and renderer-specific escape
hatches are marked platform-specific and unstable. Renderer migration is an adapter change, not
a rewrite of the spatial model.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Custom renderer in C++/Rust | Enormous cost, no differentiation, competes with mature engines |
| Platform-native maps (Google/Apple) | Provider lock-in, inconsistent contracts, licensing constraints |
| Web-only (deck.gl/CesiumJS) | Does not serve native mobile or game surfaces |

## Consequences

**Positive.** Working 2D rendering on every target from day one. Style/tile compatibility with
the wider ecosystem.

**Negative.** We inherit MapLibre's release cadence and its binding gaps, and must maintain a
compatibility matrix for MapLibre Native, the Flutter binding and OS versions.

**Follow-ups.** Compatibility spike before pinning the package; attribution controls tested in a
sample app.

## Review trigger

MapLibre stalls on a platform target, or the binding cannot support a required capability
(custom layer types, 3D terrain) within our budget.

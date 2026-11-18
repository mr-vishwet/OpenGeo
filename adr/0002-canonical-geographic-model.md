# ADR-0002: Canonical geographic model in WGS84 lon/lat with explicit CRS

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

GeoJSON defines EPSG:4326 coordinate order as longitude then latitude. Every serious mapping
bug report in the wild eventually reduces to swapped coordinates or to decimal degrees treated
as metres. Internal computation needs a projection or geodesic method, but the interchange
format must be unambiguous.

## Decision

Public interchange is EPSG:4326 with longitude-first ordering, matching GeoJSON. Every geometry
carries or inherits an explicit CRS identifier. Every value type names its unit. Decimal degrees
are never used as a distance unit. Internal calculations choose a geodesic method or an
appropriate projection per operation and area, and report which method was used.

A `Coordinate` is never a bare pair of doubles without a declared axis order. A `Distance`
carries value, unit and method (geodesic, projected planar, or network travel).

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Latitude-first internal convention | Breaks GeoJSON round-tripping and the ecosystem's default |
| Web Mercator (EPSG:3857) as interchange | Distorts distance and area; unusable as a canonical model |
| Unitless tuples | Exactly the failure mode this ADR exists to prevent |

## Consequences

**Positive.** One documented order removes the highest-frequency integration bug. Geometry
validators can reject out-of-range values and swapped pairs cheaply.

**Negative.** Every adapter boundary needs a documented order check, and 3D/game consumers need
a transform layer rather than raw coordinates.

**Follow-ups.** Coordinate-order and antimeridian tests in `packages/geo_types`; altitude
datum policy documented separately.

## Review trigger

Adoption of a future OGC standard that changes GeoJSON axis order, or a consumer platform that
cannot express longitude-first coordinates.

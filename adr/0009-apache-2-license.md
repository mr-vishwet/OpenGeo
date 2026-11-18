# ADR-0009: Apache-2.0 project license

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

PRD §44/§55 requires a license decision before redistribution, contribution files and any public
hosting claim. The platform integrates third-party engines (MapLibre, PostGIS/GEOS/PROJ,
Valhalla, Pelias) under their own licenses, and serves ODbL data that is licensed separately from
the code.

## Decision

Code is licensed under Apache-2.0. The license covers source code in this repository only.

- OSM-derived databases are **not** covered by Apache-2.0 and remain under ODbL, with attribution
  and share-alike assessed before redistribution.
- Map styles, fonts, sprites, imagery and terrain carry their own licenses and are recorded in
  `DATA_SOURCES.md` and `THIRD_PARTY_NOTICES.md`.
- A dependency whose license is incompatible with Apache-2.0 distribution cannot be added
  without a superseding ADR.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| MIT | No patent grant, silent on trademarks — weak for infrastructure other companies embed |
| AGPL-3.0 | Strong hosted-fork protection, but blocks adoption inside products that cannot accept copyleft |
| Dual license | Premature: no commercial entity or contributor agreement exists yet |

## Consequences

**Positive.** Explicit patent grant, standard for infrastructure, compatible with the ecosystem
we integrate, and clear separation between code and data licensing.

**Negative.** No copyleft protection against a closed hosted clone. Requires NOTICE hygiene and
per-dependency license review.

**Follow-ups.** `NOTICE`, `THIRD_PARTY_NOTICES.md`, `DATA_SOURCES.md`, and a CI license check.

## Review trigger

A hosted-service business model that needs copyleft protection, or a required dependency whose
license is incompatible with Apache-2.0.

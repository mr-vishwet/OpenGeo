# Data sources and attribution

Attribution is a product obligation, not a UI preference. It must be visible in
every client and removable only by breaking compliance.

## Currently bundled in this repository

| Dataset | What it is | License | Attribution |
|---|---|---|---|
| `data/fixtures/pune_places.geojson` | 13 synthetic features around Pune, authored for tests | Apache-2.0 | Synthetic test data authored for OpenGeo |

The fixture is **not** OpenStreetMap data and must never be presented as a place
database. It exists to exercise duplicate names, Devanagari names, incomplete
addresses and a containment polygon.

## Planned regional data

| Dataset | Source | License | Status |
|---|---|---|---|
| Pune, Maharashtra extract | Geofabrik | ODbL-1.0 | not imported |
| Bengaluru, Karnataka extract | Geofabrik | ODbL-1.0 | not imported |
| Other Indian metropolitan extracts | Geofabrik | ODbL-1.0 | not planned in this milestone |

Every imported extract must be recorded in `opengeo.source` with its checksum,
retrieval date, license and allowed uses before it is published.

## ODbL obligations

OpenStreetMap data is under the Open Database License. Attribution text
("© OpenStreetMap contributors") must be displayed by every client that shows
the data or a produced database.

Whether a produced database is a derivative database subject to share-alike
depends on how the data is combined and distributed. **Obtain legal review
before commercial redistribution.** This document is not legal advice.

## Assets with separate licenses

Map styles, sprites, glyphs, satellite imagery, terrain and building models are
licensed independently of both the code and the OSM database. No asset may be
bundled until its redistribution rights are verified and recorded here.

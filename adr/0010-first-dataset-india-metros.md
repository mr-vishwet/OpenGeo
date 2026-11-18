# ADR-0010: First dataset is Indian metropolitan regions, Pune primary

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

PRD §15/§46 require one representative regional extract for the first vertical slice, and §55
lists the region as an open question. Everything downstream — search evaluation sets, routing
graph, tile coverage, quality baselines — is scoped to it. A planet file is out of the question
on this hardware.

The PRD's own example coordinates are Pune (longitude 73.8567, latitude 18.5204).

## Decision

Primary region: **Pune, Maharashtra**. Expansion order: **Bengaluru, Karnataka**, then additional
Indian metropolitan regions (Mumbai, Delhi NCR, Hyderabad, Chennai) as separate, independently
versioned dataset releases.

Each region is its own dataset version with its own extract, checksum, import run and evaluation
set. A region is not "supported" because a city name appears in a list; it is supported when its
import is repeatable, its search baseline is recorded and its attribution is verifiable.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Planet extract | Size and RAM are infeasible here; no value for a vertical slice |
| A European city | Not the target market; different address and naming conventions |
| All Indian metros at once | Cannot establish import correctness on one region if five change at once |

## Consequences

**Positive.** Small enough to import and re-import repeatedly on 5.9 GB RAM. Well-mapped enough
for search and routing evaluation. Matches the specification's examples.

**Negative.** Indian address data in OSM is uneven; some evaluations will measure coverage gaps
rather than engine quality. Multilingual name handling (Devanagari, Kannada, English) becomes a
first-class requirement earlier than for a single-language region.

**Follow-ups.** Select the Geofabrik/BBBike extract, record checksum and import date, author a
labeled Pune evaluation set, and test one non-Latin script through the search pipeline.

## Review trigger

Pune import cannot be made repeatable, or the evaluation baseline cannot reach the agreed
quality floor after adapter tuning.

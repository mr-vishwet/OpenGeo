# ADR-0007: Map assets and regional datasets stay outside the SDK binary

- **Status:** accepted
- **Date:** 2026-11-19
- **Owner:** maintainer

## Context

A mobile app that only needs a map should not ship a routing graph, a search index and a global
place dataset. Data is also licensed separately from code, and ODbL obligations differ between
code distribution and database distribution.

## Decision

Executable code ships through approved app distribution channels. Geographic data — tiles,
terrain, search indexes, routing graph subsets — is delivered separately at runtime from a
versioned, checksummed manifest. The SDK declares which regional assets are required and reports
their download size; it does not bundle them.

Build-time modularity removes unused code and native dependencies. Runtime data delivery streams
tiles, terrain and regional indexes independently. Both dimensions are measured separately:
compressed download size, installed size, native binary size per ABI, and data storage.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Bundle a baseline dataset for offline-out-of-the-box | Unbounded binary size, per-region licence complexity, stale data on install |
| Download executable modules after install | Prohibited or restricted by mobile app store policy |

## Consequences

**Positive.** Small default install, per-region licensing, dataset updates without an app release.

**Negative.** First-run experience requires network or a separately downloaded pack; offline
capability must be discovered rather than assumed.

**Follow-ups.** Offline manifest with region geometry, zoom range, layers, dataset versions,
bytes and chunk hashes; atomic activation so a partial pack never activates.

## Review trigger

A target platform permits executable module delivery and a measured user need justifies it.

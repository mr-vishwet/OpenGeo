# Security Policy

## Reporting

Do not open a public issue for a vulnerability. Report privately to the maintainer listed in
`MAINTAINERS.md`, or through GitHub's private vulnerability reporting on this repository.
Include the affected surface, reproduction steps and impact. You will receive an
acknowledgement within 5 working days.

## Scope

Surfaces in scope: the HTTP API, the MCP adapter, ingestion and tile endpoints, offline pack
manifests, SDK local storage, and any game-server spatial authority path.

## Known trust boundaries

1. Client → gateway.
2. Gateway → application services.
3. MCP host → tools.
4. Ingestion source → publication.
5. Game client → authoritative server.

## Baseline controls

TLS; scoped tokens; authorization on every protected operation; request-size and
geometry-complexity limits; deadlines and cancellation; strict schema validation; rate limits;
safe archive extraction; content hashing on downloaded packs; redacted logs; no database
credentials or unrestricted SQL exposed to clients or models.

## Never in scope for a fix

Removing attribution to make an integration easier, or trusting client-reported location for
security-sensitive gameplay decisions.

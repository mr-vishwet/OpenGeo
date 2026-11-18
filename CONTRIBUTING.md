# Contributing to OpenGeo

Read the architecture decision records in `adr/` before changing a public contract. If your
change alters coordinate semantics, units, error codes, geometry behaviour or provider
behaviour, it is a breaking change and needs an ADR plus a migration note.

## Local setup

```bash
dart pub get                     # Dart packages
dart test

python -m venv .venv
.venv/Scripts/activate           # Windows
pip install -r requirements-dev.txt
pytest

docker compose -f infrastructure/compose.dev.yml up -d   # when the stack is enabled
```

## Definition of done

A change is done when it has tests, documentation and a defined failure mode. A compiling stub
is not done, and a benchmark claim without a reproducible command is not evidence.

- Unit tests for validation, transforms, units and error mapping.
- Integration test when the change touches a database, an engine or the network.
- Contract test when the change touches OpenAPI, JSON Schema or an SDK surface.
- `CHANGELOG.md` entry for anything a consumer can observe.

## Commit and PR rules

- One milestone or one concern per pull request.
- Every dependency addition states its license, maintenance health and why the standard library
  or an existing dependency was insufficient.
- Never commit secrets, credentials, precise location data or untested generated code.
- AI-assisted changes are allowed and must be understood, tested and reviewed by the author.

## Data rules

OSM-derived data is under ODbL. Do not commit extracts, derived databases or tiles. Attribution
must stay visible in every client. Do not invent absent geographic facts — no guessed house
numbers, opening hours, categories or accessibility claims.

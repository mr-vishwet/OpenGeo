"""`opengeo-api` entry point."""

from __future__ import annotations


def main() -> None:
    import uvicorn

    uvicorn.run("opengeo.api.app:app", host="127.0.0.1", port=8080, reload=False)


if __name__ == "__main__":
    main()

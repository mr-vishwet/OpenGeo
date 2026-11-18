"""MCP tool catalogue.

Only capabilities this build can actually serve are published. A tool name in a
generic document is not a promise, so `routing`, `isochrone`, `map_match` and
`context` are deliberately absent until an engine exists.

Every entry carries the parts the PRD requires: a narrow purpose, a strict JSON
Schema, declared units, bounds, defaults, permissions, limits and examples.
"""

from __future__ import annotations

from typing import Any

from ..api.models import MAX_LIMIT, MAX_RADIUS_M

TOOL_SCHEMA_VERSION = "1.0.0"

MAX_STEPS = 5


def _position() -> dict[str, Any]:
    return {
        "type": "object",
        "description": "A position. Order is named, so it cannot be swapped.",
        "properties": {
            "longitude": {
                "type": "number",
                "minimum": -180,
                "maximum": 180,
                "description": "Degrees east, EPSG:4326.",
            },
            "latitude": {
                "type": "number",
                "minimum": -90,
                "maximum": 90,
                "description": "Degrees north, EPSG:4326.",
            },
        },
        "required": ["longitude", "latitude"],
        "additionalProperties": False,
    }


def _geometry() -> dict[str, Any]:
    return {
        "type": "object",
        "description": "A GeoJSON geometry, EPSG:4326, longitude first.",
        "properties": {
            "type": {
                "enum": [
                    "Point",
                    "LineString",
                    "Polygon",
                    "MultiPoint",
                    "MultiLineString",
                    "MultiPolygon",
                    "GeometryCollection",
                ]
            },
            "coordinates": {"type": "array"},
            "geometries": {"type": "array"},
        },
        "required": ["type"],
        "additionalProperties": False,
    }


def _radius() -> dict[str, Any]:
    return {
        "type": "object",
        "properties": {
            "value": {
                "type": "number",
                "exclusiveMinimum": 0,
                "maximum": MAX_RADIUS_M,
                "description": f"Maximum {MAX_RADIUS_M} metres.",
            },
            "unit": {"enum": ["m", "km", "mi", "nmi"], "default": "m"},
        },
        "required": ["value"],
        "additionalProperties": False,
    }


def _catalog() -> list[dict[str, Any]]:
    return [
        {
            "name": "geo.nearby",
            "description": (
                "Find points of interest within a radius of a position. Returns places "
                "ordered by distance in metres. Use when the user asks what is near a "
                "location. It cannot answer road distance or travel time."
            ),
            "inputSchema": {
                "type": "object",
                "properties": {
                    "center": _position(),
                    "radius": _radius(),
                    "categories": {
                        "type": "array",
                        "items": {"type": "string"},
                        "maxItems": 10,
                    },
                    "limit": {
                        "type": "integer",
                        "minimum": 1,
                        "maximum": MAX_LIMIT,
                        "default": 20,
                    },
                },
                "required": ["center", "radius"],
                "additionalProperties": False,
            },
            "annotations": {
                "units": ["metres", "kilometres", "miles", "nautical_miles"],
                "permissions": ["places:read"],
                "errorCodes": ["invalid_input", "quota_exhausted", "unavailable_service"],
                "returns": "places with distance_m",
            },
            "examples": [
                {
                    "arguments": {
                        "center": {"longitude": 73.8567, "latitude": 18.5204},
                        "radius": {"value": 1200, "unit": "m"},
                        "categories": ["pharmacy"],
                        "limit": 10,
                    }
                }
            ],
        },
        {
            "name": "geo.distance",
            "description": (
                "Straight-line distance between two positions, in the requested unit. "
                "This is not travel distance. If the user asks how long it takes to get "
                "somewhere, distance is the wrong tool."
            ),
            "inputSchema": {
                "type": "object",
                "properties": {
                    "origin": _position(),
                    "destination": _position(),
                    "unit": {"enum": ["m", "km", "mi", "nmi"], "default": "m"},
                },
                "required": ["origin", "destination"],
                "additionalProperties": False,
            },
            "annotations": {
                "units": ["metres", "kilometres", "miles", "nautical_miles"],
                "permissions": [],
                "errorCodes": ["invalid_input", "unsupported_capability"],
                "returns": "value, unit, method",
            },
            "examples": [
                {
                    "arguments": {
                        "origin": {"longitude": 73.8567, "latitude": 18.5204},
                        "destination": {"longitude": 72.8777, "latitude": 19.076},
                        "unit": "km",
                    }
                }
            ],
        },
        {
            "name": "geo.contains",
            "description": (
                "Whether a geometry or position lies inside a container geometry. "
                "boundary_rule='contains' excludes the boundary, 'covers' includes it. "
                "Never guess this answer; call the tool."
            ),
            "inputSchema": {
                "type": "object",
                "properties": {
                    "container": _geometry(),
                    "candidate": _geometry(),
                    "boundary_rule": {"enum": ["contains", "covers"], "default": "covers"},
                },
                "required": ["container", "candidate"],
                "additionalProperties": False,
            },
            "annotations": {
                "units": [],
                "permissions": ["spatial:read"],
                "errorCodes": ["invalid_input", "unavailable_service"],
                "returns": "boolean result with the rule used",
            },
            "examples": [
                {
                    "arguments": {
                        "container": {
                            "type": "Polygon",
                            "coordinates": [
                                [
                                    [73.83, 18.5],
                                    [73.9, 18.5],
                                    [73.9, 18.55],
                                    [73.83, 18.55],
                                    [73.83, 18.5],
                                ]
                            ],
                        },
                        "candidate": {"type": "Point", "coordinates": [73.855, 18.525]},
                        "boundary_rule": "covers",
                    }
                }
            ],
        },
        {
            "name": "geo.intersects",
            "description": "Whether two geometries share any point.",
            "inputSchema": {
                "type": "object",
                "properties": {"a": _geometry(), "b": _geometry()},
                "required": ["a", "b"],
                "additionalProperties": False,
            },
            "annotations": {
                "units": [],
                "permissions": ["spatial:read"],
                "errorCodes": ["invalid_input", "unavailable_service"],
                "returns": "boolean",
            },
            "examples": [
                {
                    "arguments": {
                        "a": {"type": "Point", "coordinates": [73.855, 18.525]},
                        "b": {
                            "type": "LineString",
                            "coordinates": [[73.8, 18.5], [73.9, 18.6]],
                        },
                    }
                }
            ],
        },
    ]


TOOLS: list[dict[str, Any]] = _catalog()

TOOLS_BY_NAME: dict[str, dict[str, Any]] = {tool["name"]: tool for tool in TOOLS}


def tool_names() -> list[str]:
    return [tool["name"] for tool in TOOLS]

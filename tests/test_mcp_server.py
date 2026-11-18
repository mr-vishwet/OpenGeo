import asyncio
from typing import Any

import pytest

pytest.importorskip("mcp", reason="MCP SDK is an optional extra")

from mcp.server.mcpserver.exceptions import ToolError  # noqa: E402

from opengeo.mcp import TOOLS_BY_NAME  # noqa: E402
from opengeo.mcp.server import build_server  # noqa: E402

PUNE = {"longitude": 73.8794, "latitude": 18.5158}


def call(name: str, arguments: dict[str, Any]) -> dict[str, Any]:
    async def run() -> dict[str, Any]:
        server = build_server()
        result = await server.call_tool(name, arguments)
        structured = result.structured_content
        assert structured is not None
        return structured

    return asyncio.run(run())


def test_server_publishes_exactly_the_catalogued_tools():
    async def run() -> list[str]:
        server = build_server()
        return sorted(tool.name for tool in await server.list_tools())

    assert asyncio.run(run()) == sorted(TOOLS_BY_NAME)


def test_generated_schemas_do_not_drift_from_the_catalogue():
    async def run() -> list[tuple[str, dict, dict]]:
        server = build_server()
        return [
            (tool.name, tool.input_schema, TOOLS_BY_NAME[tool.name]["inputSchema"])
            for tool in await server.list_tools()
        ]

    for name, generated, catalogued in asyncio.run(run()):
        assert set(generated["properties"]) == set(catalogued["properties"]), name


def test_nearby_returns_places_with_distance_and_dataset_version():
    result = call(
        "geo.nearby",
        {"center": PUNE, "radius": {"value": 2, "unit": "km"}, "categories": ["cafe"]},
    )
    places = result["places"]
    assert places
    assert all("distance_m" in place for place in places)
    assert [p["distance_m"] for p in places] == sorted(p["distance_m"] for p in places)
    assert result["dataset_version"].startswith("fixture-")


def test_nearby_does_not_invent_an_address_field():
    result = call(
        "geo.nearby",
        {"center": PUNE, "radius": {"value": 3, "unit": "km"}, "limit": 20},
    )
    for place in result["places"]:
        assert isinstance(place["address"], dict)
        assert "house_number" not in place["address"] or isinstance(
            place["address"]["house_number"], str
        )


def test_nearby_refuses_a_radius_over_the_ceiling():
    with pytest.raises(ToolError) as exc:
        call("geo.nearby", {"center": PUNE, "radius": {"value": 500, "unit": "km"}})
    assert "invalid_input" in str(exc.value)


def test_distance_is_geodesic_and_converted():
    result = call(
        "geo.distance",
        {
            "origin": {"longitude": 73.8567, "latitude": 18.5204},
            "destination": {"longitude": 72.8777, "latitude": 19.076},
            "unit": "km",
        },
    )
    assert result["method"] == "geodesic"
    assert result["unit"] == "km"
    assert 115 < result["value"] < 125


def test_contains_boundary_rule_is_honoured():
    square = {
        "type": "Polygon",
        "coordinates": [
            [
                [73.85, 18.52],
                [73.86, 18.52],
                [73.86, 18.53],
                [73.85, 18.53],
                [73.85, 18.52],
            ]
        ],
    }
    corner = {"type": "Point", "coordinates": [73.85, 18.52]}
    excluded = call(
        "geo.contains", {"container": square, "candidate": corner, "boundary_rule": "contains"}
    )
    included = call(
        "geo.contains", {"container": square, "candidate": corner, "boundary_rule": "covers"}
    )
    assert excluded["result"] is False
    assert included["result"] is True


def test_contains_rejects_an_open_ring():
    broken = {
        "type": "Polygon",
        "coordinates": [
            [[73.85, 18.52], [73.86, 18.52], [73.86, 18.53], [73.85, 18.53]]
        ],
    }
    with pytest.raises(ToolError) as exc:
        call(
            "geo.contains",
            {
                "container": broken,
                "candidate": {"type": "Point", "coordinates": [73.855, 18.525]},
            },
        )
    assert "invalid_ring" in str(exc.value)


def test_intersects_returns_a_boolean():
    result = call(
        "geo.intersects",
        {
            "a": {"type": "Point", "coordinates": [73.855, 18.525]},
            "b": {"type": "LineString", "coordinates": [[73.8, 18.5], [73.9, 18.6]]},
        },
    )
    assert result["result"] in (True, False)

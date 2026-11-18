import pytest
from jsonschema import Draft202012Validator

from opengeo.mcp import (
    TOOLS,
    TOOLS_BY_NAME,
    PlanError,
    PlanErrorCode,
    validate_plan,
)

LOCATION = frozenset({"authorized-user-location"})


def test_every_tool_schema_is_a_valid_json_schema():
    for tool in TOOLS:
        Draft202012Validator.check_schema(tool["inputSchema"])


def test_every_tool_declares_the_required_metadata():
    for tool in TOOLS:
        assert tool["description"]
        assert tool["inputSchema"]["additionalProperties"] is False
        assert "annotations" in tool
        assert tool["annotations"]["errorCodes"]
        assert tool["examples"]


def test_unimplemented_operations_are_not_published():
    names = set(TOOLS_BY_NAME)
    assert "geo.nearby" in names
    assert "geo.distance" in names
    assert "geo.contains" in names
    for absent in ("geo.directions", "geo.isochrone", "geo.map_match", "geo.geocode"):
        assert absent not in names


def test_radius_has_a_documented_ceiling():
    limit = TOOLS_BY_NAME["geo.nearby"]["inputSchema"]["properties"]["radius"]["properties"][
        "value"
    ]["maximum"]
    assert limit == 50_000


def test_a_context_resolved_step_says_bounds_are_checked_at_execution():
    plan = validate_plan(
        {
            "operation": "nearby",
            "center": {"context_ref": "authorized-user-location"},
            "radius": {"value": 1200, "unit": "m"},
        },
        granted_context=LOCATION,
    )
    assert plan.warnings
    assert "execution time" in plan.warnings[0]


def test_accepts_a_valid_single_step_plan():
    plan = validate_plan(
        {
            "operation": "nearby",
            "center": {"context_ref": "authorized-user-location"},
            "radius": {"value": 1200, "unit": "m"},
            "categories": ["pharmacy"],
            "limit": 10,
        },
        granted_context=LOCATION,
    )
    assert len(plan.steps) == 1
    assert plan.steps[0].operation == "geo.nearby"
    assert plan.steps[0].context_refs == ("authorized-user-location",)


def test_accepts_a_multi_step_plan_with_an_explanation():
    plan = validate_plan(
        {
            "explanation": "Find pharmacies near the user, then measure the closest one.",
            "steps": [
                {
                    "operation": "geo.nearby",
                    "center": {"context_ref": "authorized-user-location"},
                    "radius": {"value": 1500},
                },
                {
                    "operation": "geo.distance",
                    "origin": {"longitude": 73.8567, "latitude": 18.5204},
                    "destination": {"longitude": 73.88, "latitude": 18.51},
                    "unit": "km",
                },
            ],
        },
        granted_context=LOCATION,
    )
    assert [step.operation for step in plan.steps] == ["geo.nearby", "geo.distance"]
    assert plan.explanation is not None


def test_rejects_an_unknown_operation_and_lists_the_real_ones():
    with pytest.raises(PlanError) as exc:
        validate_plan({"operation": "route", "origin": {}, "destination": {}})
    assert exc.value.code is PlanErrorCode.UNSUPPORTED_OPERATION
    assert "geo.nearby" in exc.value.message


def test_rejects_an_ungranted_location_reference():
    with pytest.raises(PlanError) as exc:
        validate_plan(
            {
                "operation": "nearby",
                "center": {"context_ref": "authorized-user-location"},
                "radius": {"value": 500},
            }
        )
    assert exc.value.code is PlanErrorCode.PERMISSION_DENIED


def test_rejects_an_unknown_context_reference():
    with pytest.raises(PlanError) as exc:
        validate_plan(
            {
                "operation": "nearby",
                "center": {"context_ref": "hidden-admin-layer"},
                "radius": {"value": 500},
            },
            granted_context=frozenset({"hidden-admin-layer"}),
        )
    assert exc.value.code is PlanErrorCode.PERMISSION_DENIED


def test_rejects_a_radius_over_the_ceiling():
    with pytest.raises(PlanError) as exc:
        validate_plan(
            {
                "operation": "nearby",
                "center": {"longitude": 73.8567, "latitude": 18.5204},
                "radius": {"value": 500_000},
            }
        )
    assert exc.value.code is PlanErrorCode.OUT_OF_BOUNDS


def test_rejects_a_swapped_coordinate():
    with pytest.raises(PlanError) as exc:
        validate_plan(
            {
                "operation": "nearby",
                "center": {"longitude": 73.8567, "latitude": 118.5204},
                "radius": {"value": 500},
            }
        )
    assert exc.value.code is PlanErrorCode.OUT_OF_BOUNDS


def test_rejects_an_unknown_argument():
    with pytest.raises(PlanError) as exc:
        validate_plan(
            {
                "operation": "distance",
                "origin": {"longitude": 0, "latitude": 0},
                "destination": {"longitude": 1, "latitude": 1},
                "mode": "driving",
            }
        )
    assert exc.value.code is PlanErrorCode.INVALID_PLAN


def test_rejects_a_plan_over_the_step_budget():
    step = {
        "operation": "distance",
        "origin": {"longitude": 0, "latitude": 0},
        "destination": {"longitude": 1, "latitude": 1},
    }
    with pytest.raises(PlanError) as exc:
        validate_plan({"steps": [step] * 6})
    assert exc.value.code is PlanErrorCode.COST_BUDGET_EXCEEDED


def test_rejects_an_empty_plan():
    with pytest.raises(PlanError) as exc:
        validate_plan({"steps": []})
    assert exc.value.code is PlanErrorCode.INVALID_PLAN


def test_rejects_a_step_without_an_operation():
    with pytest.raises(PlanError) as exc:
        validate_plan({"radius": {"value": 100}})
    assert exc.value.code is PlanErrorCode.INVALID_PLAN

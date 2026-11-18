"""MCP adapter surface: tool catalogue and plan validation.

No transport here. The adapter process is a separate deployment; this package
holds the parts that must be identical to the REST service's semantics.
"""

from .plan import (
    CONTEXT_REFS,
    PlanError,
    PlanErrorCode,
    PlanStep,
    ValidatedPlan,
    validate_plan,
)
from .tools import TOOL_SCHEMA_VERSION, TOOLS, TOOLS_BY_NAME, tool_names

__all__ = [
    "CONTEXT_REFS",
    "PlanError",
    "PlanErrorCode",
    "PlanStep",
    "TOOLS",
    "TOOLS_BY_NAME",
    "TOOL_SCHEMA_VERSION",
    "ValidatedPlan",
    "tool_names",
    "validate_plan",
]

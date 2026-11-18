"""Server-side validation of a model-proposed plan.

A plan is never executed because it parses. It is executed because it passed
this module: known operation, strict schema, permissioned context reference,
bounded radius, bounded result count and a step budget.
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any

from jsonschema import Draft202012Validator

from .tools import MAX_STEPS, TOOLS_BY_NAME, tool_names

CONTEXT_REFS = {"authorized-user-location"}
_BOUND_CODES = {"maximum", "minimum", "exclusiveMaximum", "exclusiveMinimum", "maxItems"}
_PLACEHOLDER = {"longitude": 0.0, "latitude": 0.0}


class PlanErrorCode(StrEnum):
    INVALID_PLAN = "invalid_plan"
    UNSUPPORTED_OPERATION = "unsupported_operation"
    PERMISSION_DENIED = "permission_denied"
    OUT_OF_BOUNDS = "out_of_bounds"
    COST_BUDGET_EXCEEDED = "cost_budget_exceeded"


class PlanError(ValueError):
    def __init__(self, code: PlanErrorCode, message: str, *, step: int | None = None):
        self.code = code
        self.message = message
        self.step = step
        suffix = f" (step {step})" if step is not None else ""
        super().__init__(f"{code.value}: {message}{suffix}")


@dataclass(frozen=True)
class PlanStep:
    operation: str
    arguments: Mapping[str, Any]
    context_refs: tuple[str, ...] = ()


@dataclass(frozen=True)
class ValidatedPlan:
    steps: tuple[PlanStep, ...]
    explanation: str | None = None
    warnings: tuple[str, ...] = field(default=())


def _normalize_operation(raw: str) -> str:
    name = raw if raw.startswith("geo.") else f"geo.{raw}"
    if name not in TOOLS_BY_NAME:
        raise PlanError(
            PlanErrorCode.UNSUPPORTED_OPERATION,
            f"'{raw}' is not an available operation; available: {', '.join(tool_names())}",
        )
    return name


def _substitute_context_refs(value: Any, found: list[str]) -> Any:
    if isinstance(value, Mapping):
        if set(value) == {"context_ref"}:
            ref = value["context_ref"]
            if not isinstance(ref, str):
                raise PlanError(PlanErrorCode.INVALID_PLAN, "context_ref must be a string")
            if ref not in CONTEXT_REFS:
                raise PlanError(
                    PlanErrorCode.PERMISSION_DENIED,
                    f"unknown context reference '{ref}'; the server resolves only "
                    f"{sorted(CONTEXT_REFS)}",
                )
            found.append(ref)
            return dict(_PLACEHOLDER)
        return {key: _substitute_context_refs(item, found) for key, item in value.items()}
    if isinstance(value, list):
        return [_substitute_context_refs(item, found) for item in value]
    return value


def _check_context(plan_step: int, refs: Iterable[str], granted: frozenset[str]) -> None:
    for ref in refs:
        if ref not in granted:
            raise PlanError(
                PlanErrorCode.PERMISSION_DENIED,
                f"context reference '{ref}' is not authorised for this caller",
                step=plan_step,
            )


def _validate_step(index: int, raw: Mapping[str, Any], granted: frozenset[str]) -> PlanStep:
    operation_raw = raw.get("operation")
    if not isinstance(operation_raw, str) or not operation_raw:
        raise PlanError(PlanErrorCode.INVALID_PLAN, "step needs an 'operation'", step=index)
    operation = _normalize_operation(operation_raw)
    tool = TOOLS_BY_NAME[operation]

    arguments = raw.get("arguments")
    if arguments is None:
        arguments = {
            key: value
            for key, value in raw.items()
            if key not in {"operation", "arguments", "explanation"}
        }
    if not isinstance(arguments, Mapping):
        raise PlanError(PlanErrorCode.INVALID_PLAN, "arguments must be an object", step=index)

    context_refs: list[str] = []
    prepared = _substitute_context_refs(dict(arguments), context_refs)
    _check_context(index, context_refs, granted)

    validator = Draft202012Validator(tool["inputSchema"])
    for error in validator.iter_errors(prepared):
        code = (
            PlanErrorCode.OUT_OF_BOUNDS
            if error.validator in _BOUND_CODES
            else PlanErrorCode.INVALID_PLAN
        )
        location = ".".join(str(part) for part in error.absolute_path)
        raise PlanError(
            code,
            f"{error.message}" + (f" at {location}" if location else ""),
            step=index,
        )

    return PlanStep(
        operation=operation, arguments=dict(arguments), context_refs=tuple(context_refs)
    )


def validate_plan(
    candidate: Mapping[str, Any],
    *,
    granted_context: frozenset[str] = frozenset(),
    budget: int = MAX_STEPS,
) -> ValidatedPlan:
    """Validate a single-step or multi-step plan.

    Accepts `{"operation": ...}` for one step, or `{"steps": [...]}`.
    `granted_context` is the set of context references the caller is authorised
    to use; a plan referencing anything else is rejected.
    """
    if not isinstance(candidate, Mapping):
        raise PlanError(PlanErrorCode.INVALID_PLAN, "plan must be an object")

    threshold = candidate.get("steps") if "steps" in candidate else [candidate]
    if not isinstance(threshold, list) or not threshold:
        raise PlanError(PlanErrorCode.INVALID_PLAN, "plan needs at least one step")
    if len(threshold) > budget:
        raise PlanError(
            PlanErrorCode.COST_BUDGET_EXCEEDED,
            f"plan has {len(threshold)} steps; the budget is {budget}",
        )

    steps: list[PlanStep] = []
    warnings: list[str] = []
    for index, raw in enumerate(threshold):
        if not isinstance(raw, Mapping):
            raise PlanError(PlanErrorCode.INVALID_PLAN, "each step must be an object", step=index)
        step = _validate_step(index, raw, granted_context)
        if step.operation == "geo.distance" and step.context_refs:
            warnings.append(
                "distance with a context reference needs an authorised position at execution time"
            )
        steps.append(step)

    explanation = candidate.get("explanation")
    if explanation is not None and not isinstance(explanation, str):
        raise PlanError(PlanErrorCode.INVALID_PLAN, "explanation must be a string")

    return ValidatedPlan(steps=tuple(steps), explanation=explanation, warnings=tuple(warnings))

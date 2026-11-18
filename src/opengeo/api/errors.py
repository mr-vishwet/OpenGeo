"""Stable API error catalogue.

Codes are part of the public contract. A caller decides whether to retry, ask
the user, or switch provider from the code alone. Messages are for humans and
may change; codes may not change without a major version.
"""

from __future__ import annotations

from enum import StrEnum

from fastapi import status


class ErrorCode(StrEnum):
    INVALID_INPUT = "invalid_input"
    UNSUPPORTED_CAPABILITY = "unsupported_capability"
    UNAVAILABLE_SERVICE = "unavailable_service"
    PERMISSION_DENIED = "permission_denied"
    QUOTA_EXHAUSTED = "quota_exhausted"
    TIMEOUT = "timeout"
    CANCELLED = "cancelled"
    NOT_FOUND = "not_found"
    MALFORMED_PROVIDER_RESPONSE = "malformed_provider_response"
    STALE_DATASET = "stale_dataset"
    INTERNAL = "internal"


HTTP_STATUS: dict[ErrorCode, int] = {
    ErrorCode.INVALID_INPUT: status.HTTP_422_UNPROCESSABLE_ENTITY,
    ErrorCode.UNSUPPORTED_CAPABILITY: status.HTTP_400_BAD_REQUEST,
    ErrorCode.UNAVAILABLE_SERVICE: status.HTTP_503_SERVICE_UNAVAILABLE,
    ErrorCode.PERMISSION_DENIED: status.HTTP_403_FORBIDDEN,
    ErrorCode.QUOTA_EXHAUSTED: status.HTTP_429_TOO_MANY_REQUESTS,
    ErrorCode.TIMEOUT: status.HTTP_504_GATEWAY_TIMEOUT,
    ErrorCode.CANCELLED: 499,
    ErrorCode.NOT_FOUND: status.HTTP_404_NOT_FOUND,
    ErrorCode.MALFORMED_PROVIDER_RESPONSE: status.HTTP_502_BAD_GATEWAY,
    ErrorCode.STALE_DATASET: status.HTTP_409_CONFLICT,
    ErrorCode.INTERNAL: status.HTTP_500_INTERNAL_SERVER_ERROR,
}


class ApiError(Exception):
    """Raised anywhere in the service; rendered as the documented envelope."""

    def __init__(
        self,
        code: ErrorCode,
        message: str,
        *,
        hint: str | None = None,
        field: str | None = None,
    ):
        self.code = code
        self.message = message
        self.hint = hint
        self.field = field
        super().__init__(message)

    @property
    def http_status(self) -> int:
        return HTTP_STATUS[self.code]

    def as_body(self) -> dict:
        error: dict[str, object] = {"code": self.code.value, "message": self.message}
        if self.hint:
            error["hint"] = self.hint
        if self.field:
            error["field"] = self.field
        return error

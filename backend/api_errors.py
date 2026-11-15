"""
Errors the app shows to the user carry a stable `code` next to the human-readable `detail`:

    {"detail": "邮箱格式不正确", "code": "email_invalid"}

The app translates the code and falls back to `detail` for codes it doesn't know, so
`detail` stays exactly as before (older app builds display it as is). Codes are part of
the API contract: add new ones freely, never rename or reuse one. List in ONBOARDING.md §6.
"""

from typing import Optional

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse


class ApiError(HTTPException):
    def __init__(self, status_code: int, code: str, detail: str,
                 headers: Optional[dict[str, str]] = None):
        super().__init__(status_code, detail, headers)
        self.code = code


async def _handle(_: Request, exc: ApiError) -> JSONResponse:
    return JSONResponse({"detail": exc.detail, "code": exc.code},
                        status_code=exc.status_code, headers=exc.headers)


def install(app: FastAPI) -> None:
    # Starlette picks the most specific handler by class, so this wins over the
    # default HTTPException handler for ApiError only.
    app.add_exception_handler(ApiError, _handle)

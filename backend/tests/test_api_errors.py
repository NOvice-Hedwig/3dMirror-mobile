"""ApiError adds a stable `code` next to `detail`; other errors keep FastAPI's shape."""

from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

import api_errors
from api_errors import ApiError


def make_app() -> FastAPI:
    app = FastAPI()
    api_errors.install(app)

    @app.get("/coded")
    def coded():
        raise ApiError(429, "rate_limited", "请求过于频繁，请稍后再试", headers={"Retry-After": "30"})

    @app.get("/plain")
    def plain():
        raise HTTPException(404, "not here")

    @app.get("/validated")
    def validated(n: int):
        return n

    return app


client = TestClient(make_app())


def test_api_error_carries_code_detail_status_and_headers():
    r = client.get("/coded")
    assert r.status_code == 429
    assert r.json() == {"detail": "请求过于频繁，请稍后再试", "code": "rate_limited"}
    assert r.headers["Retry-After"] == "30"


def test_plain_http_exception_is_unchanged():
    r = client.get("/plain")
    assert r.status_code == 404
    assert r.json() == {"detail": "not here"}


def test_request_validation_errors_are_unchanged():
    r = client.get("/validated", params={"n": "x"})
    assert r.status_code == 422
    assert isinstance(r.json()["detail"], list)
    assert "code" not in r.json()


def test_main_app_installs_the_handler():
    import main
    assert ApiError in main.app.exception_handlers

"""Tests for /weather. The external Open-Meteo API is always mocked: tests must not need a network."""
import main
import requests


class FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def json(self):
        return self._payload


def _mock_weather(monkeypatch, code, temp=21.7, humidity=40):
    payload = {"current": {"temperature_2m": temp, "relative_humidity_2m": humidity, "weather_code": code}}
    monkeypatch.setattr(main.requests, "get", lambda *a, **k: FakeResponse(payload))


def test_clear_sky_is_rated_excellent(client, monkeypatch):
    _mock_weather(monkeypatch, code=0)
    body = client.get("/weather", params={"lat": 49.87, "lon": 8.65}).json()
    assert body["condition"] == "Clear"
    assert body["rating"] == "Excellent"
    assert body["temperature"] == 21  # truncated to int
    assert body["humidity"] == 40


def test_thunderstorm_is_rated_poor(client, monkeypatch):
    _mock_weather(monkeypatch, code=95)
    assert client.get("/weather", params={"lat": 1, "lon": 1}).json()["rating"] == "Poor"


def test_unmapped_weather_code_falls_back_to_unknown_condition(client, monkeypatch):
    _mock_weather(monkeypatch, code=999)
    body = client.get("/weather", params={"lat": 1, "lon": 1}).json()
    assert body["condition"] == "Unknown"


def test_upstream_failure_returns_graceful_fallback_not_an_error(client, monkeypatch):
    def boom(*args, **kwargs):
        raise requests.exceptions.ConnectionError("network down")

    monkeypatch.setattr(main.requests, "get", boom)
    r = client.get("/weather", params={"lat": 49.87, "lon": 8.65})
    assert r.status_code == 200
    assert r.json()["rating"] == "Unknown"


def test_missing_coordinates_is_validation_error(client):
    assert client.get("/weather", params={"lat": 49.87}).status_code == 422
    assert client.get("/weather").status_code == 422

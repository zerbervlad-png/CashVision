import pytest
from fastapi.testclient import TestClient

from api.main import app


@pytest.fixture
def client():
    return TestClient(app)


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"


def test_feature_flags(client):
    resp = client.get("/api/v1/feature-flags")
    assert resp.status_code == 200
    body = resp.json()
    assert "counting_enabled" in body
    assert "max_free_scans_per_day" in body


def test_list_banknotes(client):
    resp = client.get("/api/v1/banknotes")
    assert resp.status_code == 200
    body = resp.json()
    assert isinstance(body, list)
    assert len(body) >= 5
    currencies = {b["currency"] for b in body}
    assert "RUB" in currencies


def test_get_banknote_by_denomination(client):
    resp = client.get("/api/v1/banknotes/RUB-5000")
    assert resp.status_code == 200
    body = resp.json()
    assert body["denomination_value"] == 5000
    assert body["currency"] == "RUB"


def test_get_unknown_banknote(client):
    resp = client.get("/api/v1/banknotes/RUB-7777")
    assert resp.status_code == 404


def test_model_version(client):
    resp = client.get("/api/v1/model/version")
    assert resp.status_code == 200
    body = resp.json()
    assert body["name"] == "CashVisionBanknoteClassifier"


def test_serial_verification_no_official_source(client):
    resp = client.post("/api/v1/verification/serial", json={"serial": "аб1234567"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "no_official_source"
    assert "Банка России" in body["source"]


def test_serial_validation_rejects_empty(client):
    resp = client.post("/api/v1/verification/serial", json={"serial": ""})
    assert resp.status_code == 422


def test_serial_validation_rejects_too_long(client):
    resp = client.post("/api/v1/verification/serial", json={"serial": "a" * 33})
    assert resp.status_code == 422


def test_serial_validation_rejects_injection(client):
    for malicious in ["<script>", "'; DROP TABLE--", "ab\t1234", "ab\n1234"]:
        resp = client.post("/api/v1/verification/serial", json={"serial": malicious})
        assert resp.status_code == 422, f"Expected 422 for {malicious!r}"


def test_serial_validation_accepts_valid_formats(client):
    for valid in ["аб1234567", "AB1234567", "аб 1234-5678", "X-123"]:
        resp = client.post("/api/v1/verification/serial", json={"serial": valid})
        assert resp.status_code == 200, f"Expected 200 for {valid!r}"


def test_request_id_propagation(client):
    resp = client.get("/health", headers={"X-Request-ID": "test-id-123"})
    assert resp.headers.get("X-Request-ID") == "test-id-123"


def test_security_headers_present(client):
    resp = client.get("/health")
    assert resp.headers.get("X-Content-Type-Options") == "nosniff"
    assert resp.headers.get("X-Frame-Options") == "DENY"
    assert resp.headers.get("Referrer-Policy") == "no-referrer"
    assert resp.headers.get("Cache-Control") == "no-store"


def test_cors_rejects_wildcard_origin(client):
    resp = client.options(
        "/api/v1/banknotes",
        headers={
            "Origin": "https://evil.example.com",
            "Access-Control-Request-Method": "GET",
        },
    )
    aco = resp.headers.get("access-control-allow-origin")
    assert aco != "https://evil.example.com"
    assert aco != "*"


def test_cors_allows_whitelisted_origin(client):
    resp = client.options(
        "/api/v1/banknotes",
        headers={
            "Origin": "https://cashvision.ai",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.status_code in (200, 204)


def test_metrics_open_in_dev(client):
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert "cashvision_requests_total" in resp.text


def test_unknown_route_returns_404_json(client):
    resp = client.get("/api/v1/does-not-exist")
    assert resp.status_code == 404

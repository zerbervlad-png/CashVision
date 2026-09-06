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


def test_request_id_propagation(client):
    resp = client.get("/health", headers={"X-Request-ID": "test-id-123"})
    assert resp.headers.get("X-Request-ID") == "test-id-123"

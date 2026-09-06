"""
Locust load profile for CashVision backend.

Usage:
    locust -f tests/locustfile.py --host http://localhost:8000

Profiles:
    --tags smoke      — quick smoke (10 users, 30s)
    --tags baseline   — normal load (100 RPS target)
    --tags peak       — peak load (500 RPS target)
    --tags stress     — ramp until failure
    --tags soak       — long-running stability (30 min)

Run all:
    locust -f tests/locustfile.py --host http://localhost:8000 \
        --headless -u 100 -r 10 -t 60s --tags baseline
"""
import random
import string

from locust import HttpUser, between, events, tag, task


VALID_SERIALS = [
    "аб1234567", "AB1234567", "аб 1234-5678", "X-123",
    "БН4567890", "abc1234",
]
DENOMINATIONS = [100, 200, 500, 1000, 5000]


def _random_garbage(length: int = 12) -> str:
    return "".join(random.choices(string.printable, k=length))


@events.test_start.add_listener
def _on_start(environment, **kwargs):
    print(f"[locust] starting, host={environment.host}")


class AnonymousUser(HttpUser):
    """Read-heavy anonymous user (most common)."""
    wait_time = between(0.1, 0.5)
    weight = 5

    @tag("smoke", "baseline", "peak", "soak")
    @task(5)
    def health(self):
        self.client.get("/health")

    @tag("smoke", "baseline", "peak", "soak")
    @task(3)
    def list_banknotes(self):
        self.client.get("/api/v1/banknotes")

    @tag("baseline", "peak", "soak")
    @task(2)
    def get_banknote(self):
        denom = random.choice(DENOMINATIONS)
        with self.client.get(
            f"/api/v1/banknotes/RUB-{denom}",
            name="/api/v1/banknotes/[denom]",
            catch_response=True,
        ) as r:
            if r.status_code == 404:
                r.failure(f"banknote {denom} not found")

    @tag("baseline", "peak")
    @task(1)
    def get_model_version(self):
        self.client.get("/api/v1/model/version")

    @tag("baseline", "peak", "soak")
    @task(2)
    def get_feature_flags(self):
        self.client.get("/api/v1/feature-flags")


class SerialCheckerUser(HttpUser):
    """User that posts serial verifications (write-path)."""
    wait_time = between(0.5, 1.5)
    weight = 2

    @tag("baseline", "peak", "soak")
    @task(3)
    def verify_serial_valid(self):
        serial = random.choice(VALID_SERIALS)
        with self.client.post(
            "/api/v1/verification/serial",
            json={"serial": serial},
            name="/api/v1/verification/serial[valid]",
            catch_response=True,
        ) as r:
            if r.status_code != 200:
                r.failure(f"valid serial {serial} -> {r.status_code}")

    @tag("stress")
    @task(1)
    def verify_serial_garbage(self):
        # Should return 422 quickly; verifies input validation under load.
        with self.client.post(
            "/api/v1/verification/serial",
            json={"serial": _random_garbage(40)},
            name="/api/v1/verification/serial[invalid]",
            catch_response=True,
        ) as r:
            if r.status_code not in (422, 400):
                r.failure(f"garbage should 422, got {r.status_code}")


class StressedUser(HttpUser):
    """Aggressive user for stress testing — minimal wait."""
    wait_time = between(0.01, 0.05)
    weight = 0  # only when --tags stress

    @tag("stress")
    @task(1)
    def hammer_banknotes(self):
        self.client.get("/api/v1/banknotes")

    @tag("stress")
    @task(1)
    def hammer_health(self):
        self.client.get("/health")

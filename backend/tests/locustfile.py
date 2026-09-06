from locust import HttpUser, between, task


class CashVisionUser(HttpUser):
    wait_time = between(0.5, 2.0)
    host = "http://localhost:8000"

    @task(3)
    def list_banknotes(self):
        self.client.get("/api/v1/banknotes")

    @task(2)
    def get_model_version(self):
        self.client.get("/api/v1/model/version")

    @task(2)
    def get_banknote(self):
        self.client.get("/api/v1/banknotes/RUB-5000")

    @task(1)
    def verify_serial(self):
        self.client.post("/api/v1/verification/serial", json={"serial": "ab1234567"})

    @task(5)
    def health(self):
        self.client.get("/health")

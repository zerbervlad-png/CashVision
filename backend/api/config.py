from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="CASHVISION_")

    app_name: str = "CashVision API"
    environment: str = "development"
    debug: bool = False

    database_url: str = "postgresql+asyncpg://cashvision:cashvision@db:5432/cashvision"
    redis_url: str = "redis://redis:6379/0"

    rate_limit_per_minute: int = 60
    cors_origins: list[str] = ["https://cashvision.ai", "http://localhost:8000"]

    banknotes_source_url: str = "https://www.cbr.ru/cash_circulation/banknotes/"
    serial_verification_available: bool = False
    counting_enabled: bool = True
    max_free_scans_per_day: int = 5
    remote_model_enabled: bool = False

    log_level: str = "INFO"

    metrics_token: str = "change_me_in_production"

    @property
    def is_production(self) -> bool:
        return self.environment == "production"


settings = Settings()

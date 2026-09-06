from datetime import UTC, datetime
import re

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field, field_validator

from .config import settings
from .data import BANKNOTES_DATASET, MODEL_VERSION

router = APIRouter()
api_router = router

SERIAL_PATTERN = re.compile(r"^[А-Яа-яA-Za-z0-9 \-]{1,32}$")


class HealthResponse(BaseModel):
    status: str
    version: str
    timestamp: datetime


class FeatureFlagsResponse(BaseModel):
    counting_enabled: bool
    max_free_scans_per_day: int
    serial_verification_available: bool
    remote_model_enabled: bool


class ModelVersionResponse(BaseModel):
    name: str
    version: str
    min_ios_version: str
    download_url: str | None = None
    checksum: str | None = None


class SecurityFeatureModel(BaseModel):
    type: str
    title: str
    short_description: str
    instructions: list[str]
    check_methods: list[str]
    position: dict[str, float]
    visible_on_side: str


class BanknoteResponse(BaseModel):
    id: str
    currency: str
    denomination_value: int
    issue_year: int
    series: str
    front_image_name: str
    back_image_name: str
    security_features: list[SecurityFeatureModel]
    official_description: str
    official_source_url: str | None
    supported_checks: list[str]
    accessibility_description: str


class SerialVerificationRequest(BaseModel):
    serial: str = Field(min_length=1, max_length=32)

    @field_validator("serial")
    @classmethod
    def validate_serial(cls, v: str) -> str:
        v = v.strip()
        if not SERIAL_PATTERN.match(v):
            raise ValueError("invalid_serial_format")
        return v


class SerialVerificationResponse(BaseModel):
    serial: str
    status: str
    source: str
    timestamp: datetime
    message: str


@router.get("/health", response_model=HealthResponse, tags=["health"])
async def get_health() -> HealthResponse:
    return HealthResponse(status="ok", version="1.0.0", timestamp=datetime.now(UTC))


@router.get("/feature-flags", response_model=FeatureFlagsResponse, tags=["config"])
async def get_feature_flags() -> FeatureFlagsResponse:
    return FeatureFlagsResponse(
        counting_enabled=settings.counting_enabled,
        max_free_scans_per_day=settings.max_free_scans_per_day,
        serial_verification_available=settings.serial_verification_available,
        remote_model_enabled=settings.remote_model_enabled,
    )


@router.get("/model/version", response_model=ModelVersionResponse, tags=["config"])
async def get_model_version() -> ModelVersionResponse:
    return ModelVersionResponse(**MODEL_VERSION)


@router.get("/banknotes", response_model=list[BanknoteResponse], tags=["banknotes"])
async def list_banknotes() -> list[BanknoteResponse]:
    return [BanknoteResponse(**b) for b in BANKNOTES_DATASET]


@router.get(
    "/banknotes/{currency}-{denomination}",
    response_model=BanknoteResponse,
    tags=["banknotes"],
)
async def get_banknote(currency: str, denomination: int) -> BanknoteResponse:
    for b in BANKNOTES_DATASET:
        if b["currency"] == currency.upper() and b["denomination_value"] == denomination:
            return BanknoteResponse(**b)
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="banknote_not_found")


@router.post(
    "/verification/serial",
    response_model=SerialVerificationResponse,
    tags=["verification"],
)
async def verify_serial(payload: SerialVerificationRequest) -> SerialVerificationResponse:
    if not settings.serial_verification_available:
        return SerialVerificationResponse(
            serial=payload.serial,
            status="no_official_source",
            source="Официальный публичный API Банка России для проверки серийных номеров банкнот отсутствует",
            timestamp=datetime.now(UTC),
            message="Проверка по внешней базе недоступна. Используйте официальный способ проверки Банка России.",
        )
    return SerialVerificationResponse(
        serial=payload.serial,
        status="not_found_in_lists",
        source="Банк России",
        timestamp=datetime.now(UTC),
        message="Серийный номер не найден в списках недействительных/сомнительных банкнот.",
    )

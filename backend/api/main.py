import logging
import time
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from .config import settings
from .logger import configure_logging
from .routes import api_router

configure_logging(settings.log_level)
logger = logging.getLogger("cashvision.api")

limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.rate_limit_per_minute}/minute"])

REQUEST_COUNT = Counter("cashvision_requests_total", "Total API requests", ["method", "path", "status"])
REQUEST_LATENCY = Histogram("cashvision_request_duration_seconds", "Request latency", ["path"])


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("CashVision backend starting, env=%s", settings.environment)
    yield
    logger.info("CashVision backend shutting down")


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    lifespan=lifespan,
    openapi_url="/api/v1/openapi.json",
    docs_url="/api/v1/docs",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_request_context(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    request.state.request_id = request_id
    start = time.perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        logger.exception("Unhandled error, request_id=%s", request_id)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"error": "internal_error", "code": 500, "requestId": request_id},
        )
    duration = time.perf_counter() - start
    response.headers["X-Request-ID"] = request_id
    REQUEST_COUNT.labels(method=request.method, path=request.url.path, status=response.status_code).inc()
    REQUEST_LATENCY.labels(path=request.url.path).observe(duration)
    return response


app.include_router(api_router, prefix="/api/v1")


@app.get("/health", tags=["health"])
async def health() -> dict:
    return {"status": "ok", "version": "1.0.0", "environment": settings.environment}


@app.get("/metrics", tags=["metrics"], include_in_schema=False)
async def metrics():
    from fastapi.responses import Response

    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

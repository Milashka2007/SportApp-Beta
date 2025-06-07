from fastapi import FastAPI, Request, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from backend.app.core import config  # оставляем как есть
from backend.app.routes import auth
from backend.app.database import database
from backend.app.models import user
import logging
import uvicorn

# Настройка логирования
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Создаем таблицы в базе данных
user.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="Gymmi API",
    description="API для приложения Gymmi",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    default_response_class=JSONResponse,
    debug=False  # Отключаем режим отладки в продакшене
)

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене заменить на конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,
)

# Добавляем сжатие ответов
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Добавляем проверку доверенных хостов
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]  # В продакшене заменить на конкретные хосты
)

# Middleware для логирования запросов
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"Request: {request.method} {request.url}")
    response = await call_next(request)
    logger.info(f"Response status: {response.status_code}")
    return response

# Подключаем маршруты
app.include_router(auth.router, prefix=config.settings.API_V1_STR + "/auth", tags=["auth"])
app.include_router(auth.router, prefix=config.settings.API_V1_STR + "/users", tags=["users"])

@app.get("/")
async def root():
    return {"message": "Welcome to Gymmi API"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        workers=1,
        log_level="info",
        timeout_keep_alive=30,
        limit_concurrency=1000,
        backlog=2048,
        loop="uvloop",  # Используем uvloop для лучшей производительности
        http="httptools",  # Используем httptools для лучшей производительности
        proxy_headers=True,
        forwarded_allow_ips="*"
    )

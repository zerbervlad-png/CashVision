# CashVision / Cash AI

Коммерческое B2C-приложение для iPhone — распознавание российских банкнот через камеру, проверка защитных признаков, пересчёт суммы наличных, история операций и Premium-подписка.

> **Важно.** Приложение помогает проверить визуальные защитные признаки банкноты. Это **не является гарантией подлинности**. Для окончательной проверки используйте официальный способ проверки Банка России.

## Принципы

- **LOCAL-FIRST.** Изображения банкнот обрабатываются на устройстве и не отправляются на сервер без необходимости.
- **Privacy-first.** Не собираются фотографии, серийные номера, персональные данные.
- **Official sources only.** Данные о защитных признаках берутся из официальных материалов Банка России (cbr.ru).
- **No misleading claims.** Приложение не заявляет «100% подлинность».

## Архитектура

```
SwiftUI
↓
Presentation Layer (Features/{Check,Count,History,Premium,Settings,Onboarding})
↓
Application / Use Cases (ViewModels, Services)
↓
Domain Layer (Models, Repositories, Entities)
↓
Data Layer (Local/Remote providers, DTO, Repositories)
↓
Local / Network (Keychain, SwiftData, URLSession, StoreKit 2)
```

Модули:

```
CashVision/
├── App/                  — точка входа, контейнер зависимостей, RootView
├── Core/                 — Logging (OSLog), Configuration, Errors, Extensions
├── Domain/               — Models, Entities, Repositories, UseCases
├── Data/                 — Local, Remote, DTO, Repositories
├── Camera/               — AVFoundation camera service
├── ComputerVision/       — ML models, Tracking (anti-duplicate)
├── BanknoteRecognition/  — распознавание банкнот
├── BanknoteVerification/ — проверка признаков и статусов
├── Counting/             — пересчёт нескольких банкнот
├── History/              — SwiftData история операций
├── Subscription/         — StoreKit 2 подписки
├── Networking/           — APIClient, rate limiting, retry
├── Security/             — Keychain, редействие данных
├── Analytics/            — privacy-friendly аналитика
├── Settings/             — настройки пользователя
├── UIComponents/         — переиспользуемые компоненты
└── Features/             — экраны по режимам (Check, Count, History, Premium, Settings, Onboarding)
```

## Стек

- Swift 5.10+, iOS 17+
- SwiftUI + Observation
- AVFoundation, Vision, Core ML, Core Image, Accelerate
- StoreKit 2 (подписки)
- SwiftData (история)
- URLSession + async/await
- Keychain (секреты)
- OSLog (логирование)
- XCTest + XCUITest

## Запуск на Mac

### Одна команда

```bash
chmod +x run-mac.sh
./run-mac.sh
```

### Получить последние правки (UAT + security + новые фичи)

```bash
# С нуля:
git clone -b feature/uat-security-compliance https://github.com/zerbervlad-png/CashVision.git
cd CashVision
./run-mac.sh

# Если репозиторий уже склонирован:
git fetch origin
git checkout feature/uat-security-compliance
git pull origin feature/uat-security-compliance
./run-mac.sh
```

> Ветка `feature/uat-security-compliance` содержит: UAT-план (`docs/UAT.md`),
> исправления security-аудита (OWASP MASVS L1), App Store compliance, новые
> фичи (авто-фонарик, тактильная отдача), расширенные backend-тесты (17 шт.)
> и locust-профили (baseline/peak/stress/soak).

Скрипт:
1. Проверяет macOS, Xcode, Swift.
2. Устанавливает XcodeGen (через Homebrew) при отсутствии.
3. Генерирует `CashVision.xcodeproj` из `project.yml`.
4. Находит/создаёт iPhone Simulator.
5. Собирает и запускает приложение.

### По шагам

```bash
./scripts/bootstrap.sh   # первичная настройка + генерация проекта
./scripts/dev.sh         # запуск в Simulator
./scripts/test.sh        # unit + UI тесты
./scripts/build.sh       # сборка (Debug или CONFIG=Release)
./scripts/archive.sh     # архив для App Store
./scripts/release.sh     # экспорт IPA
./scripts/clean.sh       # очистка артефактов
```

### Makefile

```bash
make bootstrap
make dev
make test
make build
make archive
make release
make clean
```

## Разработка на Windows

Исходный код проекта полностью совместим с Git и не требует Xcode для редактирования. На Windows вы редактируете Swift-файлы и `project.yml`. Файл `CashVision.xcodeproj` **не хранится в репозитории** — он генерируется на Mac через XcodeGen из `project.yml`.

```bash
# Windows: просто редактируйте исходники.
# Перед коммитом убедитесь, что .gitignore исключает DerivedData, .build, *.xcuserstate.
```

## Backend

Минимальный backend на FastAPI + PostgreSQL + Redis + Nginx.

```bash
cd backend
cp .env.example .env
docker compose up -d --build
```

API доступен на `http://localhost:8000` (документация: `/api/v1/docs`).

### Эндпоинты

- `GET /health`
- `GET /api/v1/feature-flags`
- `GET /api/v1/model/version`
- `GET /api/v1/banknotes`
- `GET /api/v1/banknotes/{currency}-{denomination}`
- `POST /api/v1/verification/serial`

### Нагрузочное тестирование

```bash
cd backend
pip install locust
locust -f tests/locustfile.py --host http://localhost:8000
```

## Тестирование

- **Unit:** `Tests/Unit/` — BanknoteRepository, CountingEngine, BanknoteTracker, Verification, History, APIClient.
- **UI (XCUITest):** `Tests/UI/CashVisionUITests.swift` — сценарии SC-001…SC-010 и более.
- **Backend:** `backend/tests/test_api.py` — pytest + TestClient.

## CI/CD

GitHub Actions:
- `.github/workflows/ios.yml` — сборка и тесты iOS на `macos-14`.
- `.github/workflows/backend.yml` — lint, тесты и Docker build на Ubuntu.

## Privacy

- Камера запрашивается только в момент необходимости.
- Изображения банкнот не покидают устройство.
- Аналитика опциональна и анонимна (отключается в Настройках).
- Privacy Manifest: `CashVision/Resources/PrivacyInfo.xcprivacy`.
- Подробно: `CashVision/Features/Settings/SettingsView.swift` → `PrivacyPolicyView`.

## App Store Compliance

- **NSCameraUsageDescription** объясняет необходимость камеры.
- **ITSAppUsesNonExemptEncryption = false** — приложение не использует несанкционированное шифрование.
- Подписки через **StoreKit 2** — `cashvision.premium.monthly` и `cashvision.premium.yearly`.
- Restore Purchases доступен на экране Premium.
- Никаких заявлений «100% подлинность» — только «помогает проверить признаки».

## App Store Metadata

Подготовлено в `docs/app_store_metadata.md` (RU + EN).

## Известные проблемы

См. `KNOWN_ISSUES.md`.

## Лицензия

© 2026 CashVision. Все права защищены.

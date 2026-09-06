# Известные проблемы

Документ ведётся по принципу **Failure-Driven Development**: проблемы не скрываются, а явно фиксируются с указанием причины, влияния и обходного пути.

> **Решённые в `feature/uat-security-compliance`:**
> - Удалён невалидный ключ `NSPrivacyAccessedAPICamera` из Privacy Manifest (блокировал App Store review).
> - `UIRequiredDeviceCapabilities` исправлен с `armv7` на `arm64`.
> - Backend CORS: убран `*`, `allow_credentials=False`, ограниченные methods/headers.
> - Backend: добавлены security headers `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Cache-Control: no-store`.
> - Backend: `/metrics` защищён Bearer-токеном в production.
> - Backend: валидация серийного номера по regex (защита от log/DB injection).
> - `SecurityService.save` теперь throws на ошибку Keychain.
> - Добавлены: авто-фонарик, тактильная отдача, расширенные Settings.
> - Backend-тесты расширены до 17 шт. (security + валидация).
> - Locust: профили baseline/peak/stress/soak.
> - UAT-план: `docs/UAT.md` (124 сценария, 5 ролей, OWASP MASVS L1 чек-лист).

## 1. ML-модели распознавания банкнот — заглушки

- **Проблема.** В `CashVision/ComputerVision/Models/MLModels.swift` реализованы stub-классы `StubBanknoteDetector`, `StubBanknoteClassifier`, `StubBanknoteQualityModel`. Реальные Core ML модели (`BanknoteDetector.mlmodel`, `BanknoteClassifier.mlmodel`, `BanknoteQualityModel.mlmodel`) отсутствуют в репозитории — их нужно обучить и добавить в проект.
- **Причина.** Обучение ML-модели требует репрезентативного датасета банкнот в разных условиях (см. раздел ТЗ №33 «Computer Vision Testing»). Этот датасет содержит защищённые изображения и не может быть включён в открытый репозиторий.
- **Влияние.** Распознавание в live-режиме возвращает пустой результат. Полный pipeline CV реализован, но не подключён к обученной модели.
- **Workaround.** Использовать `LocalBanknoteDataProvider` для просмотра защитных признаков конкретной банкноты вручную.
- **Что требуется вручную.** Собрать датасет (или получить разрешение Банка России), обучить модель в Create ML/Turicreate/CoreMLTools, экспортировать `.mlmodel`, добавить в `CashVision/ComputerVision/Models/` и заменить stub-классы на сгенерированные.

## 2. Серийная проверка банкнот

- **Проблема.** Официальный публичный API Банка России для проверки серийных номеров банкнот отсутствует.
- **Причина.** Банк России не предоставляет публичный endpoint.
- **Влияние.** Метод `checkSerialNumber()` всегда возвращает статус `noOfficialSource`.
- **Workaround.** UI показывает «Проверка по внешней базе недоступна» и рекомендует официальный способ проверки.
- **Что требуется вручную.** Если Банк России выпустит публичный API, реализуйте `RemoteBanknoteSerialVerificationProvider` и добавьте его в `CompositeSerialVerificationProvider`. UI изменения не потребуются.

## 3. StoreKit 2 — Sandbox тестирование

- **Проблема.** `SubscriptionManager` корректно обрабатывает покупки/restore/expiration, но реальная проверка требует StoreKit Configuration File и Sandbox-аккаунта.
- **Workaround.** Для локальной отладки используйте StoreKit Configuration File `.storekit` в Xcode.
- **Что требуется вручную.** Создать продукты в App Store Connect и StoreKit Configuration File в Xcode.

## 4. Изображения банкнот

- **Проблема.** Изображения банкнот (`rub*_front`, `rub*_back`) не включены в репозиторий.
- **Причина.** Использование изображений банкнот требует согласования с Банком России.
- **Workaround.** Приложение работает без них — отображается только текстовое описание и позиции защитных признаков.
- **Что требуется вручную.** Получить разрешение Банка России или использовать публичные материалы cbr.ru согласно их правилам.

## 5. Тестирование на реальных устройствах

- **Проблема.** Camera+Vision pipeline невозможно полноценно протестировать на Simulator (нет реальной камеры).
- **Workaround.** Использовать реальные iPhone для CV-тестирования. UI и unit-тесты работают на Simulator.

## 6. Code Signing

- **Проблема.** Проект собирается без подписи (`CODE_SIGNING_ALLOWED=NO`) для удобства разработки.
- **Что требуется вручную.** Перед archive/release указать `DEVELOPMENT_TEAM` в `project.yml` или через Xcode.

## 7. Backend persistence

- **Проблема.** Реализована только инициализация PostgreSQL схемы (`backend/db/init.sql`). Полноценные миграции через Alembic требуют дополнительной настройки.
- **Workaround.** Использовать `init.sql` для dev-окружения.
- **Что требуется вручную.** Настроить Alembic-миграции при развитии backend.

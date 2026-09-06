# UAT — User Acceptance Testing

Полный план приёмочного тестирования CashVision. Проводится на реальном iPhone (iOS 17+) и/или iPhone Simulator (для UI/unit-тестов). Backend поднимается локально (`docker compose up -d` или `uvicorn api.main:app --port 8000`).

## Роли

| Роль | Описание | Лимиты |
|------|----------|--------|
| **Free** | Новый пользователь без подписки | 5 сканов/день, базовый пересчёт, история 7 дней |
| **Premium (monthly/yearly)** | Активная подписка StoreKit 2 | Безлимитный скан, расширенный пересчёт, безлимитная история |
| **Expired Premium** | Подписка истекла | Откат к Free-лимитам, история сохраняется |
| **Offline user** | Нет сети | Только локальные данные + bundled CoreML |
| **First-launch user** | Onboarding ещё не пройден | 3 экрана онбординга, можно пропустить |

## Окружения

| Окружение | Где запускать | Что покрывает |
|-----------|---------------|----------------|
| iPhone 15 Pro (iOS 17.6) | Реальное устройство | Камера, Vision, CoreML, StoreKit Sandbox, Haptics |
| iPhone 15 Simulator | Xcode → Simulator | UI, навигация, accessibility, history |
| Backend local | `cd backend && docker compose up -d` | API, rate limiting, CORS, metrics |
| Backend headless | `uvicorn api.main:app --port 8000` | API без Redis/Postgres (in-memory) |

## Сценарии UAT

### A. Onboarding & First Launch (роль: First-launch user)

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-001 | Первый запуск | Установить приложение, открыть | Показан онбординг (1/3) | ☐ |
| UAT-002 | Пропуск онбординга | Нажать «Пропустить» | Переход к экрану камеры | ☐ |
| UAT-003 | Полный онбординг | Пройти 3 экрана → «Начать» | Запрос разрешения камеры | ☐ |
| UAT-004 | Разрешение камеры | Нажать «Разрешить» | Камера запускается, видна подсказка «Наведите камеру на банкноту» | ☐ |
| UAT-005 | Отказ камеры | Нажать «Запретить» | Экран объяснения + кнопка «Открыть Настройки» | ☐ |
| UAT-006 | Disclaimer | Проверить наличие | Над/под камерой disclaimer «Не является гарантией подлинности» | ☐ |

### B. Recognition — Check mode (роли: Free, Premium)

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-010 | Наведение на 5000 ₽ | Навести камеру на 5000 ₽ (лицевая) | Определён номинал 5000 ₽, обрамление, confidence > 0.8 | ☐ |
| UAT-011 | Наведение на 1000 ₽ | То же для 1000 ₽ | Определён 1000 ₽ | ☐ |
| UAT-012 | Наведение на 500 ₽ | То же для 500 ₽ | Определён 500 ₽ | ☐ |
| UAT-013 | Наведение на 200 ₽ | То же для 200 ₽ | Определён 200 ₽ | ☐ |
| UAT-014 | Наведение на 100 ₽ | То же для 100 ₽ | Определён 100 ₽ | ☐ |
| UAT-015 | Тусклый свет | Закрыть камеру рукой / тусклая комната | Сообщение `insufficientLight` или автоподсветка | ☐ |
| UAT-016 | Чужой объект | Навести на телефон/книгу | Банкнота не определяется (нет ложного срабатывания) | ☐ |
| UAT-017 | Частично закрытая банкнота | Закрыть половину банкноты | Низкая confidence, нет ложного результата | ☐ |
| UAT-018 | Перемещение банкноты | Двигать банкноту в кадре | Нет повторного счёта (трекинг) | ☐ |
| UAT-019 | Bottom sheet признаков | Тап по кнопке признака | Открывается лист с инструкцией по проверке | ☐ |
| UAT-020 | Free-лимит сканов | Сделать 6 сканов | 6-й блокируется, показан экран Premium | ☐ |
| UAT-021 | Premium безлимит | Активировать Premium → сканировать | Лимита нет | ☐ |

### C. Count mode (роли: Free, Premium)

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-030 | Подсчёт 3 банкнот | Перейти в Count, просканировать 3×500 | Сумма = 1500 ₽ | ☐ |
| UAT-031 | Смешанный подсчёт | 500 + 1000 + 200 | Сумма = 1700 ₽ | ☐ |
| UAT-032 | Сброс | Нажать «Сбросить» | Счётчик = 0 | ☐ |
| UAT-033 | Дубликат | Держать одну банкноту > 3 сек | Не считается дважды | ☐ |
| UAT-034 | Free-лимит Count | Превысить лимит Count | Предложение Premium | ☐ |

### D. History (роли: Free, Premium, Expired)

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-040 | Сохранение операции | Сделать скан → открыть History | Операция в списке | ☐ |
| UAT-041 | Сортировка | Проверить порядок | Последние сверху | ☐ |
| UAT-042 | Удаление одной | Свайп влево по записи | Запись удалена | ☐ |
| UAT-043 | Очистка всей истории | Нажать «Очистить» → подтвердить | История пуста | ☐ |
| UAT-044 | Free-хранение 7 дней | Проверить старые (>7д) записи | Автоматически удалены | ☐ |
| UAT-045 | Premium безлимит | Активировать Premium | Старые записи сохраняются | ☐ |

### E. Premium & Subscriptions (StoreKit Sandbox)

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-050 | Открыть Premium | Тап «Premium» | Экран с тарифами (месяц/год) | ☐ |
| UAT-051 | Загрузка тарифов | Подождать 2 сек | Тарифы с ценами отображены | ☐ |
| UAT-052 | Покупка месячной | Нажать «Купить» → подтвердить в Sandbox | Статус = Premium, галочка | ☐ |
| UAT-053 | Покупка годовой | То же для yearly | Статус = Premium | ☐ |
| UAT-054 | Restore Purchases | Переустановить приложение → «Восстановить» | Premium восстановлен | ☐ |
| UAT-055 | Subscription expired | В Sandbox дождаться истечения | Статус = expired, откат к Free | ☐ |
| UAT-056 | Отмена покупки | Отменить в системном диалоге | Без изменений, статус Free | ☐ |
| UAT-057 | Pending покупка | Sandbox → «Ask to Buy» | Статус pending, без блокировки UI | ☐ |

### F. Settings & Privacy

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-060 | Открыть Settings | Тап «Настройки» | Список опций | ☐ |
| UAT-061 | Privacy Policy | Открыть | Текст политики | ☐ |
| UAT-062 | Аналитика вкл/выкл | Переключатель | Сохраняется в UserDefaults | ☐ |
| UAT-063 | Haptics вкл/выкл | Переключатель | Вибрация при распознавании | ☐ |
| UAT-064 | Авто-фонарик | Переключатель | Тумблер torch on/off | ☐ |
| UAT-065 | Стирание данных | Нажать «Очистить все данные» | Keychain + SwiftData очищены | ☐ |

### G. Accessibility

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-070 | VoiceOver | Включить VoiceOver | Все элементы озвучены, навигация работает | ☐ |
| UAT-071 | Dynamic Type XL | Settings → Accessibility → Larger Text | Размеры адаптированы | ☐ |
| UAT-072 | Dark Mode | Settings → Dark | Цвета корректны | ☐ |
| UAT-073 | Reduce Motion | Settings → Accessibility | Анимации упрощены | ☐ |
| UAT-074 | High Contrast | Increase Contrast | Границы видимы | ☐ |

### H. Networking & Resilience

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-080 | Нет сети | Airplane mode → открыть Check | Локальное распознавание работает | ☐ |
| UAT-081 | Server 500 | Заглушить backend на 500 | APIClient retry ×2, затем fallback | ☐ |
| UAT-082 | Rate limit 429 | Превысить 60 req/min | APIClient корректно отображает | ☐ |
| UAT-083 | Backend down | Не запускать backend | Приложение не падает, локальные данные | ☐ |
| UAT-084 | Slow network | Network Link Conditioner 3G | Retry + корректные таймауты | ☐ |

### I. Background / Lifecycle

| ID | Сценарий | Шаги | Ожидаемый результат | Статус |
|----|----------|------|---------------------|--------|
| UAT-090 | App backgrounded | Свернуть приложение во время камеры | Камера остановлена | ☐ |
| UAT-091 | App foregrounded | Вернуться в приложение | Камера возобновлена | ☐ |
| UAT-092 | App killed | Смахнуть из переключателя | При повторном запуске состояние восстановлено (history) | ☐ |

### J. Backend API (curl/httpie)

| ID | Сценарий | Команда | Ожидаемый результат | Статус |
|----|----------|---------|---------------------|--------|
| UAT-100 | Health | `GET /health` | 200, `{"status":"ok"}` | ☐ |
| UAT-101 | Feature flags | `GET /api/v1/feature-flags` | 200, содержит 4 флага | ☐ |
| UAT-102 | Banknotes list | `GET /api/v1/banknotes` | 200, массив ≥ 5 | ☐ |
| UAT-103 | Banknote by denom | `GET /api/v1/banknotes/RUB-5000` | 200, denomination_value=5000 | ☐ |
| UAT-104 | Unknown banknote | `GET /api/v1/banknotes/RUB-7777` | 404, `banknote_not_found` | ☐ |
| UAT-105 | Serial verify | `POST /api/v1/verification/serial {"serial":"аб1234567"}` | 200, `no_official_source` | ☐ |
| UAT-106 | Serial empty | `POST /api/v1/verification/serial {"serial":""}` | 422 | ☐ |
| UAT-107 | Serial injection | `{"serial":"<script>"}` | 422 (validation) | ☐ |
| UAT-108 | Rate limit | 100 req/min | Несколько 429 после 60-го | ☐ |
| UAT-109 | CORS | OPTIONS preflight | `Access-Control-Allow-Origin` из белого списка | ☐ |
| UAT-110 | Security headers | Любой запрос | X-Content-Type-Options, X-Frame-Options, Cache-Control | ☐ |
| UAT-111 | Metrics prod | `GET /metrics` в production | 403 без токена | ☐ |
| UAT-112 | Request-ID | `GET /health` с X-Request-ID | Echo в response header | ☐ |

### K. Нагрузочное тестирование

| ID | Сценарий | Профиль | Метрика | Целевое значение | Статус |
|----|----------|---------|---------|------------------|--------|
| UAT-120 | Базовый read | 100 RPS, 1 min | p95 latency | < 100 ms | ☐ |
| UAT-121 | Пиковая read | 500 RPS, 1 min | p95 latency | < 300 ms | ☐ |
| UAT-122 | Смешанный | 70/30 GET/POST | error rate | < 1% | ☐ |
| UAT-123 | Stress | +100 RPS каждые 30 сек | Когда p95 > 500 мс | graceful 429 | ☐ |
| UAT-124 | Soak | 50 RPS, 30 min | memory leak | RSS стабильна | ☐ |

### L. Security Audit Checklist (OWASP MASVS L1)

| ID | Контроль | Реализация | Статус |
|----|----------|------------|--------|
| SEC-001 | V1.1 Privacy Manifest заполнен | `PrivacyInfo.xcprivacy` | ✅ |
| SEC-002 | V1.2 Cam, Photo — required-reason APIs корректны | Удалён невалидный `NSPrivacyAccessedAPICamera` | ✅ |
| SEC-003 | V2.1 No sensitive data in logs | OSLog + redact | ✅ |
| SEC-004 | V2.2 No secrets in code | Нет захардкоженных ключей | ✅ |
| SEC-005 | V3.1 TLS everywhere | URLSession + HTTPS backend | ✅ |
| SEC-006 | V4.1 Auth on privileged endpoints | `/metrics` защищён в prod | ✅ |
| SEC-007 | V4.2 Sufficient input validation | Serial pattern + pydantic | ✅ |
| SEC-008 | V4.3 Rate limiting | slowapi + nginx limit_req | ✅ |
| SEC-009 | V5.1 Keychain для секретов | SecurityService | ✅ |
| SEC-010 | V5.2 No insecure storage | UserDefaults только для настроек | ✅ |
| SEC-011 | V7.1 Hardening headers | X-Frame, X-Content-Type, Cache-Control | ✅ |
| SEC-012 | V7.2 CORS strict | Whitelist origins, `allow_credentials=False` | ✅ |
| SEC-013 | V8.1 StoreKit signed transactions | `VerificationResult.verified` | ✅ |
| SEC-014 | V8.2 Restore purchases available | `SubscriptionManager.restorePurchases` | ✅ |

## Критерии приёмки (Definition of Done)

Приложение считается прошедшим UAT, если:
- Все сценарии UAT-001…UAT-124 имеют статус «pass» или «N/A (обосновано)».
- Все SEC-контроли MASVS L1 — pass.
- Backend: 100% pytest pass, locust p95 < 300 мс при 500 RPS, error rate < 1%.
- iOS: сборка `make test` green, `make build Release` без warnings.
- App Store Connect: `archive` загружается без ошибок, metadata проходит автоматическую валидацию.

## Дефекты

Все найденные дефекты фиксируются в KNOWN_ISSUES.md или как GitHub Issues.

## Подписи

- QA Engineer: __________________ / дата: ____________
- Developer: __________________ / дата: ____________
- Product Owner: __________________ / дата: ____________

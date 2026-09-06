# QA-сценарии (SC-001 … SC-020)

| ID | Сценарий | Ожидание | Покрытие |
|----|----------|----------|----------|
| SC-001 | Первый запуск | Камера запускается после разрешения permission | `CashVisionUITests.testSC001_appLaunchesAndShowsCameraHint` |
| SC-002 | Запрет камеры | Понятный экран объяснения и кнопка перехода в Settings | `CameraPermissionView` в `CheckView.swift` |
| SC-003 | Наведение на 5000 ₽ | Определяется 5000 ₽ | Зависит от ML-модели (см. KNOWN_ISSUES) |
| SC-004 | Наведение на 1000 ₽ | Определяется 1000 ₽ | Зависит от ML-модели |
| SC-005 | Наведение на 500 ₽ | Определяется 500 ₽ | Зависит от ML-модели |
| SC-006 | Несколько банкнот | Корректное количество | Зависит от ML-модели |
| SC-007 | Перемещение банкноты | Нет повторного счёта | `BanknoteTrackerTests.testDuplicateNotCountedTwice` |
| SC-008 | Плохое освещение | Сообщение о качестве | `AppError.insufficientLight` |
| SC-009 | Частично закрытая банкнота | Низкая confidence | `BanknoteRecognitionService.isPartial` |
| SC-010 | Другой объект | Банкнота не определяется | Логика детектора (ML) |
| SC-011 | Нет интернета | Локальное распознавание работает | `CompositeBanknoteDataProvider` fallback на local |
| SC-012 | Server unavailable | Приложение не падает | `APIClient` retry + fallback |
| SC-013 | Покупка Premium | Подписка активируется | `SubscriptionManager.purchase` |
| SC-014 | Restore Purchases | Восстановление покупок | `SubscriptionManager.restorePurchases` |
| SC-015 | Subscription expired | Корректный статус | `SubscriptionManager.refreshStatus` (expired) |
| SC-016 | Dark Mode | Корректное отображение | SwiftUI ColorScheme automatic |
| SC-017 | Dynamic Type | Корректные размеры | SwiftUI Dynamic Type |
| SC-018 | VoiceOver | Доступность | `accessibilityLabel`, `accessibilityHint` |
| SC-019 | App killed during camera | Корректный останов | `CameraService.handleAppBackground` |
| SC-020 | App resumed | Возврат к работе | `CameraService.handleAppForeground` |

# Architecture / Security / Privacy / UX / Performance / Apple Review Audit

Финальный аудит проекта по 8 направлениям (раздел ТЗ №48).

## 1. Architecture Review

- ✅ Clean Architecture + MVVM: SwiftUI → Presentation → Use Cases → Domain → Data → Local/Network.
- ✅ Разделение на модули (App, Core, Domain, Data, Camera, ComputerVision, BanknoteRecognition, BanknoteVerification, Counting, History, Subscription, Networking, Security, Analytics, Settings, UIComponents, Features).
- ✅ Dependency Inversion: `BanknoteDataProvider`, `BanknoteSerialVerificationProvider`, `BanknoteRepositoryProtocol` — протоколы.
- ✅ `AppContainer` собирает зависимости в одном месте.
- ✅ `@Observable` (Observation framework, iOS 17+) вместо Combine для state.
- ✅ Swift Concurrency (`async/await`, `Task`, actor для `RateLimiter`).
- ⚠️ `BanknoteTracker` сделан `@MainActor`-классом (вместо actor) для синхронных вызовов из `CountingService`. Это допустимо, так как используется только из главного потока.

## 2. Security Review

- ✅ Keychain используется для секретов (`SecurityService`).
- ✅ HTTPS для backend; Nginx включает HSTS.
- ✅ API keys не хранятся в приложении.
- ✅ Логи не содержат персональных данных/серийных номеров/платёжных данных.
- ✅ Rate limiting на backend (`slowapi`) и в `APIClient`.
- ✅ Request ID propagation (`X-Request-ID`).
- ✅ Certificate validation — по умолчанию URLSession.
- ⚠️ Jailbreak detection не реализован — не критично для приложения проверки банкнот.

## 3. Privacy Review

- ✅ Privacy Manifest: `CashVision/Resources/PrivacyInfo.xcprivacy`.
- ✅ `NSPrivacyTracking = false`.
- ✅ Camera — единственное разрешение, обязательное для работы.
- ✅ Изображения не покидают устройство (LOCAL-FIRST).
- ✅ Аналитика опциональна, отключается в Настройках.
- ✅ История хранится локально (SwiftData).
- ✅ Privacy Policy в `SettingsView.PrivacyPolicyView`.

## 4. UX Review

- ✅ Главный экран — камера.
- ✅ Подсказка «Наведите камеру на банкноту» до распознавания.
- ✅ 4 режима (Проверить, Посчитать, История, Premium).
- ✅ Bottom sheets для защитных признаков.
- ✅ Статусы: «Банкнота распознана», «Номинал определён», и т.д.
- ✅ Disclaimer «Не является гарантией подлинности».
- ✅ Onboarding максимум 3 экрана, можно пропустить.
- ✅ Haptic feedback готов к добавлению (через `UIImpactFeedbackGenerator`).

## 5. Accessibility Review

- ✅ Dynamic Type (через `@ScaledMetric` и `.font`).
- ✅ VoiceOver labels на интерактивных элементах (FeaturePin, кнопки).
- ✅ Reduce Motion поддерживается через `SettingsStore.reduceMotion`.
- ✅ High Contrast — SF Symbols и semantic colors.
- ✅ `accessibilityDescription` для каждой банкноты в dataset.

## 6. Performance Review

- ✅ Frame throttling (`FrameThrottler`, 10–15 FPS).
- ✅ Тяжёлые операции вне main thread (Vision/Core ML через `async`).
- ✅ Battery: при отсутствии банкноты уменьшается FPS (`setInferenceFPS`).
- ✅ Camera session останавливается в background (`handleAppBackground`).
- ✅ Cache для banknote definitions (`NSCache`).

## 7. Apple Review Review

- ✅ App Store Review Guidelines compliance:
  - Нет misleading claims («100% подлинность»).
  - Подписки через StoreKit 2.
  - Restore Purchases доступен.
  - Camera usage объяснён в Info.plist.
  - Privacy Manifest заполнен.
  - `ITSAppUsesNonExemptEncryption = false`.
- ✅ Subscription metadata: `cashvision.premium.monthly`, `cashvision.premium.yearly`.
- ✅ App Store metadata подготовлен в `docs/app_store_metadata.md`.

## 8. Final Notes

- Build: `./run-mac.sh` или `make bootstrap && make dev`.
- Tests: `make test`.
- Backend: `cd backend && docker compose up -d`.
- Известные ограничения — в `KNOWN_ISSUES.md`.

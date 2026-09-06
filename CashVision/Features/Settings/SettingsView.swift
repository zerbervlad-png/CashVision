import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Внешний вид") {
                    Picker("Тема", selection: Binding(
                        get: { settings.preferredColorScheme },
                        set: { settings.preferredColorScheme = $0 }
                    )) {
                        ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                            Text(scheme.title).tag(scheme)
                        }
                    }
                    Toggle("Снижение анимаций", isOn: Binding(
                        get: { settings.reduceMotion },
                        set: { settings.reduceMotion = $0 }
                    ))
                }

                Section("Камера и отдача") {
                    Toggle("Тактильная отдача", isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { settings.hapticsEnabled = $0 }
                    ))
                    Toggle("Авто-фонарик", isOn: Binding(
                        get: { settings.autoTorchInLowLight },
                        set: { settings.autoTorchInLowLight = $0 }
                    ))
                }

                Section("Приватность") {
                    Toggle("Отправлять анонимную аналитику", isOn: Binding(
                        get: { settings.allowAnalytics },
                        set: { settings.allowAnalytics = $0 }
                    ))
                    Toggle("Сохранять результаты в Фото", isOn: Binding(
                        get: { settings.saveResultsToPhotos },
                        set: { settings.saveResultsToPhotos = $0 }
                    ))
                    NavigationLink("Политика конфиденциальности") {
                        PrivacyPolicyView()
                    }
                }

                Section("О приложении") {
                    LabeledContent("Версия", value: appVersion)
                    LabeledContent("Сборка", value: buildNumber)
                    Link("Сайт CashVision", destination: URL(string: "https://cashvision.ai")!)
                    Link("Источник данных: cbr.ru", destination: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/")!)
                }

                Section {
                    Button("Очистить все данные", role: .destructive) {
                        settings.reset()
                        SecurityService().delete(key: "subscription-cache")
                    }
                    Button("Сбросить настройки", role: .destructive) {
                        settings.reset()
                    }
                }
            }
            .navigationTitle("Настройки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text(PrivacyPolicy.text)
                .padding()
        }
        .navigationTitle("Политика конфиденциальности")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum PrivacyPolicy {
    static let text = """
    Политика конфиденциальности CashVision

    Последнее обновление: 06.09.2026

    1. Принципы обработки данных
    CashVision работает по принципу LOCAL-FIRST. Изображения банкнот обрабатываются на вашем iPhone и не отправляются на сервер без необходимости.

    2. Какие данные собираются
    • Анонимная статистика использования (только если включена в Настройках)
    • История операций (хранится локально на устройстве)
    • Состояние подписки (через Apple StoreKit 2)

    3. Что мы НЕ собираем
    • Фотографии банкнот
    • Серийные номера банкнот
    • Персональные данные
    • Геолокацию
    • Контакты

    4. Где хранятся данные
    Все данные по умолчанию хранятся локально на вашем устройстве в защищённом хранилище iOS (Keychain / UserDefaults / SwiftData). Серверная часть используется только для обновления метаданных банкнот и моделей распознавания.

    5. Срок хранения
    История операций хранится, пока вы её не удалите. Аналитика агрегированная и не содержит идентификаторов.

    6. Удаление данных
    Вы можете удалить историю операций в любой момент в разделе «История» → «Очистить».

    7. Сторонние сервисы
    CashVision использует Apple StoreKit 2 для оформления подписок. Apple обрабатывает платежи в соответствии со своей политикой конфиденциальности.

    8. Контакты
    Вопросы по приватности: privacy@cashvision.ai
    """
}

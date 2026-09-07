import SwiftUI
import StoreKit

struct PremiumView: View {
    @Bindable var manager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    plansSection
                    restoreSection
                    disclaimerSection
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await manager.loadProducts() }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.yellow)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 6) {
                Text("CashVision Premium")
                    .font(.title2.bold())
                Text("Расширенные возможности\nдля проверки и пересчёта банкнот")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FeatureRow(icon: "infinity", title: "Безлимитная проверка", subtitle: "Сколько угодно сканирований в день")
            FeatureRow(icon: "list.bullet.rectangle", title: "Расширенный пересчёт", subtitle: "Дополнительные валюты и опции")
            FeatureRow(icon: "clock.arrow.circlepath", title: "История операций", subtitle: "Сохранение и экспорт результатов")
            FeatureRow(icon: "checkmark.shield", title: "Расширенная проверка", subtitle: "Дополнительные защитные элементы")
        }
        .padding(18)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            if manager.products.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Загрузка тарифов…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(manager.products, id: \.id) { product in
                    PlanCard(product: product) {
                        Task {
                            await manager.purchase(product)
                        }
                    }
                }
            }
        }
    }

    private var restoreSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await manager.restorePurchases() }
            } label: {
                Label("Восстановить покупки", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
    }

    private var disclaimerSection: some View {
        VStack(spacing: 8) {
            Text(statusDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Link("Политика конфиденциальности", destination: URL(string: "https://cashvision.ai/privacy")!)
                Link("Условия использования", destination: URL(string: "https://cashvision.ai/terms")!)
            }
            .font(.caption)
        }
        .padding(.top, 8)
    }

    private var statusDescription: String {
        switch manager.status {
        case .premium(let expires):
            if let expires {
                return "Premium активна до \(expires.formatted(date: .abbreviated, time: .omitted))"
            } else {
                return "Premium активна"
            }
        case .free:
            return "У вас бесплатный тариф"
        case .expired:
            return "Подписка истекла. Продлите, чтобы продолжить пользоваться Premium."
        case .error(let msg):
            return msg
        case .unknown:
            return "Загрузка статуса подписки…"
        }
    }
}

extension SubscriptionManager {
    func analytics_trackPurchase() {
        AppLogger.subscription.notice("User tapped purchase")
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        }
    }
}

struct PlanCard: View {
    let product: Product
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
            }
            .padding(16)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

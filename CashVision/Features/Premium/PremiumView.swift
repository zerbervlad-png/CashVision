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
        .onAppear { manager.status == .free ? () : () }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
            Text("CashVision Premium")
                .font(.title2.bold())
            Text("Расширенные возможности для проверки и пересчёта банкнот")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(icon: "infinity", title: "Безлимитная проверка", subtitle: "Сколько угодно сканирований в день")
            FeatureRow(icon: "list.bullet.rectangle", title: "Расширенный пересчёт", subtitle: "Дополнительные валюты и опции")
            FeatureRow(icon: "clock.arrow.circlepath", title: "История операций", subtitle: "Сохранение и экспорт результатов")
            FeatureRow(icon: "checkmark.shield", title: "Расширенная проверка признаков", subtitle: "Дополнительные защитные элементы")
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            if manager.products.isEmpty {
                ProgressView()
            } else {
                ForEach(manager.products, id: \.id) { product in
                    PlanCard(product: product, isPurchasing: false) {
                        Task {
                            manager.analytics_trackPurchase()
                            await manager.purchase(product)
                        }
                    }
                }
            }
        }
    }

    private var restoreSection: some View {
        Button("Восстановить покупки") {
            Task { await manager.restorePurchases() }
        }
        .font(.subheadline)
    }

    private var disclaimerSection: some View {
        VStack(spacing: 8) {
            Text(statusDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            Link("Политика конфиденциальности", destination: URL(string: "https://cashvision.ai/privacy")!)
                .font(.caption)
            Link("Условия использования", destination: URL(string: "https://cashvision.ai/terms")!)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 32)
            VStack(alignment: .leading) {
                Text(title).font(.body.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        }
    }
}

struct PlanCard: View {
    let product: Product
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
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
            .padding()
            .background(.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}

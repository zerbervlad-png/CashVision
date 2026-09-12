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
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 12)
                Image(systemName: "star.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
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
                    PlanCard(
                        product: product,
                        isBestValue: product.id.contains("yearly")
                    ) {
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
    let isBestValue: Bool
    let action: () -> Void

    init(product: Product, isBestValue: Bool = false, action: @escaping () -> Void) {
        self.product = product
        self.isBestValue = isBestValue
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.headline)
                        if isBestValue {
                            Text("Выгодно")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor, in: Capsule())
                        }
                    }
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
            }
            .padding(16)
            .background(
                isBestValue
                    ? Color.accentColor.opacity(0.15)
                    : Color.accentColor.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isBestValue ? Color.accentColor : Color.accentColor.opacity(0.2),
                        lineWidth: isBestValue ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

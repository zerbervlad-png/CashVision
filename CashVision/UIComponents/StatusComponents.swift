import SwiftUI

struct StatusBadgeView: View {
    let status: VerificationStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            StatusRow(label: "Банкнота распознана", done: status.banknoteRecognized)
            StatusRow(label: "Номинал определён", done: status.denominationDetected)
            StatusRow(label: "Визуальные признаки обнаружены", done: status.visualFeaturesDetected)
            StatusRow(label: "Требуется дополнительная проверка", done: status.requiresAdditionalCheck, isWarning: true)
            Text(status.disclaimer)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
}

struct StatusRow: View {
    let label: String
    let done: Bool
    var isWarning: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: done ? (isWarning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill") : "circle")
                .foregroundStyle(done ? (isWarning ? .orange : .green) : .secondary)
            Text(label).font(.subheadline)
            Spacer()
        }
    }
}

struct DisclaimerBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

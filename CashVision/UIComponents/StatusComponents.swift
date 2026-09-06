import SwiftUI

struct StatusBadgeView: View {
    let status: VerificationStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusRow(label: "Банкнота распознана", done: status.banknoteRecognized)
            StatusRow(label: "Номинал определён", done: status.denominationDetected)
            StatusRow(label: "Визуальные признаки обнаружены", done: status.visualFeaturesDetected)
            StatusRow(label: "Требуется дополнительная проверка", done: status.requiresAdditionalCheck, isWarning: true)
        }
    }
}

struct StatusRow: View {
    let label: String
    let done: Bool
    var isWarning: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: done ? (isWarning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill") : "circle")
                .foregroundStyle(done ? (isWarning ? .orange : .green) : .secondary)
                .font(.body)
                .symbolEffect(.bounce, options: .nonRepeating, value: done)
            Text(label)
                .font(.subheadline)
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
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
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

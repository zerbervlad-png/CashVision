import SwiftUI

struct SecurityFeatureSheet: View {
    let feature: SecurityFeature
    let denomination: Denomination
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.largeTitle)
                            .foregroundStyle(.accent)
                            .frame(width: 48, height: 48)
                            .background(.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(.title3.bold())
                            Text(denomination.formatted)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    Text(feature.shortDescription)
                        .font(.body)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Как проверить")
                            .font(.headline)
                        ForEach(Array(feature.instructions.enumerated()), id: \.offset) { idx, instruction in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(idx + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(.accent, in: Circle())
                                Text(instruction)
                                    .font(.subheadline)
                            }
                        }
                    }

                    HStack {
                        ForEach(feature.checkMethods, id: \.self) { method in
                            Text(methodText(method))
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.quaternary, in: Capsule())
                        }
                    }

                    DisclaimerBanner(text: VerificationStatus.notGuaranteeDisclaimer)
                }
                .padding()
            }
            .navigationTitle("Защитный признак")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .bold()
                }
            }
        }
    }

    private var icon: String {
        switch feature.type {
        case .watermark: return "drop.fill"
        case .securityThread: return "minus.dash"
        case .microperforation: return "circle.dashed"
        case .relief: return "hand.point.up.left.fill"
        case .holographic, .kinematicElement: return "sparkles"
        case .protectiveFibers: return "scribble"
        case .uvFeature: return "lightbulb.fill"
        case .irFeature: return "thermometer.sun.fill"
        case .latentImage: return "eye.fill"
        case .microtext: return "magnifyingglass"
        case .magneticInk: return "magnet"
        }
    }

    private func methodText(_ method: SecurityCheckMethod) -> String {
        switch method {
        case .onLight: return "На просвет"
        case .onAngle: return "Под углом"
        case .onTouch: return "На ощупь"
        case .withUV: return "УФ-свет"
        case .withIR: return "ИК-свет"
        case .withMagnifier: return "С лупой"
        }
    }
}

import SwiftUI

struct SecurityFeatureSheet: View {
    let feature: SecurityFeature
    let denomination: Denomination
    let officialSourceURL: URL?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    init(feature: SecurityFeature, denomination: Denomination, officialSourceURL: URL? = nil) {
        self.feature = feature
        self.denomination = denomination
        self.officialSourceURL = officialSourceURL
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 48, height: 48)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
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
                                    .background(Color.accentColor, in: Circle())
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

                    if let url = officialSourceURL {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Источник данных")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Button {
                                openURL(url)
                            } label: {
                                Label("Банк России — cbr.ru", systemImage: "building.columns")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 8)
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

    private var icon: String { Self.icon(for: feature.type) }

    static func icon(for type: SecurityCheckType) -> String {
        switch type {
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

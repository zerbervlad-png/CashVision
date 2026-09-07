import SwiftUI
import AVFoundation
import Observation

@MainActor
@Observable
final class CheckViewModel {
    let container: AppContainer
    private(set) var status: RecognitionStatus = .idle
    private(set) var recognized: [RecognizedBanknote] = []
    private(set) var verification: VerificationStatus = .initial
    private(set) var permissionState: CameraService.Status = .notDetermined
    private(set) var selectedFeature: SecurityFeature?
    private(set) var selectedBanknote: RecognizedBanknote?

    init(container: AppContainer) {
        self.container = container
    }

    func bootstrap() async {
        let perm = await container.cameraService.checkPermission()
        permissionState = perm
        if perm == .notDetermined {
            permissionState = await container.cameraService.requestPermission() ? .ready : .unauthorized
        }
        if permissionState == .ready {
            await container.cameraService.configure()
            container.cameraService.start()
            container.analytics.track(.init(name: .cameraStarted))
        }
    }

    func handlePermissionDenied() {
        permissionState = .unauthorized
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func updateRecognition(_ result: RecognitionResult?) {
        guard let result else {
            status = .idle
            recognized = []
            return
        }
        recognized = result.banknotes
        if result.banknotes.isEmpty {
            status = result.quality.issues.contains(.lowLight) ? .lowQuality : .noBanknote
        } else if result.banknotes.count > 1 {
            status = .multipleBanknotes(result.banknotes.count)
        } else {
            let banknote = result.banknotes[0]
            status = .banknoteRecognized
            verification = container.makeVerificationService().evaluate(recognized: banknote)
            container.analytics.track(.init(name: .banknoteDetected, properties: ["denom": banknote.denomination.formatted]))
        }
    }

    func selectFeature(_ feature: SecurityFeature, on banknote: RecognizedBanknote) {
        selectedFeature = feature
        selectedBanknote = banknote
    }

    var topHintText: String {
        switch status {
        case .idle, .scanning: return "Наведите камеру на банкноту"
        case .banknoteRecognized, .denominationDetected, .visualFeaturesDetected:
            if let first = recognized.first {
                return first.denomination.formatted
            }
            return "Банкнота распознана"
        case .additionalVerificationRequired: return "Требуется дополнительная проверка"
        case .noBanknote: return "Банкнота не найдена"
        case .lowQuality: return "Недостаточно света"
        case .multipleBanknotes(let count): return "\(count) банкнот в кадре"
        }
    }

    var topHintIcon: String {
        switch status {
        case .idle, .scanning: return "viewfinder"
        case .banknoteRecognized, .denominationDetected, .visualFeaturesDetected:
            return "checkmark.seal.fill"
        case .additionalVerificationRequired: return "exclamationmark.triangle.fill"
        case .noBanknote: return "questionmark.circle"
        case .lowQuality: return "sun.min"
        case .multipleBanknotes: return "square.stack.3d.up.fill"
        }
    }

    var topHintColor: Color {
        switch status {
        case .idle, .scanning: return .white
        case .banknoteRecognized, .denominationDetected, .visualFeaturesDetected: return .green
        case .additionalVerificationRequired: return .orange
        case .noBanknote: return .white.opacity(0.6)
        case .lowQuality: return .yellow
        case .multipleBanknotes: return .blue
        }
    }
}

extension AppContainer {
    func makeVerificationService() -> BanknoteVerificationService {
        BanknoteVerificationService(serialProvider: serialVerificationProvider)
    }
}

struct CheckView: View {
    let container: AppContainer
    @State private var viewModel: CheckViewModel
    @State private var showSheet = false
    @State private var showStatusPanel = true

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: CheckViewModel(container: container))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.permissionState {
            case .unauthorized:
                CameraPermissionView(onOpenSettings: { viewModel.openSettings() })
            case .notDetermined:
                ProgressView("Запрашиваем доступ к камере…")
                    .tint(.white)
                    .foregroundStyle(.white)
            default:
                cameraContent
            }
        }
        .task {
            await viewModel.bootstrap()
        }
        .onAppear {
            container.analytics.track(.init(name: .appOpen))
        }
        .onDisappear {
            container.cameraService.stop()
        }
        .sheet(isPresented: $showSheet) {
            if let feature = viewModel.selectedFeature, let banknote = viewModel.selectedBanknote {
                SecurityFeatureSheet(feature: feature, denomination: banknote.denomination)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
            }
        }
    }

    @ViewBuilder
    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(session: container.cameraService.captureSession)
                .ignoresSafeArea()

            BanknoteOverlayView(recognized: viewModel.recognized) { banknote, feature in
                viewModel.selectFeature(feature, on: banknote)
                showSheet = true
            }
            .allowsHitTesting(!viewModel.recognized.isEmpty)

            VStack {
                topHint

                Spacer()

                if !viewModel.recognized.isEmpty && showStatusPanel {
                    statusPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !viewModel.recognized.isEmpty {
                    disclaimerBanner
                        .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .animation(.cashSpring, value: viewModel.status)
        }
    }

    private var topHint: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.topHintIcon)
                .font(.title3)
                .foregroundStyle(viewModel.topHintColor)
                .symbolEffect(.pulse, options: .repeating, value: viewModel.status)

            Text(viewModel.topHintText)
                .font(.headline)
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.cashSpring, value: viewModel.topHintText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .adaptiveGlassBackground(cornerRadius: 24)
        .padding(.top, 8)
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Статус проверки")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Button {
                    withAnimation(.cashSpring) {
                        showStatusPanel.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            StatusBadgeView(status: viewModel.verification)
        }
        .padding(16)
        .adaptiveGlassBackground(cornerRadius: 20)
    }

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
            Text("Не является гарантией подлинности")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .adaptiveGlassBackground(cornerRadius: 12)
    }
}

struct CameraPermissionView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 8) {
                Text("Камера недоступна")
                    .font(.title2.bold())
                Text("CashVision использует камеру для распознавания банкнот. Изображения обрабатываются локально и не покидают устройство.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }

            Button(action: onOpenSettings) {
                Label("Открыть Настройки", systemImage: "gear")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

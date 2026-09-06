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

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initializedValue: CheckViewModel(container: container))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.permissionState {
            case .unauthorized:
                CameraPermissionView(onOpenSettings: { viewModel.openSettings() })
            case .notDetermined:
                ProgressView("Запрашиваем доступ к камере…")
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
            }
        }
    }

    @ViewBuilder
    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(session: container.cameraService.captureSession)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Text(viewModel.topHintText)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 16)

                if !viewModel.recognized.isEmpty {
                    StatusBadgeView(status: viewModel.verification)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }

            BanknoteOverlayView(recognized: viewModel.recognized) { banknote, feature in
                viewModel.selectFeature(feature, on: banknote)
                showSheet = true
            }
            .allowsHitTesting(!viewModel.recognized.isEmpty)
        }
    }
}

struct CameraPermissionView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Камера недоступна")
                .font(.title2.bold())
            Text("CashVision использует камеру для распознавания банкнот. Изображения не покидают устройство.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            Button("Открыть Настройки", action: onOpenSettings)
                .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(.white)
    }
}

import Foundation
import SwiftUI
import Observation

/// DEBUG-режим для эмуляции различных состояний.
/// Активируется переменной окружения `CASHVISION_DEBUG=1` или `#if DEBUG`.
@MainActor
@Observable
final class TestModeController {
    enum Emulation {
        case disabled
        case testBanknote5000
        case testBanknote1000
        case testBanknote500
        case emulateBadCamera
        case emulateServerFailure
        case emulateSubscription
        case emulateOffline
        case emulateAPITimeout
    }

    var activeEmulation: Emulation = .disabled
    let isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func emulateTestBanknote(_ denomination: Denomination) {
        guard isEnabled else { return }
        switch denomination.value {
        case 5000: activeEmulation = .testBanknote5000
        case 1000: activeEmulation = .testBanknote1000
        case 500:  activeEmulation = .testBanknote500
        default: activeEmulation = .disabled
        }
    }

    func emulateBadCamera() {
        guard isEnabled else { return }
        activeEmulation = .emulateBadCamera
    }

    func emulateServerFailure() {
        guard isEnabled else { return }
        activeEmulation = .emulateServerFailure
    }

    func emulateSubscription() {
        guard isEnabled else { return }
        activeEmulation = .emulateSubscription
    }

    func emulateOffline() {
        guard isEnabled else { return }
        activeEmulation = .emulateOffline
    }

    func emulateAPITimeout() {
        guard isEnabled else { return }
        activeEmulation = .emulateAPITimeout
    }

    func reset() {
        activeEmulation = .disabled
    }

    func makeTestResult() -> RecognitionResult? {
        switch activeEmulation {
        case .testBanknote5000:
            return RecognitionResult(
                banknotes: [
                    RecognizedBanknote(
                        denomination: .rub5000,
                        boundingBox: NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                        confidence: 0.95,
                        qualityScore: 0.95
                    )
                ],
                quality: BanknoteQualityAssessment(overallScore: 0.95, issues: []),
                timestamp: Date()
            )
        case .testBanknote1000:
            return RecognitionResult(
                banknotes: [
                    RecognizedBanknote(
                        denomination: .rub1000,
                        boundingBox: NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                        confidence: 0.92,
                        qualityScore: 0.9
                    )
                ],
                quality: BanknoteQualityAssessment(overallScore: 0.9, issues: []),
                timestamp: Date()
            )
        case .testBanknote500:
            return RecognitionResult(
                banknotes: [
                    RecognizedBanknote(
                        denomination: .rub500,
                        boundingBox: NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                        confidence: 0.9,
                        qualityScore: 0.9
                    )
                ],
                quality: BanknoteQualityAssessment(overallScore: 0.9, issues: []),
                timestamp: Date()
            )
        case .emulateBadCamera:
            return RecognitionResult(
                banknotes: [],
                quality: BanknoteQualityAssessment(overallScore: 0.2, issues: [.lowLight, .blurry]),
                timestamp: Date()
            )
        case .disabled, .emulateServerFailure, .emulateSubscription, .emulateOffline, .emulateAPITimeout:
            return nil
        }
    }
}

#if DEBUG
struct TestModeView: View {
    @State var controller: TestModeController

    var body: some View {
        NavigationStack {
            List {
                Section("Эмуляция распознавания") {
                    Button("5000 ₽") { controller.emulateTestBanknote(.rub5000) }
                    Button("1000 ₽") { controller.emulateTestBanknote(.rub1000) }
                    Button("500 ₽") { controller.emulateTestBanknote(.rub500) }
                }
                Section("Эмуляция ошибок") {
                    Button("Плохая камера") { controller.emulateBadCamera() }
                    Button("Сервер недоступен") { controller.emulateServerFailure() }
                    Button("Offline") { controller.emulateOffline() }
                    Button("API timeout") { controller.emulateAPITimeout() }
                }
                Section("Эмуляция подписки") {
                    Button("Premium active") { controller.emulateSubscription() }
                }
                Section {
                    Button("Сбросить", role: .destructive) { controller.reset() }
                }
            }
            .navigationTitle("Test Mode (DEBUG)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif

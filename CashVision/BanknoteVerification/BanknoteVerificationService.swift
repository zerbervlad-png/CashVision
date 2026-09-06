import Foundation
import Observation

@MainActor
@Observable
final class BanknoteVerificationService {
    private let serialProvider: BanknoteSerialVerificationProvider

    init(serialProvider: BanknoteSerialVerificationProvider) {
        self.serialProvider = serialProvider
    }

    /// Вычисляет статус проверки банкноты по результатам распознавания.
    func evaluate(recognized: RecognizedBanknote?) -> VerificationStatus {
        guard let banknote = recognized, banknote.confidence >= 0.5 else {
            return VerificationStatus(
                banknoteRecognized: false,
                denominationDetected: false,
                visualFeaturesDetected: false,
                requiresAdditionalCheck: true,
                disclaimer: VerificationStatus.notGuaranteeDisclaimer
            )
        }
        let banknoteRecognized = banknote.confidence >= 0.5
        let denominationDetected = banknoteRecognized && banknote.denomination.value > 0
        let visualFeaturesDetected = denominationDetected && (banknote.definition?.securityFeatures.isEmpty == false)
        return VerificationStatus(
            banknoteRecognized: banknoteRecognized,
            denominationDetected: denominationDetected,
            visualFeaturesDetected: visualFeaturesDetected,
            requiresAdditionalCheck: true,
            disclaimer: VerificationStatus.notGuaranteeDisclaimer
        )
    }

    func verifySerial(_ serial: String) async -> SerialVerificationResult {
        do {
            return try await serialProvider.checkSerialNumber(serial)
        } catch {
            return SerialVerificationResult(
                serial: serial,
                status: .noOfficialSource,
                source: "Ошибка запроса",
                timestamp: Date(),
                message: "Проверка по внешней базе недоступна"
            )
        }
    }

    var disclaimer: String { VerificationStatus.notGuaranteeDisclaimer }
}

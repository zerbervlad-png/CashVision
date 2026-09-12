import Foundation

enum DemoRecognitionHelper {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    static var isDemoAvailable: Bool {
        #if DEBUG
        return true
        #else
        return isSimulator
        #endif
    }

    static func makeResult(for denomination: Denomination) -> RecognitionResult {
        let definition = RubBanknotesDataset.allBanknotes.first {
            $0.currency == denomination.currency && $0.denominationValue == denomination.value
        }
        let banknote = RecognizedBanknote(
            denomination: denomination,
            side: .front,
            orientation: .up,
            boundingBox: NormalizedRect(x: 0.1, y: 0.15, width: 0.8, height: 0.7),
            confidence: 0.95,
            qualityScore: 0.95,
            isPartial: false,
            definition: definition
        )
        return RecognitionResult(
            banknotes: [banknote],
            quality: BanknoteQualityAssessment(overallScore: 0.95, issues: []),
            timestamp: Date()
        )
    }

    static var availableDenominations: [Denomination] {
        RubBanknotesDataset.allBanknotes
            .sorted { $0.denominationValue > $1.denominationValue }
            .map { $0.denomination }
    }
}

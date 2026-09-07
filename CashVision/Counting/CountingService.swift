import Foundation
import CoreGraphics
import Observation

@MainActor
@Observable
final class CountingService {
    private let recognition: BanknoteRecognitionService
    private let tracker: BanknoteTracker

    private(set) var counted: [Denomination: Int] = [:]
    private(set) var totalCount: Int = 0
    private(set) var totalAmount: Int = 0
    private(set) var isCounting = false

    init(recognition: BanknoteRecognitionService, tracker: BanknoteTracker? = nil) {
        self.recognition = recognition
        self.tracker = tracker ?? BanknoteTracker()
    }

    func startCounting() {
        guard !isCounting else { return }
        isCounting = true
        counted.removeAll()
        totalCount = 0
        totalAmount = 0
        tracker.reset()
    }

    func stopCounting() {
        isCounting = false
    }

    func update(with result: RecognitionResult) {
        guard isCounting else { return }
        var newOnes: [RecognizedBanknote] = []
        for banknote in result.banknotes where banknote.confidence >= 0.6 {
            if tracker.track(banknote) == .newCounted {
                newOnes.append(banknote)
            }
        }
        for new in newOnes {
            counted[new.denomination, default: 0] += 1
            totalCount += 1
            totalAmount += new.denomination.value
        }
    }

    func increment(denomination: Denomination, by amount: Int = 1) {
        counted[denomination, default: 0] += amount
        if amount > 0 {
            totalCount += amount
            totalAmount += denomination.value * amount
        } else if amount < 0 {
            let current = counted[denomination, default: 0]
            let new = max(0, current + amount)
            let diff = current - new
            counted[denomination] = new
            if new == 0 { counted.removeValue(forKey: denomination) }
            totalCount = max(0, totalCount - diff)
            totalAmount = max(0, totalAmount - denomination.value * diff)
        }
    }

    func setCount(_ value: Int, for denomination: Denomination) {
        let current = counted[denomination, default: 0]
        let diff = value - current
        counted[denomination] = value
        if value == 0 { counted.removeValue(forKey: denomination) }
        totalCount = max(0, totalCount + diff)
        totalAmount = max(0, totalAmount + denomination.value * diff)
    }

    func clear() {
        counted.removeAll()
        totalCount = 0
        totalAmount = 0
        tracker.reset()
    }
}

import Foundation
import UIKit

@MainActor
enum HapticFeedback {
    static func notify(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func denominationPattern(rank: Int) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        for _ in 0..<max(1, min(rank, 5)) {
            generator.impactOccurred()
            Thread.sleep(forTimeInterval: 0.12)
        }
    }
}

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class SettingsStore {
    var onboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingCompleted") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingCompleted") }
    }

    var preferredColorScheme: AppColorScheme {
        get {
            AppColorScheme(rawValue: UserDefaults.standard.integer(forKey: "colorScheme")) ?? .system
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "colorScheme") }
    }

    var reduceMotion: Bool {
        get { UserDefaults.standard.bool(forKey: "reduceMotion") }
        set { UserDefaults.standard.set(newValue, forKey: "reduceMotion") }
    }

    var saveResultsToPhotos: Bool {
        get { UserDefaults.standard.bool(forKey: "saveResultsToPhotos") }
        set { UserDefaults.standard.set(newValue, forKey: "saveResultsToPhotos") }
    }

    var allowAnalytics: Bool {
        get { UserDefaults.standard.object(forKey: "allowAnalytics") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "allowAnalytics") }
    }

    var hapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }

    var autoTorchInLowLight: Bool {
        get { UserDefaults.standard.object(forKey: "autoTorch") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "autoTorch") }
    }

    var lastUsedMode: String {
        get { UserDefaults.standard.string(forKey: "lastMode") ?? "check" }
        set { UserDefaults.standard.set(newValue, forKey: "lastMode") }
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: "colorScheme")
        UserDefaults.standard.removeObject(forKey: "reduceMotion")
        UserDefaults.standard.removeObject(forKey: "saveResultsToPhotos")
        UserDefaults.standard.removeObject(forKey: "hapticsEnabled")
        UserDefaults.standard.removeObject(forKey: "autoTorch")
    }
}

enum AppColorScheme: Int, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "Системная"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }
}

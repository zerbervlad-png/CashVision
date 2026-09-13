import SwiftUI
import Observation

@main
struct CashVisionApp: App {
    @State private var appContainer: AppContainer

    init() {
        AppLogger.bootstrap()
        if CommandLine.arguments.contains("-UITestsFresh") {
            UserDefaults.standard.removeObject(forKey: "onboardingCompleted")
        }
        _appContainer = State(initialValue: AppContainer())
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: appContainer)
                .tint(.accentColor)
                .preferredColorScheme(appContainer.settings.preferredColorScheme.colorSchemeValue)
                .environment(appContainer.subscription)
                .environment(appContainer.history)
                .environment(appContainer.settings)
        }
    }
}

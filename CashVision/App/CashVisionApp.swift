import SwiftUI
import Observation

@main
struct CashVisionApp: App {
    @State private var appContainer: AppContainer

    init() {
        AppLogger.bootstrap()
        _appContainer = State(initializedValue: AppContainer())
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: appContainer)
                .preferredColorScheme(nil)
                .environment(appContainer.subscription)
                .environment(appContainer.history)
                .environment(appContainer.settings)
        }
    }
}

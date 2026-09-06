import SwiftUI
import Observation

struct RootView: View {
    let container: AppContainer
    @State private var showOnboarding: Bool
    @State private var selectedTab: AppTab = .check

    init(container: AppContainer) {
        self.container = container
        _showOnboarding = State(initialValue: !container.settings.onboardingCompleted)
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingFlow {
                    container.settings.onboardingCompleted = true
                    showOnboarding = false
                }
            } else {
                MainTabView(container: container, selectedTab: $selectedTab)
            }
        }
    }
}

enum AppTab: Hashable {
    case check, count, history, premium
}

struct MainTabView: View {
    let container: AppContainer
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            CheckView(container: container)
                .tabItem { Label("Проверить", systemImage: "viewfinder") }
                .tag(AppTab.check)

            CountView(container: container)
                .tabItem { Label("Посчитать", systemImage: "plus.app") }
                .tag(AppTab.count)

            HistoryView(viewModel: container.history)
                .tabItem { Label("История", systemImage: "clock.arrow.circlepath") }
                .tag(AppTab.history)

            PremiumView(manager: container.subscription)
                .tabItem { Label("Premium", systemImage: "crown") }
                .tag(AppTab.premium)
        }
    }
}

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
                    withAnimation(.cashSpring) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                MainTabView(container: container, selectedTab: $selectedTab)
                    .transition(.opacity)
            }
        }
        .animation(.cashSpring, value: showOnboarding)
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
            Tab("Проверить", systemImage: "viewfinder", value: AppTab.check) {
                CheckView(container: container)
            }

            Tab("Посчитать", systemImage: "plus.app", value: AppTab.count) {
                CountView(container: container)
            }

            Tab("История", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView(viewModel: container.history)
            }

            Tab("Premium", systemImage: "crown", value: AppTab.premium) {
                PremiumView(manager: container.subscription)
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            container.settings.lastUsedMode = newValue == .check ? "check" : newValue == .count ? "count" : "other"
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}

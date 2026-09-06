import SwiftUI

struct OnboardingFlow: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "viewfinder",
            title: "Распознавание банкнот",
            subtitle: "Наведите камеру на банкноту — CashVision определит номинал и покажет защитные признаки"
        ),
        OnboardingPage(
            icon: "plus.app",
            title: "Пересчёт наличных",
            subtitle: "Считайте несколько банкнот подряд. Приложение само исключит дубликаты"
        ),
        OnboardingPage(
            icon: "lock.shield",
            title: "Приватность",
            subtitle: "Изображения не покидают ваше устройство. Проверка — офлайн"
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                    OnboardingPageView(page: page).tag(idx)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Начать" : "Далее") {
                    if page == pages.count - 1 {
                        onFinish()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Пропустить") { onFinish() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(.accent)
            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(page.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 32)
    }
}

import SwiftUI

extension View {
    /// Glass-эффект для overlay-элементов (совместимый fallback).
    @ViewBuilder
    func glassOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        self.background(
            content()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
    }

    /// Адаптивный glass-фон для bottom sheets и overlays.
    @ViewBuilder
    func adaptiveGlassBackground(cornerRadius: CGFloat = 16) -> some View {
        self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Shimmer-эффект для loading-состояний.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 1.5)
                    .offset(x: phase * geo.size.width * 1.5)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Плавная spring-анимация.
extension Animation {
    static var cashSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
    }

    static var cashBouncy: Animation {
        .spring(response: 0.5, dampingFraction: 0.6)
    }
}

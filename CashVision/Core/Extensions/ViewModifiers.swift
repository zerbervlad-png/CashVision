import SwiftUI

extension View {
    /// iOS 26 Liquid Glass эффект для overlay-элементов.
    @ViewBuilder
    func glassOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26.0, *) {
            self.background(
                content()
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
            )
        } else {
            self.background(
                content()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            )
        }
    }

    /// Адаптивный glass-фон для bottom sheets и overlays.
    @ViewBuilder
    func adaptiveGlassBackground(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26.0, *) {
            self.background(
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            )
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

/// Современный shimmer-эффект для loading-состояний.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @State private var animation: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 1.5)
                    .offset(x: phase * geo.size.width * 1.5)
                    .onAppear {
                        phase = -1
                        withAnimation(animation) {
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

/// Плавная spring-анимация для iOS 26.
extension Animation {
    static var cashSpring: Animation {
        if #available(iOS 26.0, *) {
            .smooth(duration: 0.4, extraBounce: 0.15)
        } else {
            .spring(response: 0.4, dampingFraction: 0.75)
        }
    }

    static var cashBouncy: Animation {
        if #available(iOS 26.0, *) {
            .bouncy(duration: 0.5, extraBounce: 0.3)
        } else {
            .spring(response: 0.5, dampingFraction: 0.6)
        }
    }
}

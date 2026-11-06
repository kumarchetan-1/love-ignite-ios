import SwiftUI

struct NeonCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(scheme == .dark
                          ? AnyShapeStyle(Color.white.opacity(0.06))
                          : AnyShapeStyle(Color.white.opacity(0.78)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                ThemePalette.neonGreen.opacity(scheme == .dark ? 0.55 : 0.4),
                                ThemePalette.neonPurple.opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func neonCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(NeonCardModifier(cornerRadius: cornerRadius))
    }
}

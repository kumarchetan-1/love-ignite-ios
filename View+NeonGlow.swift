import SwiftUI

/// A convenience modifier to add a neon-like glow to any SwiftUI view.
///
/// Usage:
/// ```swift
/// Image(systemName: "heart.fill")
///     .foregroundStyle(.pink)
///     .neonGlow(.pink, radius: 10)
/// ```
public extension View {
    /// Applies a neon glow effect around the view using the provided color.
    /// - Parameters:
    ///   - color: The glow color.
    ///   - radius: The base blur/shadow radius used to build the glow. Defaults to 8.
    /// - Returns: A view with a neon-like glow.
    func neonGlow(_ color: Color, radius: CGFloat = 8) -> some View {
        self
            // Base subtle shadow
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            // Stronger outer glow via multiple stacked shadows
            .shadow(color: color.opacity(0.35), radius: radius * 1.8, x: 0, y: 0)
            .shadow(color: color.opacity(0.25), radius: radius * 3.0, x: 0, y: 0)
            // Overlay a blurred stroke of the shape to intensify the glow near edges
            .overlay(
                self
                    .blendMode(.plusLighter)
                    .shadow(color: color.opacity(0.8), radius: radius * 0.8, x: 0, y: 0)
                    .mask(self)
            )
    }
}

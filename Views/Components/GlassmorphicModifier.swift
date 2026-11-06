import SwiftUI

// Glassmorphism effect modifier based on the article
struct GlassmorphicModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.2
    var borderOpacity: Double = 0.4
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Blur effect using Material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .background(.ultraThinMaterial)
                    
                    // Translucent white overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(scheme == .dark ? opacity * 0.5 : opacity))
                    
                    // Soft border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(borderOpacity),
                                    Color.white.opacity(borderOpacity * 0.5),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// Extension for easy use
extension View {
    func glassmorphic(cornerRadius: CGFloat = 20, opacity: Double = 0.2, borderOpacity: Double = 0.4) -> some View {
        modifier(GlassmorphicModifier(cornerRadius: cornerRadius, opacity: opacity, borderOpacity: borderOpacity))
    }
}

// Reusable Glassmorphic Card component
struct GlassmorphicCard<Content: View>: View {
    let cornerRadius: CGFloat
    let opacity: Double
    let borderOpacity: Double
    let content: Content
    
    @Environment(\.colorScheme) private var scheme
    
    init(
        cornerRadius: CGFloat = 20,
        opacity: Double = 0.2,
        borderOpacity: Double = 0.4,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.borderOpacity = borderOpacity
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Blur effect
            RoundedRectangle(cornerRadius: cornerRadius)
                .background(.ultraThinMaterial)
            
            // Translucent overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(scheme == .dark ? opacity * 0.5 : opacity))
            
            // Soft border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(borderOpacity),
                            Color.white.opacity(borderOpacity * 0.5),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            content
        }
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

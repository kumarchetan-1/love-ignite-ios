import SwiftUI

struct AchievementToast: View {
    let achievement: Achievement
    @Environment(\.colorScheme) private var scheme
    
    // Simple sparkle pulse
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Full-screen sparkle layer
            FullScreenSparkles()
                .allowsHitTesting(false)
            
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                        .shadow(color: .orange.opacity(0.45), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animate ? 1.1 : 0.95)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
                }
                
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement Unlocked")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(scheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
                
                Text(achievement.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        scheme == .dark ?
                            LinearGradient(colors: [.white, .yellow.opacity(0.9)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.pink, Color.purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .lineLimit(1)
            }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(scheme == .light ? Color.white : Color.black.opacity(0.85)) // opaque background for clarity
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(LinearGradient(colors: [.yellow.opacity(0.6), .orange.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
            )
            .padding(.horizontal, 16)
            .onAppear { animate = true }
        }
    }
}

// Full-screen sparkles made of multiple sparkle fields layered
private struct FullScreenSparkles: View {
    var body: some View {
        ZStack {
            SparkleLayer(count: 22, maxOffset: 200, maxSize: 6, duration: 1.4)
            SparkleLayer(count: 18, maxOffset: 220, maxSize: 8, duration: 1.8)
            SparkleLayer(count: 14, maxOffset: 240, maxSize: 10, duration: 2.2)
        }
    }
}

private struct SparkleLayer: View {
    @State private var animate = false
    
    let count: Int
    let maxOffset: CGFloat
    let maxSize: CGFloat
    let duration: Double
    
    private var sparkles: [Sparkle] {
        (0..<count).map { idx in
            Sparkle(id: idx,
                    x: Double.random(in: -maxOffset...maxOffset),
                    y: Double.random(in: -maxOffset...maxOffset),
                    size: Double.random(in: 3...maxSize),
                    delay: Double.random(in: 0...0.8))
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(sparkles) { sparkle in
                    Circle()
                        .fill(LinearGradient(colors: [.white.opacity(0.95), .yellow.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        .frame(width: sparkle.size, height: sparkle.size)
                        .position(
                            x: proxy.size.width / 2 + sparkle.x,
                            y: proxy.size.height / 2 + sparkle.y
                        )
                        .scaleEffect(animate ? 1.8 : 1.0)
                        .opacity(animate ? 0.0 : 0.9)
                        .animation(
                            .easeOut(duration: duration)
                                .repeatForever(autoreverses: false)
                                .delay(sparkle.delay),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
        }
        .ignoresSafeArea()
    }
}

private struct Sparkle: Identifiable {
    let id: Int
    let x: Double
    let y: Double
    let size: Double
    let delay: Double
}


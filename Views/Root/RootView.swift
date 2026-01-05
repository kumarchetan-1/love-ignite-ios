import SwiftUI

struct RootView: View {
    @EnvironmentObject var posterVM: PosterViewModel
    @State private var selection = 0
    @Namespace private var ns
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // background gradient respecting theme
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: scheme)), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // --- MAIN CONTENT (Full Screen) ---
                VStack(spacing: 0) {
                    if selection == 0 {
                        PosterGridView()
                            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    } else if selection == 1 {
                        AchievementsView()
                            .transition(.opacity)
                    } else {
                        SettingsView()
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)

                // --- FLOATING GLASS TAB BAR ---
                VStack {
                        Spacer()
                    
                    HStack(spacing: 0) {
                        TabButton(icon: "square.grid.3x3.fill", title: "Poster", selected: selection == 0, namespace: ns) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 0 }
                        }
                        
                        TabButton(icon: "star.fill", title: "Medal", selected: selection == 1, namespace: ns) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 1 }
                        }
                        
                        TabButton(icon: "gearshape.fill", title: "More", selected: selection == 2, namespace: ns) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 2 }
                        }
                    }
                    .frame(width: 260)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(.ultraThinMaterial)
                            
                            Capsule()
                                .fill(Color.white.opacity(scheme == .dark ? 0.05 : 0.03))
                            
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(scheme == .dark ? 0.3 : 0.6),
                                            .white.opacity(0.1),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10)
                    // Ensure it floats above the home bar
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 5 : 20)
                    .contentShape(Rectangle()) // Make the 260pt area hittable
                }
                // This VStack is 100% width but we want touches to pass through the empty sides
                .allowsHitTesting(true) 
                
                // Overlays (Toasts & Confetti)
                if posterVM.showConfetti {
                    ConfettiEmitter()
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
                
                if let unlocked = posterVM.recentlyUnlocked {
                        AchievementToast(achievement: unlocked)
                            .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: posterVM.recentlyUnlocked)
                }
            }
        }
        .ignoresSafeArea()
    }
}

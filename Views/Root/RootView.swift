import SwiftUI

struct RootView: View {
    @EnvironmentObject var posterVM: PosterViewModel
    @State private var selection: Int? = 0
    @Namespace private var ns
    @Environment(\.colorScheme) private var scheme

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // background gradient respecting theme
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: self.scheme)), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                if isIPad {
                    // --- IPAD SPLIT VIEW LAYOUT ---
                    NavigationSplitView {
                        List(selection: $selection) {
                            Label("Poster", systemImage: "square.grid.3x3.fill")
                                .tag(0)
                            Label("Medals", systemImage: "star.fill")
                                .tag(1)
                            Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                                .tag(3)
                            Label("Settings", systemImage: "gearshape.fill")
                                .tag(2)
                        }
                        .navigationTitle("Love Ignite")
                        .scrollContentBackground(.hidden)
                        .background(
                            LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: self.scheme)), startPoint: .top, endPoint: .bottom)
                                .ignoresSafeArea()
                        )
                    } detail: {
                        ZStack {
                            LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: self.scheme)), startPoint: .top, endPoint: .bottom)
                                .ignoresSafeArea()
                            
                            switch selection {
                            case 0:
                                PosterGridView()
                            case 1:
                                AchievementsView()
                            case 3:
                                ChatRootView()
                            case 2:
                                SettingsView()
                            default:
                                PosterGridView()
                            }
                        }
                        .ignoresSafeArea()
                    }
                } else {
                    // --- IPHONE LAYOUT (Original) ---
                    VStack(spacing: 0) {
                        if selection == 0 {
                            PosterGridView()
                                .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                        } else if selection == 1 {
                            AchievementsView()
                                .transition(.opacity)
                        } else if selection == 3 {
                            ChatRootView()
                                .transition(.opacity)
                        } else {
                            SettingsView()
                        }
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                }

                // --- FLOATING GLASS TAB BAR (Common or adjusted for iPad) ---
                VStack {
                    Spacer()
                    
                    HStack(spacing: 0) {
                        TabButton(icon: "square.grid.3x3.fill", title: "Poster", selected: selection == 0, namespace: ns) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 0 }
                        }
                        
                        TabButton(icon: "star.fill", title: "Medal", selected: selection == 1, namespace: ns) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 1 }
                        }

                        TabButton(icon: "bubble.left.and.bubble.right.fill", title: "Chat", selected: selection == 3, namespace: ns) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 3 }
                        }
                        
                        TabButton(icon: "gearshape.fill", title: "More", selected: selection == 2, namespace: ns) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 2 }
                        }
                    }
                    .frame(width: isIPad ? 560 : 320)
                    .padding(.vertical, isIPad ? 18 : 8)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(.ultraThinMaterial)
                            
                            Capsule()
                                .fill(Color.white.opacity(self.scheme == .dark ? 0.05 : 0.03))
                            
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(self.scheme == .dark ? 0.3 : 0.6),
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
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 5 : (isIPad ? 60 : 20))
                    .contentShape(Rectangle())
                }
                .allowsHitTesting(true) 
                
                // Overlays (Toasts & Confetti)
                // ... (keep as is)
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

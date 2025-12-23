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

                VStack(spacing: 0) {
                    Color.clear.frame(height: geometry.safeAreaInsets.top)

                    if selection == 0 {
                        PosterGridView()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.35), value: selection)
                    } else if selection == 1 {
                        AchievementsView()
                            .transition(.opacity)
                    } else {
                        SettingsView()
                    }

                    HStack {
                        TabButton(icon: "square.grid.3x3.fill", title: "Poster", selected: selection == 0, namespace: ns) { selection = 0 }
                        Spacer()
                        TabButton(icon: "star.fill", title: "Achievements", selected: selection == 1, namespace: ns) { selection = 1 }
                        Spacer()
                        TabButton(icon: "gearshape.fill", title: "Settings", selected: selection == 2, namespace: ns) { selection = 2 }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(BlurView(style: .systemUltraThinMaterialDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                    .padding(.horizontal, 12))
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 12)
                }
                
                if posterVM.showConfetti {
                    ConfettiEmitter()
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                
                if let unlocked = posterVM.recentlyUnlocked {
                    ZStack {
                        AchievementToast(achievement: unlocked)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: posterVM.recentlyUnlocked)
                }
            }
        }
        .ignoresSafeArea()
    }
}

import SwiftUI

struct RootView: View {
    @EnvironmentObject var posterVM: PosterViewModel
    @State private var selection = 0

    var body: some View {
        ZStack {
            // background gradient
            LinearGradient(gradient: Gradient(colors: [Color("bg1"), Color("bg2")]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear.frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)

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
                    TabButton(icon: "square.grid.3x3.fill", title: "Poster", selected: selection == 0) { selection = 0 }
                    Spacer()
                    TabButton(icon: "star.fill", title: "Achievements", selected: selection == 1) { selection = 1 }
                    Spacer()
                    TabButton(icon: "gearshape.fill", title: "Settings", selected: selection == 2) { selection = 2 }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(BlurView(style: .systemUltraThinMaterialDark)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .padding(.horizontal, 12))
                .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 12)
            }

            if posterVM.showConfetti {
                ConfettiEmitter()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

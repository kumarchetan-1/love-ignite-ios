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

                // Full-screen content + floating tab bar on iPhone and iPad.
                let sel = selection ?? 0
                ZStack {
                    PosterGridView()
                        .opacity(sel == 0 ? 1 : 0)
                        .allowsHitTesting(sel == 0)

                    MoodTrackerView()
                        .opacity(sel == 1 ? 1 : 0)
                        .allowsHitTesting(sel == 1)

                    CycleTrackerView()
                        .opacity(sel == 2 ? 1 : 0)
                        .allowsHitTesting(sel == 2)

                    SettingsView()
                        .opacity(sel == 3 ? 1 : 0)
                        .allowsHitTesting(sel == 3)
                }
                .ignoresSafeArea(.container, edges: .bottom)

                // --- FLOATING GLASS TAB BAR (Common or adjusted for iPad) ---
                VStack {
                    Spacer()
                        
                        let barWidth = geometry.size.width * 0.90
                        let slotWidth: CGFloat = isIPad ? 112 : 62

                        HStack(spacing: isIPad ? 12 : 6) {
                            TabButton(icon: "square.grid.3x3.fill", title: "Poster", selected: selection == 0, namespace: ns) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 0 }
                            }
                            .frame(width: slotWidth)

                            TabButton(icon: "face.smiling.fill", title: "Mood", selected: selection == 1, namespace: ns) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 1 }
                            }
                            .frame(width: slotWidth)

                            TabButton(icon: "calendar.badge.clock", title: "Cycle", selected: selection == 2, namespace: ns) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 2 }
                            }
                            .frame(width: slotWidth)
                            
                            TabButton(icon: "gearshape.fill", title: "More", selected: selection == 3, namespace: ns) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = 3 }
                            }
                            .frame(width: slotWidth)
                        }
                        .frame(width: isIPad ? min(720, barWidth) : barWidth)
                        // Outer padding inside capsule so tabs never touch edges
                        .padding(.horizontal, isIPad ? 18 : 14)
                        .padding(.vertical, isIPad ? 16 : 10)
                        .background(
                            ZStack {
                                // Blur effect using Material
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                
                                // Translucent white overlay (enhanced glassmorphism)
                                Capsule()
                                    .fill(Color.white.opacity(self.scheme == .dark ? 0.15 : 0.2))
                                
                                // Soft border with gradient
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(self.scheme == .dark ? 0.4 : 0.6),
                                                .white.opacity(self.scheme == .dark ? 0.2 : 0.3),
                                                .clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 5 : (isIPad ? 60 : 20))
                        .contentShape(Rectangle())
                    }
                    .allowsHitTesting(true)

                // (Medals tab removed) — no achievement toasts / confetti overlays here.
            }
        }
        .ignoresSafeArea()
        #if DEBUG
        .onAppear {
            let t = UserDefaults.standard.integer(forKey: "uiTab")
            if t > 0 { selection = t }
        }
        #endif
    }
}

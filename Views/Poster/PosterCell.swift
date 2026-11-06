import SwiftUI

struct PosterCell: View {
    @EnvironmentObject var vm: PosterViewModel
    @Environment(\.colorScheme) private var scheme
    let task: Challenge
    let displayNumber: Int? // Overrides task.number if provided
    let onScratchReveal: () -> Void
    let onOpenTask: () -> Void
    let redactedExplicit: Bool
    @State private var isAnimating = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ZStack {
            // Main Card Background
            let isRevealed = vm.isRevealed(task) && !redactedExplicit
            
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isRevealed ? 
                      LinearGradient(colors: [Color("revealed1"), Color("revealed2")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                      LinearGradient(colors: [Color("cardBg1"), Color("cardBg2")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(self.scheme == .dark ? 0.4 : 0.15), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(self.scheme == .dark ? 0.15 : 0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            if redactedExplicit && vm.isRevealed(task) {
                // Redacted styling
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    VStack(spacing: 6) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Private")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else if isRevealed {
                let neonColor = NeonColors.color(for: task.difficulty)
                Button { 
                    Haptics.selection()
                    onOpenTask()
                } label: {
                    VStack(spacing: isIPad ? 10 : 6) {
                        ZStack {
                            Circle()
                                .fill(neonColor.opacity(0.15))
                                .frame(width: isIPad ? 60 : 36, height: isIPad ? 60 : 36)
                                .blur(radius: 4)
                            
                            do {
                                Image(systemName: iconForCategory(task.category))
                                    .font(.system(size: isIPad ? 32 : 20, weight: .bold))
                                    .foregroundColor(neonColor)
                                    .neonGlow(neonColor)
                            }
                        }
                        
                        Text(shortLabel(for: task))
                            .font(.system(size: isIPad ? 18 : 12, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1, anchor: .center).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.6)),
                    removal: .opacity
                ))
            } else {
                // Scratch Layer
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color("cardBg1"), Color("cardBg2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: isIPad ? 8 : 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: isIPad ? 22 : 14))
                            .foregroundColor(.white.opacity(0.4))
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                        
                        Text("\(displayNumber ?? task.number)")
                            .font(.system(size: isIPad ? 48 : 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
                .onTapGesture {
                    Haptics.impact()
                    onScratchReveal()
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            }
            
            // Lock Overlay
            if false {
                 VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                            .padding(5)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .foregroundColor(.yellow)
                            .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func iconForCategory(_ category: TaskCategory) -> String {
        switch category {
        case .general: return "heart.fill"
        case .locations: return "map.fill"
        case .questions: return "bubble.right.fill"
        case .techniques: return "person.2.wave.2.fill"
        case .extraHot: return "star.fill"
        case .loveQnA: return "questionmark.bubble.fill"
        }
    }
    
    private func shortLabel(for task: Challenge) -> String {
        switch task.category {
        case .extraHot: return "Card"
        case .questions: return "Ask"
        case .locations: return "Go"
        case .loveQnA: return "QnA"
        case .techniques: return "Skill"
        case .general: return "Date"
        }
    }
}

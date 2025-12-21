import SwiftUI

struct PosterCell: View {
    @EnvironmentObject var vm: PosterViewModel
    @EnvironmentObject var store: StoreKitManager
    let task: Challenge
    let onScratchReveal: () -> Void
    let onOpenTask: () -> Void
    let redactedExplicit: Bool
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: 16)
                .fill(vm.isRevealed(task) ? 
                      LinearGradient(colors: [Color("revealed1"), Color("revealed2")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                      LinearGradient(colors: [Color("cardBg1"), Color("cardBg2")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

            let isRevealed = vm.isRevealed(task) && !redactedExplicit
            
            if redactedExplicit && vm.isRevealed(task) {
                // Redacted styling for previously revealed explicit cards
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(.white.opacity(0.8))
                            Text("Hidden for privacy")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
            } else if isRevealed {
                let neonColor = NeonColors.color(for: task.difficulty)
                Button { 
                    Haptics.selection()
                    // lock check: uses the isLocked property now
                    if task.isLocked && !store.hasSubscription {
                        store.showPaywall = true
                        return
                    }
                    onOpenTask()
                } label: {
                    VStack(spacing: 4) {
                        if let img = task.imageName, task.category == .extraHot {
                            Image(img)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(neonColor)
                                .neonGlow(neonColor)
                                .blur(radius: (task.isLocked && !store.hasSubscription) ? 6 : 0)
                        } else {
                            // Icon based on category
                            Image(systemName: iconForCategory(task.category))
                                .font(.system(size: 22))
                                .foregroundColor(neonColor)
                                .neonGlow(neonColor)
                        }
                        
                        // Small label
                        Text(shortLabel(for: task))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1, anchor: .center).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.5)),
                    removal: .opacity
                ))
            } else {
                // Not revealed — show a tap-to-reveal card (single or double tap)
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color("cardBg1"), Color("cardBg2")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Rectangle().stroke(Color.white.opacity(0.08)))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    VStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.system(size: 20))
                            .scaleEffect(isAnimating ? 1.15 : 1.0)
                            .opacity(isAnimating ? 0.8 : 1.0)
                        Text("\(task.number)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .allowsHitTesting(false)
                }
                .onTapGesture {
                    Haptics.impact()
                    onScratchReveal()
                }
                .onTapGesture(count: 2) { // Also allow double tap
                    Haptics.impact()
                    onScratchReveal()
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            }

            // Lock icon overlay for revealed locked items
            if vm.isRevealed(task) && task.isLocked && !store.hasSubscription {
                 VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .foregroundColor(.yellow)
                            .padding(2)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }
    
    private func iconForCategory(_ category: TaskCategory) -> String {
        switch category {
        case .general: return "heart.fill"
        case .locations: return "map.fill"
        case .questions: return "bubble.right.fill"
        case .techniques: return "sparkles"
        case .extraHot: return "flame.fill"
        }
    }
    
    private func shortLabel(for task: Challenge) -> String {
        switch task.category {
        case .extraHot: return "Position"
        case .questions: return "Ask"
        case .locations: return "Go"
        default: return "Task"
        }
    }
}

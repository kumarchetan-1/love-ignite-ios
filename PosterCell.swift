import SwiftUI

struct PosterCell: View {
    @EnvironmentObject var vm: PosterViewModel
    @EnvironmentObject var store: StoreKitManager
    let task: Task
    let onScratchReveal: () -> Void
    let onOpenTask: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(vm.isRevealed(task) ? LinearGradient(colors: [Color("revealed1"), Color("revealed2")], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color("cardBg1"), Color("cardBg2")], startPoint: .top, endPoint: .bottom))
                .frame(height: 90)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))

            if vm.isRevealed(task) {
                let neonColor = NeonColors.color(for: task.difficulty)
                Button { 
                    Haptics.selection()
                    // lock check: extraHot requires subscription
                    if task.category == .extraHot && !store.hasSubscription {
                        store.showPaywall = true // we'll add this published state in StoreKitManager
                        return
                    }
                    onOpenTask()
                } label: {
                    VStack(spacing: 6) {
                        if let img = task.imageName, task.category == .extraHot {
                            Image(img)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 34, height: 34)
                                .foregroundColor(neonColor)
                                .neonGlow(neonColor)
                        } else {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 24))
                                .foregroundColor(neonColor)
                                .neonGlow(neonColor)
                        }
                        Text(task.category.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            } else {
                // not revealed — show scratch overlay; on reveal call vm.reveal
                ScratchUIViewRepresentable {
                    Haptics.impact()
                    onScratchReveal()
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Premium badge for locked extraHot when not revealed (optional small badge)
            if !vm.isRevealed(task) && task.category == .extraHot && !store.hasSubscription {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .padding(8)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                            .foregroundColor(.yellow)
                            .padding(8)
                    }
                    Spacer()
                }
            }
        }
    }
}

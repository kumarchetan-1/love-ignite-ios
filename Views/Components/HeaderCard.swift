import SwiftUI

struct HeaderCard: View {
    let revealedCount: Int
    let total: Int
    @EnvironmentObject var vm: PosterViewModel
    @Environment(\.colorScheme) private var scheme
    
    @State private var showRelockAlert = false
    @State private var showRevealAlert = false
    @State private var selectedDailyTask: Challenge?

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(revealedCount) / Double(total), 1)
    }

    var body: some View {
        ZStack {
            // Modern Floating Card Background with Mesh-like Gradient
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    self.scheme == .dark ?
                        AnyShapeStyle(LinearGradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                        AnyShapeStyle(.ultraThinMaterial)
                )
                .shadow(
                    color: self.scheme == .dark ? .black.opacity(0.4) : Color.pink.opacity(0.1),
                    radius: 25, x: 0, y: 12
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(self.scheme == .dark ? 0.2 : 0.6),
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            VStack(spacing: 20) {
                // Top Row: Title + Progress Ring
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Love Journey")
                            .font(.system(size: isIPad ? 36 : 26, weight: .black, design: .rounded))
                            .foregroundColor(self.scheme == .dark ? .white : Color.pink.opacity(0.9))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(isIPad ? .body : .caption)
                                .foregroundColor(.yellow)
                            Text("\(revealedCount) of \(total) discovered")
                                .font(.system(size: isIPad ? 18 : 14, weight: .bold, design: .rounded))
                                .foregroundColor(self.scheme == .dark ? .white.opacity(0.6) : Color.black.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    // Modern Progress Ring with Glow
                    ZStack {
                        Circle()
                            .stroke(self.scheme == .dark ? Color.white.opacity(0.1) : Color.pink.opacity(0.08), lineWidth: isIPad ? 10 : 8)
                            .frame(width: isIPad ? 80 : 64, height: isIPad ? 80 : 64)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(colors: [.pink, .purple, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: isIPad ? 10 : 8, lineCap: .round)
                            )
                            .frame(width: isIPad ? 80 : 64, height: isIPad ? 80 : 64)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: .pink.opacity(0.5), radius: 6)
                        
                        VStack(spacing: -2) {
                            Text("\(Int(progress * 100))")
                                .font(.system(size: isIPad ? 20 : 16, weight: .black, design: .rounded))
                            Text("%")
                                .font(.system(size: isIPad ? 12 : 10, weight: .bold, design: .rounded))
                                .opacity(0.7)
                        }
                        .foregroundColor(self.scheme == .dark ? .white : .black.opacity(0.8))
                    }
                }
                
                // Refined Action Buttons
                HStack(spacing: isIPad ? 16 : 10) {
                    if revealedCount > 0 {
                        HeaderActionButton(icon: "arrow.counterclockwise", title: "Reset", color: .gray) {
                            showRelockAlert = true
                        }
                    }
                    
                    HeaderActionButton(
                        icon: "eye.fill",
                        title: "Reveal All",
                        color: .purple,
                        isLocked: false
                    ) {
                        showRevealAlert = true
                    }
                }
                .padding(.horizontal, isIPad ? 0 : 2) // Slight padding to prevent edge touching
                .frame(maxWidth: .infinity)

                // --- Daily Tasks Section ---
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Daily Challenges", systemImage: "calendar.badge.clock")
                            .font(.system(size: isIPad ? 22 : 16, weight: .heavy, design: .rounded))
                            .foregroundColor(self.scheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
                        
                        Spacer()
                        
                        Text("TODAY")
                            .font(.system(size: isIPad ? 12 : 10, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: isIPad ? 24 : 16) {
                            ForEach(vm.dailyTasks) { task in
                                DailyTaskCard(task: task)
                                    .onTapGesture {
                                        selectedDailyTask = task
                                        Haptics.selection()
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(24)
        }
        // Alert for Relock
        .alert("Relock All Memories?", isPresented: $showRelockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Relock", role: .destructive) {
                withAnimation {
                    vm.resetProgress()
                }
                Haptics.success()
            }
        } message: {
            Text("This will hide all revealed tasks again. Your achievements will also be reset.")
        }
        // Alert for Reveal All
        .alert("Reveal Everything?", isPresented: $showRevealAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reveal All", role: .none) {
                withAnimation {
                    vm.revealAllTasks()
                }
                Haptics.success()
            }
        } message: {
            Text("This will reveal all hidden tasks at once. Your achievements will also be updated.")
        }
        // Sheet for Daily Task
        .sheet(item: $selectedDailyTask) { task in
            TaskDetailSheet(task: task)
                .presentationDetents([.medium])
        }
    }
}

struct DailyTaskCard: View {
    let task: Challenge
    @Environment(\.colorScheme) private var scheme
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: isIPad ? 40 : 32, height: isIPad ? 40 : 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: isIPad ? 18 : 14))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("NEW")
                    .font(.system(size: isIPad ? 12 : 10, weight: .black))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            Text(task.title)
                .font(.system(size: isIPad ? 18 : 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: isIPad ? 220 : 160, height: isIPad ? 160 : 130)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: self.scheme == .dark ?
                            [Color.purple.opacity(0.8), Color.blue.opacity(0.7)] :
                            [Color.pink.opacity(0.9), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: (self.scheme == .dark ? Color.purple : Color.pink).opacity(0.3),
            radius: 10, x: 0, y: 5
        )
    }
}

struct HeaderActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var isLocked: Bool = false
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isIPad ? 10 : 6) {
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 18 : 14, weight: .bold))
                Text(title)
                    .font(.system(size: isIPad ? 18 : 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isLocked ? (self.scheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5)) : (self.scheme == .dark ? color.opacity(0.9) : color))
            .padding(.vertical, isIPad ? 16 : 12)
            .padding(.horizontal, isIPad ? 12 : 8)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(self.scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )
            .overlay(
                Capsule()
                    .stroke(isLocked ? Color.yellow.opacity(0.3) : color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

import SwiftUI
import StoreKit

struct HeaderCard: View {
    let revealedCount: Int
    let total: Int
    @EnvironmentObject var vm: PosterViewModel
    @EnvironmentObject var store: StoreKitManager
    @Environment(\.colorScheme) private var scheme
    
    @State private var showRelockAlert = false
    @State private var showEraseAlert = false
    @State private var selectedDailyTask: Challenge?

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(revealedCount) / Double(total), 1)
    }

    var body: some View {
        ZStack {
            // Modern Floating Card Background
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    scheme == .dark ?
                        LinearGradient(colors: [Color.black.opacity(0.4), Color.black.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color.white, Color.white.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(
                    color: scheme == .dark ? .black.opacity(0.3) : Color.pink.opacity(0.12),
                    radius: 20, x: 0, y: 10
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            scheme == .dark ?
                                LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.white, Color.pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )

            VStack(spacing: 16) {
                // Top Row: Title + Percentage
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Love Journey")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(scheme == .dark ? .white : Color.pink.opacity(0.9))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("\(revealedCount) of \(total) discovered")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(scheme == .dark ? .white.opacity(0.5) : Color.black.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    // Modern Progress Ring
                    ZStack {
                        Circle()
                            .stroke(scheme == .dark ? Color.white.opacity(0.08) : Color.pink.opacity(0.05), lineWidth: 6)
                            .frame(width: 54, height: 54)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(colors: [.pink, .purple, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 54, height: 54)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(scheme == .dark ? .white : .black.opacity(0.8))
                    }
                }
                
                // Aesthetic Progress Bar
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: geo.size.width * CGFloat(progress), height: 8)
                                .shadow(color: .pink.opacity(0.4), radius: 6, x: 0, y: 0)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Refined Action Buttons
                HStack(spacing: 12) {
                    if revealedCount > 0 {
                        HeaderActionButton(icon: "arrow.counterclockwise", title: "Relock", color: .gray) {
                            showRelockAlert = true
                        }
                    }
                    
                    HeaderActionButton(
                        icon: store.canEraseAll ? "trash.fill" : "lock.fill",
                        title: "Erase All",
                        color: store.canEraseAll ? .red : .orange,
                        isLocked: !store.canEraseAll
                    ) {
                        if store.canEraseAll {
                            showEraseAlert = true
                        } else {
                            store.showPaywall = true
                        }
                    }
                }
                .padding(.top, 4)

                // --- Daily Tasks Section ---
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Daily Selection")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(scheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
                        
                        Spacer()
                        
                        Text("NEW")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.pink)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(vm.dailyTasks) { task in
                                DailyTaskCard(task: task)
                                    .onTapGesture {
                                        selectedDailyTask = task
                                        Haptics.selection()
                                    }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
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
        // Alert for Erase All
        .alert("Erase Everything?", isPresented: $showEraseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Erase All", role: .destructive) {
                withAnimation {
                    vm.resetProgress()
                }
                Haptics.success()
            }
        } message: {
            Text("This permanently wipes all progress and history. This action cannot be undone.")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
                Spacer()
                Text("DAILY")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Text(task.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 145, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: scheme == .dark ?
                            [Color.purple.opacity(0.7), Color.blue.opacity(0.6)] :
                            [Color.pink.opacity(0.8), Color.purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: (scheme == .dark ? Color.purple : Color.pink).opacity(0.2),
            radius: 8, x: 0, y: 4
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
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(isLocked ? (scheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5)) : (scheme == .dark ? color.opacity(0.9) : color))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )
            .overlay(
                Capsule()
                    .stroke(isLocked ? Color.yellow.opacity(0.3) : color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

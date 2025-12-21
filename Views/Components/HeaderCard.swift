import SwiftUI
import StoreKit

struct HeaderCard: View {
    let revealedCount: Int
    let total: Int
    @EnvironmentObject var vm: PosterViewModel
    @EnvironmentObject var store: StoreKitManager
    
    @State private var showRelockAlert = false
    @State private var showEraseAlert = false
    @State private var selectedDailyTask: Challenge?

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(revealedCount) / Double(total), 1)
    }

    var body: some View {
        ZStack {
            // Background with subtle gradient
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.4), Color.black.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)

            VStack(spacing: 12) {
                // Top Row: Title + Percentage
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Love Journey")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(0.5)
                        
                        Text("\(revealedCount) of \(total) unlocked")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Circular Percentage Badge
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 4)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                // Aesthetic Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(colors: [Color.pink, Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * CGFloat(progress), height: 6)
                            .shadow(color: Color.pink.opacity(0.5), radius: 4, x: 0, y: 0) // Glow effect
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                    }
                }
                .frame(height: 6)
                
                // Action Buttons
                HStack(spacing: 12) {
                    // 1. Relock Memories (Standard Reset)
                    if revealedCount > 0 {
                        Button(action: {
                            showRelockAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Relock")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 18)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                        }
                    }
                    
                    // 2. Erase All (Premium Reset)
                    Button(action: {
                        if store.canEraseAll {
                            showEraseAlert = true
                        } else {
                            // Show the paywall (same flow as locked positions)
                            store.showPaywall = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            if !store.canEraseAll {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12))
                            }
                            
                            Text("Erase All")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(store.canEraseAll ? .red.opacity(0.8) : .white.opacity(0.7))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(store.canEraseAll ? Color.red.opacity(0.3) : Color.yellow.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.top, 4)

                // --- Daily Tasks Section ---
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tasks of the Day")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.leading, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(vm.dailyTasks) { task in
                                DailyTaskCard(task: task)
                                    .onTapGesture {
                                        selectedDailyTask = task
                                        Haptics.selection()
                                    }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4) // Space for shadow
                    }
                }
                .padding(.top, 12)
            }
            .padding(16)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Spacer()
                Text("Daily")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(task.title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: 130, height: 110)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

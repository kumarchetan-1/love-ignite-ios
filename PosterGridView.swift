import SwiftUI

struct PosterGridView: View {
    @EnvironmentObject var vm: PosterViewModel
    @EnvironmentObject var store: StoreKitManager
    
    @State private var selectedTask: Challenge?
    @State private var showTaskSheet = false
    
    // We will group tasks by difficulty
    var groupedTasks: [Difficulty: [Challenge]] {
        Dictionary(grouping: vm.tasks, by: { $0.difficulty })
    }
    
    // Define the order we want to show sections
    let displayOrder: [Difficulty] = [.easy, .medium, .hard, .extreme]
    
    // Grid layout
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Space
            Spacer().frame(height: 50)
            
            // Header Card
            HeaderCard(revealedCount: vm.revealedIDs.count, total: vm.tasks.count)
                .environmentObject(vm)
                .padding(Edge.Set.horizontal, 14)
                .padding(.bottom, 16)
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(displayOrder, id: \.self) { diff in
                        if let tasks = groupedTasks[diff], !tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Section Title
                                CategoryHeader(difficulty: diff)
                                    .padding(.horizontal, 14)
                                
                                // Grid
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(tasks) { task in
                                        PosterCell(task: task, onScratchReveal: {
                                            vm.reveal(task: task)
                                        }, onOpenTask: {
                                            if task.isLocked && !store.hasSubscription {
                                                store.showPaywall = true
                                            } else {
                                                selectedTask = task
                                                showTaskSheet = true
                                            }
                                        })
                                        .environmentObject(vm)
                                        .environmentObject(store)
                                        .frame(height: 72)
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(item: $selectedTask) { t in
            TaskDetailSheet(task: t)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $store.showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }
}

struct CategoryHeader: View {
    let difficulty: Difficulty
    
    var body: some View {
        HStack {
            Text(difficulty.rawValue.capitalized)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(NeonColors.color(for: difficulty).opacity(0.2))
                )
                .overlay(
                    Capsule()
                        .stroke(NeonColors.color(for: difficulty).opacity(0.5), lineWidth: 1)
                )
            
            Spacer()
            
            // Decorative line
            Capsule()
                .fill(LinearGradient(colors: [NeonColors.color(for: difficulty), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 2)
        }
    }
}

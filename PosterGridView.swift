import SwiftUI

struct PosterGridView: View {
    @EnvironmentObject var vm: PosterViewModel
    @EnvironmentObject var store: StoreKitManager

    @State private var selectedTask: Task?
    @State private var showTaskSheet = false

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(spacing:12) {
            HeaderCard(revealedCount: vm.revealedIDs.count, total: vm.tasks.count)
                .padding(Edge.Set.horizontal, 14)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(vm.tasks) { task in
                        PosterCell(task: task, onScratchReveal: {
                            vm.reveal(task: task)
                        }, onOpenTask: {
                            // lock check already in PosterCell, but we still guard here
                            if task.category == .extraHot && !store.hasSubscription {
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
                .padding(12)
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

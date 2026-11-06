import SwiftUI

struct PosterGridView: View {
    @EnvironmentObject var vm: PosterViewModel
    @State private var selectedTab: FilterTab = .all
    
    @State private var selectedTask: Challenge?
    @State private var showTaskSheet = false
    
    enum FilterTab: String, CaseIterable, Identifiable {
        case all = "All"
        case talk = "Talk"
        case skills = "Relationship Skills"
        case dates = "Date Ideas"
        case outdoor = "Out & About"
        
        var id: String { rawValue }
    }
    
    private var filteredVisibleTasks: [(Challenge, Bool)] {
        vm.tasks.filter { task in
            switch selectedTab {
            case .all: return true
            case .talk: return task.category == .questions || task.category == .loveQnA
            case .skills: return task.category == .techniques
            case .dates: return task.category == .general
            case .outdoor: return task.category == .locations
            }
        }.map { ($0, false) }
    }
    
    // We will group tasks by difficulty
    var groupedTasks: [Difficulty: [(Challenge, Bool)]] {
        Dictionary(grouping: filteredVisibleTasks, by: { $0.0.difficulty })
    }
    
    // Define the order we want to show sections
    let displayOrder: [Difficulty] = [.easy, .medium, .hard, .extreme]
    
    // Grid layout
    private var columns: [GridItem] {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let minWidth: CGFloat = isIPad ? 140 : 65
        return [GridItem(.adaptive(minimum: minWidth), spacing: 16)]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Modern top spacing for clean breathing room
                let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                Spacer().frame(height: isIPad ? 40 : 70)
                
                // Header Card now scrolls with content
                HeaderCard(revealedCount: vm.revealedIDs.count, total: vm.tasks.count)
                    .environmentObject(vm)
                    .padding(.horizontal, isIPad ? 40 : 14)
                
                // Filter Tabs
                FilterTabs(selectedTab: $selectedTab)
                    .padding(.horizontal, isIPad ? 40 : 14)
                    .padding(.bottom, 4)
                
                ForEach(displayOrder, id: \.self) { diff in
                    if let tasks = groupedTasks[diff], !tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            // Section Title
                            CategoryHeader(difficulty: diff)
                                .padding(.horizontal, isIPad ? 40 : 14)
                            
                            // Grid
                            LazyVGrid(columns: columns, spacing: 12) {
                                let categoryTasks = tasks
                                ForEach(0..<categoryTasks.count, id: \.self) { index in
                                    let entry = categoryTasks[index]
                                    let task = entry.0
                                    let redacted = entry.1
                                    
                                    // If not 'All' tab, use (index + 1) as display number
                                    let displayNumber = selectedTab == .all ? task.number : (index + 1)
                                    
                                    PosterCell(task: task, displayNumber: displayNumber, onScratchReveal: {
                                        vm.reveal(task: task)
                                    }, onOpenTask: {
                                        selectedTask = task
                                        showTaskSheet = true
                                    }, redactedExplicit: redacted)
                                    .environmentObject(vm)
                                }
                            }
                            .padding(.horizontal, isIPad ? 38 : 12)
                        }
                    }
                }
                
                Spacer().frame(height: 120)
            }
        }
        #if DEBUG
        .onAppear {
            // Screenshot hooks (debug builds only): -uiFilter talk -uiReveal 30 -uiOpenTask 3
            let d = UserDefaults.standard
            if let f = d.string(forKey: "uiFilter"), let t = FilterTab.allCases.first(where: { "\($0)" == f }) { selectedTab = t }
            let n = d.integer(forKey: "uiReveal")
            if n > 0 { vm.tasks.prefix(n).forEach { vm.reveal(task: $0) } }
            if let i = d.object(forKey: "uiOpenTask") as? String, let idx = Int(i) {
                let list = filteredVisibleTasks.map { $0.0 }
                if idx < list.count { DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { selectedTask = list[idx]; showTaskSheet = true } }
            }
        }
        #endif
        .sheet(item: $selectedTask) { t in
            TaskDetailSheet(task: t)
                .presentationDetents([.large])
        }
    }
}

struct CategoryHeader: View {
    let difficulty: Difficulty
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        HStack(spacing: 12) {
            Text(difficulty.displayName.uppercased())
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundColor(titleColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                )
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [NeonColors.color(for: difficulty).opacity(0.6), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
    
    private var backgroundColor: Color {
        NeonColors.color(for: difficulty).opacity(self.scheme == .dark ? 0.2 : 0.1)
    }
    
    private var titleColor: Color {
        NeonColors.color(for: difficulty)
    }
}

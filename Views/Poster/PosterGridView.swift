import SwiftUI

struct PosterGridView: View {
    @EnvironmentObject var vm: PosterViewModel
    @EnvironmentObject var store: StoreKitManager
    @AppStorage("hide_explicit") private var hideExplicit: Bool = true
    @State private var selectedTab: FilterTab = .all
    
    @State private var selectedTask: Challenge?
    @State private var showTaskSheet = false
    
    enum FilterTab: String, CaseIterable, Identifiable {
        case all = "All"
        case qna = "QnA"
        case indoor = "Indoor"
        case outdoor = "Outdoor"
        case kama = "Kamasutra Positions"
        
        var id: String { rawValue }
    }
    
    // Love gesture replacements for explicit tasks (indoor)
    private let indoorGestures: [String] = [
        "Leave a lipstick kiss on a mirror for them to find.",
        "Whisper a secret desire while holding hands.",
        "Plan a surprise candlelit dessert tasting.",
        "Give a slow back-trace with fingertips in the dark.",
        "Share a fantasy over soft music and dim lights.",
        "Hide a love note under their pillow.",
        "Offer a slow hand massage with warm oil.",
        "Dance chest-to-chest to a single song.",
        "Brush their hair back and kiss their forehead.",
        "Read a flirty poem to them in bed.",
        "Do a blindfolded taste-guessing game.",
        "Hold a 30-second gaze, then kiss slowly.",
        "Trace a heart on their palm and let them guess.",
        "Plan a surprise indoor picnic with fairy lights.",
        "Give a lingering hug from behind and whisper.",
        "Place small compliments in their pockets to find.",
        "Share one hidden wish for tonight.",
        "Give a playful countdown before a kiss.",
        "Offer a warm towel and a scalp massage.",
        "Send them to another room and text a sweet dare."
    ]
    // Outdoor-friendly affectionate gestures
    private let outdoorGestures: [String] = [
        "Hold hands and whisper a compliment while you walk.",
        "Take a playful selfie together in a crowd.",
        "Find a quiet bench and share one wish for the future.",
        "Give them your jacket and steal a kiss.",
        "Buy them a favorite snack and surprise them.",
        "Plan a 10-minute park stroll and link arms.",
        "Stand behind them and whisper why you're proud.",
        "Cheer loudly for them in public, just because.",
        "Leave a kind note in their bag before heading out."
    ]
    
    // Filter/transform explicit content if toggle is on
    // Returns: (displayTask, redactedExplicit)
    private var visibleTasks: [(Challenge, Bool)] {
        vm.tasks.map { task in
            let shouldReplace = hideExplicit && task.category == .extraHot
            
            guard shouldReplace else {
                return (task, false)
            }
            
            // Deterministic replacement based on task ID
            let hash = abs(task.id.hashValue)
            let useOutdoor = hash.isMultiple(of: 2)
            let gestureList = useOutdoor ? outdoorGestures : indoorGestures
            let gesture = gestureList[hash % gestureList.count]
                
                let replaced = Challenge(
                    id: task.id,
                    number: task.number,
                    title: gesture,
                category: .extraHot, // Keep the category so it stays in the Kamasutra tab
                    difficulty: task.difficulty,
                    hint: "Love Gesture",
                    imageName: nil,
                    isLocked: false
                )
            return (replaced, true)
        }
    }
    
    // Apply tab filter
    private var filteredVisibleTasks: [(Challenge, Bool)] {
        visibleTasks.filter { entry in
            let displayCat = entry.0.category
            
            // If Privacy Mode is ON, we hide all .extraHot tasks from the "All" tab 
            // and they are already filtered out if we hide the Kamasutra tab.
            if hideExplicit && displayCat == .extraHot && selectedTab == .all {
                return false
            }
            
            switch selectedTab {
            case .all:
                return true
            case .qna:
                return displayCat == .loveQnA
            case .indoor:
                return displayCat != .locations && displayCat != .extraHot && displayCat != .loveQnA
            case .outdoor:
                return displayCat == .locations
            case .kama:
                return displayCat == .extraHot
            }
        }
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
                                        if task.isLocked && !store.hasSubscription {
                                            store.showPaywall = true
                                        } else {
                                            selectedTask = task
                                            showTaskSheet = true
                                        }
                                    }, redactedExplicit: redacted)
                                    .environmentObject(vm)
                                    .environmentObject(store)
                                }
                            }
                            .padding(.horizontal, isIPad ? 38 : 12)
                        }
                    }
                }
                
                Spacer().frame(height: 120)
            }
        }
        .sheet(item: $selectedTask) { t in
            TaskDetailSheet(task: t)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $store.showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }
}

struct CategoryHeader: View {
    let difficulty: Difficulty
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        HStack(spacing: 12) {
            Text(difficulty.rawValue.uppercased())
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

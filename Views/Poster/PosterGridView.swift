import SwiftUI

struct PosterGridView: View {
    @EnvironmentObject var vm: PosterViewModel
    @EnvironmentObject var store: StoreKitManager
    @AppStorage("hide_explicit") private var hideExplicit: Bool = false
    @State private var selectedTab: FilterTab = .all
    
    @State private var selectedTask: Challenge?
    @State private var showTaskSheet = false
    
    enum FilterTab: String, CaseIterable, Identifiable {
        case all = "All"
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
            
            // Deterministic replacement so SwiftUI doesn't recompute random content on each render
            let useOutdoor = task.id.hashValue.isMultiple(of: 2)
            let gesture = (useOutdoor ? outdoorGestures.randomElement() : indoorGestures.randomElement())
                ?? "Share a gentle love gesture tonight."
            let newCategory: TaskCategory = useOutdoor ? .locations : .general
            
            let replaced = Challenge(
                id: task.id,
                number: task.number,
                title: gesture,
                category: newCategory,
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
            switch selectedTab {
            case .all:
                return true
            case .indoor:
                return displayCat != .locations && displayCat != .extraHot
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
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top spacing to clear safe areas / dynamic island
                Spacer().frame(height: 50)
                
                // Header Card now scrolls with content
                HeaderCard(revealedCount: vm.revealedIDs.count, total: vm.tasks.count)
                    .environmentObject(vm)
                    .padding(Edge.Set.horizontal, 14)
                
                // Filter Tabs
                FilterTabs(selectedTab: $selectedTab)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
                
                ForEach(displayOrder, id: \.self) { diff in
                    if let tasks = groupedTasks[diff], !tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Title
                            CategoryHeader(difficulty: diff)
                                .padding(.horizontal, 14)
                            
                            // Grid
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(tasks, id: \.0.id) { entry in
                                    let task = entry.0
                                    let redacted = entry.1
                                    
                                    PosterCell(task: task, onScratchReveal: {
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
                                    .frame(height: 72)
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                }
                
                Spacer().frame(height: 40)
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
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        HStack {
            Text(difficulty.rawValue.capitalized)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(titleColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                )
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                )
            
            Spacer()
            
            // Decorative line
            Capsule()
                .fill(LinearGradient(colors: [NeonColors.color(for: difficulty), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 2)
        }
    }
    
    private var backgroundColor: Color {
        if scheme == .light {
            return NeonColors.color(for: difficulty).opacity(0.14)
        } else {
            return NeonColors.color(for: difficulty).opacity(0.2)
        }
    }
    
    private var titleColor: Color {
        if scheme == .light {
            // Darker shade of the same base color for contrast on light pills
            return NeonColors.color(for: difficulty).opacity(0.9)
        } else {
            return .white
        }
    }
    
    private var borderColor: Color {
        if scheme == .light {
            return NeonColors.color(for: difficulty).opacity(0.6)
        } else {
            return NeonColors.color(for: difficulty).opacity(0.5)
        }
    }
}

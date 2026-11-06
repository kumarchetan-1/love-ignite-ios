import Foundation
import Combine
import SwiftUI

class PosterViewModel: ObservableObject {
    @Published var tasks: [Challenge] = []
    @Published var dailyTasks: [Challenge] = []
    @Published var revealedIDs: Set<String> = []
    @Published var achievements: [Achievement] = []
    @Published var showConfetti: Bool = false
    @Published var recentlyUnlocked: Achievement?

    private var storage: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    private struct Keys {
        static let tasks = "tasks_v3"
        static let achievements = "achievements_v3"
        static let revealed = "revealed_v3"
    }

    init(storage: StorageServiceProtocol = StorageService.shared) {
        self.storage = storage
        loadSampleDataIfNeeded()
        loadProgress()
        
        Task {
            await refreshDailyTasksWithAI()
        }

        $revealedIDs
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveProgress()
            }
            .store(in: &cancellables)

        // Observe iCloud changes
        NotificationCenter.default.addObserver(self, selector: #selector(ubiquitousKeyValueStoreDidChange), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
    }

    func loadSampleDataIfNeeded() {
        if let saved = storage.load([Challenge].self, for: Keys.tasks), !saved.isEmpty {
            self.tasks = saved
        } else {
            let generated = TasksData.generateTasks()
            storage.save(generated.tasks, for: Keys.tasks)
            self.tasks = generated.tasks
        }

        // Always refresh daily tasks on load (or could store date to persist for 24h)
        self.dailyTasks = TasksData.generateDailyTasks()

        // Achievements
        let defaultAch: [Achievement] = [
            Achievement(id: "a1", title: "First Spark", unlocked: false),
            Achievement(id: "a2", title: "Warming Up (10)", unlocked: false),
            Achievement(id: "a3", title: "Halfway There (50)", unlocked: false),
            Achievement(id: "a4", title: "Committed Pro (100)", unlocked: false),
            Achievement(id: "a5", title: "Check-in Champ (10 Skills)", unlocked: false),
            Achievement(id: "a6", title: "True Romantic (All Cards)", unlocked: false),
            Achievement(id: "a7", title: "Twenty Together (20 Cards)", unlocked: false),
            Achievement(id: "a8", title: "Date Night Darling (20 Dates)", unlocked: false),
            Achievement(id: "a9", title: "Deep Talker (20 Love Questions)", unlocked: false),
            Achievement(id: "a10", title: "Curious Couple (15 Talks)", unlocked: false),
            Achievement(id: "a11", title: "Out & About (15 Outings)", unlocked: false),
            Achievement(id: "a12", title: "Good Listener (20 Skills)", unlocked: false),
            Achievement(id: "a13", title: "Century Club (100 Cards)", unlocked: false),
            Achievement(id: "a14", title: "Full House (120 Cards)", unlocked: false),
            Achievement(id: "a15", title: "All In (130 Cards)", unlocked: false),
            Achievement(id: "a16", title: "Heart Collector (All Achievements)", unlocked: false)
        ]
        
        if let savedAchievements = storage.load([Achievement].self, for: Keys.achievements) {
            // Merge in any newly added achievements that aren't stored yet
            var merged = savedAchievements
            for ach in defaultAch where !merged.contains(where: { $0.id == ach.id }) {
                merged.append(ach)
            }
            self.achievements = merged
            storage.save(merged, for: Keys.achievements)
        } else {
            self.achievements = defaultAch
            storage.save(defaultAch, for: Keys.achievements)
        }
    }

    func reveal(task: Challenge) {
        // Idempotent reveal
        if !revealedIDs.contains(task.id) {
        revealedIDs.insert(task.id)
        checkAchievements()
            triggerCelebrationIfNeeded()
        }
    }
    
    private func triggerCelebrationIfNeeded() {
        // show confetti briefly when certain milestones hit
        if revealedIDs.count % 10 == 0 { 
            DispatchQueue.main.async {
                withAnimation {
                self.showConfetti = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation {
                        self.showConfetti = false
                    }
                }
            }
        }
    }

    func isRevealed(_ task: Challenge) -> Bool {
        revealedIDs.contains(task.id)
    }

    func saveProgress() {
        storage.save(Array(revealedIDs), for: Keys.revealed)
        storage.save(achievements, for: Keys.achievements)
    }

    func loadProgress() {
        if let arr = storage.load([String].self, for: Keys.revealed) {
            // Merge loaded data with current state (Union) to prevent data loss during sync
            self.revealedIDs.formUnion(arr)
        }
    }

    func resetProgress() {
        revealedIDs.removeAll()
        achievements.indices.forEach { achievements[$0].unlocked = false }
        
        let generated = TasksData.generateTasks()
        self.tasks = generated.tasks
        storage.save(generated.tasks, for: Keys.tasks)
        
        saveProgress()
    }

    func revealAllTasks() {
        let allIDs = tasks.map { $0.id }
        revealedIDs.formUnion(allIDs)
        checkAchievements()
        saveProgress()
    }

    private func checkAchievements() {
        let totalReveals = revealedIDs.count
        var changed = false
        var newlyUnlocked: Achievement?
        
        let revealedTasks = tasks.filter { revealedIDs.contains($0.id) }
        func categoryCount(_ cat: TaskCategory) -> Int {
            revealedTasks.filter { $0.category == cat }.count
        }
        
        // 1. First Spark (1 task)
        if totalReveals > 0, let idx = achievements.firstIndex(where: { $0.id == "a1" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 2. Heating Up (10 tasks)
        if totalReveals >= 10, let idx = achievements.firstIndex(where: { $0.id == "a2" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 3. Halfway There (50 tasks)
        if totalReveals >= 50, let idx = achievements.firstIndex(where: { $0.id == "a3" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 4. Passionate Pro (100 tasks)
        if totalReveals >= 100, let idx = achievements.firstIndex(where: { $0.id == "a4" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 5. Check-in Champ (10 skills)
        if categoryCount(.techniques) >= 10, let idx = achievements.firstIndex(where: { $0.id == "a5" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 6. True Romantic (All 200 Tasks)
        if !tasks.isEmpty && totalReveals >= tasks.count, let idx = achievements.firstIndex(where: { $0.id == "a6" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 7. Flirty Twenty
        if totalReveals >= 20, let idx = achievements.firstIndex(where: { $0.id == "a7" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 8. Date Night Darling (20 Romantic/general)
        if categoryCount(.general) >= 20, let idx = achievements.firstIndex(where: { $0.id == "a8" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 9. Deep Talker (20 love questions)
        if categoryCount(.loveQnA) >= 20, let idx = achievements.firstIndex(where: { $0.id == "a9" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 10. Question Tease (15 Questions)
        if categoryCount(.questions) >= 15, let idx = achievements.firstIndex(where: { $0.id == "a10" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 11. City of Love (15 Locations)
        if categoryCount(.locations) >= 15, let idx = achievements.firstIndex(where: { $0.id == "a11" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 12. Intimate Whisper (10 Techniques)
        if categoryCount(.techniques) >= 20, let idx = achievements.firstIndex(where: { $0.id == "a12" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 13. Centurion of Love (150 reveals)
        if totalReveals >= 100, let idx = achievements.firstIndex(where: { $0.id == "a13" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 14. Full House (175 reveals)
        if totalReveals >= 120, let idx = achievements.firstIndex(where: { $0.id == "a14" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 15. All In Lover (190 reveals)
        if totalReveals >= 130, let idx = achievements.firstIndex(where: { $0.id == "a15" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        // 16. Heart Collector (all achievements)
        if achievements.dropLast().allSatisfy({ $0.unlocked }), let idx = achievements.firstIndex(where: { $0.id == "a16" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true; newlyUnlocked = achievements[idx]
        }
        
        if changed {
            storage.save(achievements, for: Keys.achievements)
            if let unlocked = newlyUnlocked {
                triggerAchievementToast(unlocked)
            }
        }
    }

    @objc private func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        // Re-load to sync changes from iCloud, merging with current state
        DispatchQueue.main.async { [weak self] in
            self?.loadProgress()
        }
    }
    
    private func triggerAchievementToast(_ achievement: Achievement) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.recentlyUnlocked = achievement
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.recentlyUnlocked = nil
                }
            }
        }
    }

    @MainActor
    func refreshDailyTasksWithAI() async {
        let lastDate = UserDefaults.standard.string(forKey: "last_ai_task_date")
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        
        // If we already have today's tasks in memory, don't fetch again
        if lastDate == today && !self.dailyTasks.isEmpty {
            return
        }

        let aiTasks = await AITaskService.shared.generateDailyTasks()
        
        if !aiTasks.isEmpty {
            self.dailyTasks = aiTasks
            UserDefaults.standard.set(today, forKey: "last_ai_task_date")
            // Optionally save to storage to persist across app restarts
            // storage.save(aiTasks, for: "ai_daily_tasks")
        } else {
            // Fallback to local generator if AI fails or no API key
            self.dailyTasks = TasksData.generateDailyTasks()
        }
    }
}

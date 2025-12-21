import Foundation
import Combine
import SwiftUI

class PosterViewModel: ObservableObject {
    @Published var tasks: [Challenge] = []
    @Published var dailyTasks: [Challenge] = []
    @Published var revealedIDs: Set<String> = []
    @Published var achievements: [Achievement] = []
    @Published var showConfetti: Bool = false

    private var storage: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private struct Keys {
        static let tasks = "tasks_v2"
        static let achievements = "achievements_v1"
        static let revealed = "revealed_v1"
    }

    init(storage: StorageServiceProtocol = StorageService.shared) {
        self.storage = storage
        loadSampleDataIfNeeded()
        loadProgress()

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
        if storage.load([Challenge].self, for: Keys.tasks) == nil {
            let arr = TasksData.generateTasks(count: 200)
            storage.save(arr, for: Keys.tasks)
        }
        if let saved = storage.load([Challenge].self, for: Keys.tasks) {
            self.tasks = saved
        }

        // Always refresh daily tasks on load (or could store date to persist for 24h)
        self.dailyTasks = TasksData.generateDailyTasks()

        // Achievements: baseline plus new naughty/romantic ones
        let defaultAch: [Achievement] = [
            Achievement(id: "a1", title: "First Spark", unlocked: false),
            Achievement(id: "a2", title: "Heating Up (10)", unlocked: false),
            Achievement(id: "a3", title: "Halfway There (50)", unlocked: false),
            Achievement(id: "a4", title: "Passionate Pro (100)", unlocked: false),
            Achievement(id: "a5", title: "Kamasutra Master (All Positions)", unlocked: false),
            Achievement(id: "a6", title: "True Romantic (All Tasks)", unlocked: false),
            Achievement(id: "a7", title: "Flirty Twenty (20 Reveals)", unlocked: false),
            Achievement(id: "a8", title: "Date Night Darling (20 Romantic)", unlocked: false),
            Achievement(id: "a9", title: "Spicy Explorer (20 Extra Hot)", unlocked: false),
            Achievement(id: "a10", title: "Question Tease (15 Questions)", unlocked: false),
            Achievement(id: "a11", title: "City of Love (15 Locations)", unlocked: false),
            Achievement(id: "a12", title: "Intimate Whisper (10 Techniques)", unlocked: false),
            Achievement(id: "a13", title: "Centurion of Love (150 Reveals)", unlocked: false),
            Achievement(id: "a14", title: "Full House (175 Reveals)", unlocked: false),
            Achievement(id: "a15", title: "All In Lover (190 Reveals)", unlocked: false),
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
        
        // Randomize tasks and positions again
        let newTasks = TasksData.generateTasks(count: 200) // Updated count
        self.tasks = newTasks
        storage.save(newTasks, for: Keys.tasks)
        
        saveProgress()
    }

    private func checkAchievements() {
        let totalReveals = revealedIDs.count
        var changed = false
        
        let revealedTasks = tasks.filter { revealedIDs.contains($0.id) }
        func categoryCount(_ cat: TaskCategory) -> Int {
            revealedTasks.filter { $0.category == cat }.count
        }
        
        // 1. First Spark (1 task)
        if totalReveals > 0, let idx = achievements.firstIndex(where: { $0.id == "a1" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 2. Heating Up (10 tasks)
        if totalReveals >= 10, let idx = achievements.firstIndex(where: { $0.id == "a2" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 3. Halfway There (50 tasks)
        if totalReveals >= 50, let idx = achievements.firstIndex(where: { $0.id == "a3" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 4. Passionate Pro (100 tasks)
        if totalReveals >= 100, let idx = achievements.firstIndex(where: { $0.id == "a4" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 5. Kamasutra Master (all positions revealed)
        let revealedPositionsCount = revealedTasks.filter { $0.category == .extraHot }.count
        if revealedPositionsCount >= 59, let idx = achievements.firstIndex(where: { $0.id == "a5" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 6. True Romantic (All 200 Tasks)
        if totalReveals >= 200, let idx = achievements.firstIndex(where: { $0.id == "a6" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 7. Flirty Twenty
        if totalReveals >= 20, let idx = achievements.firstIndex(where: { $0.id == "a7" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 8. Date Night Darling (20 Romantic/general)
        if categoryCount(.general) >= 20, let idx = achievements.firstIndex(where: { $0.id == "a8" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 9. Spicy Explorer (20 Extra Hot)
        if categoryCount(.extraHot) >= 20, let idx = achievements.firstIndex(where: { $0.id == "a9" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 10. Question Tease (15 Questions)
        if categoryCount(.questions) >= 15, let idx = achievements.firstIndex(where: { $0.id == "a10" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 11. City of Love (15 Locations)
        if categoryCount(.locations) >= 15, let idx = achievements.firstIndex(where: { $0.id == "a11" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 12. Intimate Whisper (10 Techniques)
        if categoryCount(.techniques) >= 10, let idx = achievements.firstIndex(where: { $0.id == "a12" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 13. Centurion of Love (150 reveals)
        if totalReveals >= 150, let idx = achievements.firstIndex(where: { $0.id == "a13" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 14. Full House (175 reveals)
        if totalReveals >= 175, let idx = achievements.firstIndex(where: { $0.id == "a14" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 15. All In Lover (190 reveals)
        if totalReveals >= 190, let idx = achievements.firstIndex(where: { $0.id == "a15" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        // 16. Heart Collector (all achievements)
        if achievements.dropLast().allSatisfy({ $0.unlocked }), let idx = achievements.firstIndex(where: { $0.id == "a16" && !$0.unlocked }) {
            achievements[idx].unlocked = true; changed = true
        }
        
        if changed {
            storage.save(achievements, for: Keys.achievements)
        }
    }

    @objc private func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        // Re-load to sync changes from iCloud, merging with current state
        DispatchQueue.main.async { [weak self] in
            self?.loadProgress()
        }
    }
}

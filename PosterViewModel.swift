import Foundation
import Combine
import SwiftUI

class PosterViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var revealedIDs: Set<String> = []
    @Published var achievements: [Achievement] = []
    @Published var showConfetti: Bool = false

    private var storage: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

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
        if storage.load([Task].self, for: "tasks_v1") == nil {
            let arr = TasksData.generateTasks(count: 169)
            storage.save(arr, for: "tasks_v1")
        }
        if let saved = storage.load([Task].self, for: "tasks_v1") {
            self.tasks = saved
        }

        if let savedAchievements = storage.load([Achievement].self, for: "achievements_v1") {
            self.achievements = savedAchievements
        } else {
            let defaultAch = [Achievement(id: "a1", title: "First Scratch", unlocked: false), Achievement(id: "a2", title: "10 Revealed", unlocked: false)]
            self.achievements = defaultAch
            storage.save(defaultAch, for: "achievements_v1")
        }
    }

    func reveal(task: Task) {
        revealedIDs.insert(task.id)
        checkAchievements()
        // show confetti briefly when certain achievements hit
        if revealedIDs.count % 10 == 0 { // every 10 reveals celebrate
            DispatchQueue.main.async {
                self.showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { self.showConfetti = false }
            }
        }
    }

    func isRevealed(_ task: Task) -> Bool {
        revealedIDs.contains(task.id)
    }

    func saveProgress() {
        storage.save(Array(revealedIDs), for: "revealed_v1")
    }

    func loadProgress() {
        if let arr = storage.load([String].self, for: "revealed_v1") {
            self.revealedIDs = Set(arr)
        }
    }

    private func checkAchievements() {
        let count = revealedIDs.count
        if count > 0, let idx = achievements.firstIndex(where: { $0.id == "a1" && !$0.unlocked }) {
            achievements[idx].unlocked = true
        }
        if count >= 10, let idx = achievements.firstIndex(where: { $0.id == "a2" && !$0.unlocked }) {
            achievements[idx].unlocked = true
        }
        storage.save(achievements, for: "achievements_v1")
    }

    @objc private func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        // Simple re-load to sync changes from iCloud
        loadProgress()
    }
}

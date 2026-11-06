import Foundation
import Combine

final class WellnessService: ObservableObject {
    static let shared = WellnessService()
    private init() {}

    private let storage = StorageService.shared

    private enum Keys {
        static let moodEntries = "wellness.mood_entries"
        static let cycleSettings = "wellness.cycle_settings"
        static let cycleProfiles = "wellness.cycle_profiles"
    }

    func loadMoodEntries() -> [MoodEntry] {
        storage.load([MoodEntry].self, for: Keys.moodEntries) ?? []
    }

    func saveMoodEntries(_ entries: [MoodEntry]) {
        storage.save(entries, for: Keys.moodEntries)
    }

    func loadCycleSettings() -> CycleSettings {
        storage.load(CycleSettings.self, for: Keys.cycleSettings) ?? CycleSettings()
    }

    func saveCycleSettings(_ settings: CycleSettings) {
        storage.save(settings, for: Keys.cycleSettings)
    }

    func loadCycleProfiles() -> [CycleProfile] {
        if let profiles = storage.load([CycleProfile].self, for: Keys.cycleProfiles), !profiles.isEmpty {
            return profiles
        }

        // Migration: if old single settings exist, wrap into a default profile.
        let legacy = loadCycleSettings()
        let defaultProfile = CycleProfile(name: "Partner", label: "Primary", settings: legacy)
        let seeded = [defaultProfile]
        saveCycleProfiles(seeded)
        return seeded
    }

    func saveCycleProfiles(_ profiles: [CycleProfile]) {
        storage.save(profiles, for: Keys.cycleProfiles)
    }

    func forecast(from settings: CycleSettings, calendar: Calendar = .current) -> CycleForecast {
        let startOfLast = calendar.startOfDay(for: settings.lastPeriodStart)
        let nextStart = calendar.date(byAdding: .day, value: settings.cycleLengthDays, to: startOfLast) ?? startOfLast
        let nextEnd = calendar.date(byAdding: .day, value: max(settings.periodLengthDays - 1, 0), to: nextStart) ?? nextStart

        let pmsStart = calendar.date(byAdding: .day, value: -5, to: nextStart) ?? nextStart
        let pmsEnd = calendar.date(byAdding: .day, value: -1, to: nextStart) ?? nextStart

        return CycleForecast(nextPeriodStart: nextStart, nextPeriodEnd: nextEnd, pmsStart: pmsStart, pmsEnd: pmsEnd)
    }
}


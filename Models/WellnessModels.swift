import Foundation

struct MoodEntry: Identifiable, Codable, Equatable {
    let id: String
    var date: Date
    /// 1...5 (very low → very good)
    var moodScore: Int
    var tags: [String]
    var note: String

    init(id: String = UUID().uuidString, date: Date, moodScore: Int, tags: [String] = [], note: String = "") {
        self.id = id
        self.date = date
        self.moodScore = min(max(moodScore, 1), 5)
        self.tags = tags
        self.note = note
    }
}

struct CycleSettings: Codable, Equatable {
    /// First day of last period.
    var lastPeriodStart: Date
    /// History of logged period starts (most recent first). Optional for backwards compatibility.
    var periodStartHistory: [Date]
    /// Typical cycle length in days (e.g., 28).
    var cycleLengthDays: Int
    /// Typical period length in days (e.g., 5).
    var periodLengthDays: Int

    init(lastPeriodStart: Date = Date(), periodStartHistory: [Date] = [], cycleLengthDays: Int = 28, periodLengthDays: Int = 5) {
        self.lastPeriodStart = lastPeriodStart
        self.periodStartHistory = periodStartHistory
        self.cycleLengthDays = min(max(cycleLengthDays, 20), 40)
        self.periodLengthDays = min(max(periodLengthDays, 2), 10)
    }
}

struct CycleForecast: Equatable {
    var nextPeriodStart: Date
    var nextPeriodEnd: Date
    /// PMS-ish window: \(nextPeriodStart - 5\) ... \(nextPeriodStart - 1\)
    var pmsStart: Date
    var pmsEnd: Date
}

struct CycleProfile: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    /// Optional label like “Partner”, “Sister”, “Mother”
    var label: String
    var settings: CycleSettings

    init(id: String = UUID().uuidString, name: String, label: String = "", settings: CycleSettings = CycleSettings()) {
        self.id = id
        self.name = name
        self.label = label
        self.settings = settings
    }
}


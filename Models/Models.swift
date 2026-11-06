import Foundation

struct Challenge: Identifiable, Codable {
    let id: String
    let number: Int
    let title: String
    let category: TaskCategory
    let difficulty: Difficulty
    let hint: String?
    let imageName: String?
    let isLocked: Bool
}

enum TaskCategory: String, Codable {
    case general, locations, questions, extraHot, techniques, loveQnA
}

enum Difficulty: String, Codable {
    case easy, medium, hard, extreme
}

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var unlocked: Bool
}

extension Difficulty {
    /// Friendly level names shown in the UI.
    var displayName: String {
        switch self {
        case .easy: return "Spark"
        case .medium: return "Connect"
        case .hard: return "Deepen"
        case .extreme: return "Grow"
        }
    }
}

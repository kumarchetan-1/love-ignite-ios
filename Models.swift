import Foundation

struct Task: Identifiable, Codable {
    let id: String
    let title: String
    let category: TaskCategory
    let difficulty: Difficulty
    let hint: String?
    let imageName: String?   
}

enum TaskCategory: String, Codable {
    case general, locations, questions, extraHot, techniques
}

enum Difficulty: String, Codable {
    case easy, medium, hard, extreme
}

struct Achievement: Identifiable, Codable {
    let id: String
    var title: String
    var unlocked: Bool
}

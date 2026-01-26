import Foundation

enum ChatMessageType: String, Codable {
    case text
    case image
    case video
}

struct ChatUser: Identifiable, Codable, Equatable {
    let id: String
    let name: String
}

struct ChatRoom: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let maxUsers: Int
    let ownerId: String
    let participants: [ChatUser]
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let roomId: String
    let senderId: String
    let senderName: String
    let messageType: ChatMessageType
    let payload: String
    let timestamp: Date
}

import Foundation

@MainActor
final class ChatService: ObservableObject {
    @Published var room: ChatRoom?
    @Published var messages: [ChatMessage] = []
    @Published var errorMessage: String?
    @Published var isConnected = false
    @Published var lastRoomId: String?
    @Published var currentUserId: String?
    @Published var currentUserName: String = "User"

    private var socket: URLSessionWebSocketTask?
    private var userName: String = "User"
    private var isReceiving = false

    private let baseURL = "https://api.loveignite.chetankumar.me"

    private var socketURL: URL? {
        guard let url = URL(string: baseURL) else { return nil }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = (components?.scheme == "https") ? "wss" : "ws"
        components?.path = "/chat"
        return components?.url
    }

    func connectIfNeeded() {
        guard socket == nil else { return }
        guard let url = socketURL else {
            errorMessage = "Invalid chat server URL"
            return
        }
        let task = URLSession.shared.webSocketTask(with: url)
        socket = task
        task.resume()
        isConnected = true
        receiveLoop()
    }

    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        isConnected = false
        isReceiving = false
    }

    func createRoom(roomName: String, maxUsers: Int, userName: String) {
        connectIfNeeded()
        self.userName = userName
        currentUserName = userName
        send(payload: [
            "type": "createRoom",
            "roomName": roomName,
            "maxUsers": maxUsers,
            "userName": userName
        ])
    }

    func joinRoom(roomId: String, userName: String) {
        connectIfNeeded()
        self.userName = userName
        currentUserName = userName
        send(payload: [
            "type": "joinRoom",
            "roomId": roomId,
            "userName": userName
        ])
    }

    func leaveRoom() {
        send(payload: ["type": "leaveRoom"])
        room = nil
        messages.removeAll()
        currentUserId = nil
    }

    func removeUser(_ userId: String) {
        send(payload: [
            "type": "removeUser",
            "targetUserId": userId
        ])
    }

    func sendText(_ text: String) {
        send(payload: [
            "type": "message",
            "messageType": "text",
            "payload": text
        ])
    }

    func sendMedia(_ base64: String, type: ChatMessageType) {
        send(payload: [
            "type": "message",
            "messageType": type.rawValue,
            "payload": base64
        ])
    }

    private func send(payload: [String: Any]) {
        guard let socket else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            let string = String(data: data, encoding: .utf8) ?? "{}"
            socket.send(.string(string)) { [weak self] error in
                if let error {
                    Task { @MainActor in
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func receiveLoop() {
        guard let socket, !isReceiving else { return }
        isReceiving = true

        socket.receive { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                switch result {
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isConnected = false
                    self.isReceiving = false
                case .success(let message):
                    self.handleIncoming(message)
                    self.isReceiving = false
                    self.receiveLoop()
                }
            }
        }
    }

    private func handleIncoming(_ message: URLSessionWebSocketTask.Message) {
        let text: String
        switch message {
        case .string(let string):
            text = string
        case .data(let data):
            text = String(data: data, encoding: .utf8) ?? ""
        @unknown default:
            return
        }

        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        switch type {
        case "roomCreated":
            if let roomId = json["roomId"] as? String {
                lastRoomId = roomId
            }
        case "roomState":
            guard let roomId = json["roomId"] as? String,
                  let roomName = json["roomName"] as? String,
                  let maxUsers = json["maxUsers"] as? Int,
                  let ownerId = json["ownerId"] as? String,
                  let participantsRaw = json["participants"] as? [[String: Any]] else { return }

            currentUserId = json["selfId"] as? String

            let participants = participantsRaw.compactMap { dict -> ChatUser? in
                guard let id = dict["id"] as? String,
                      let name = dict["name"] as? String else { return nil }
                return ChatUser(id: id, name: name)
            }

            room = ChatRoom(id: roomId, name: roomName, maxUsers: maxUsers, ownerId: ownerId, participants: participants)
        case "message":
            guard let messageId = json["messageId"] as? String,
                  let roomId = json["roomId"] as? String,
                  let senderId = json["senderId"] as? String,
                  let senderName = json["senderName"] as? String,
                  let messageTypeRaw = json["messageType"] as? String,
                  let payload = json["payload"] as? String,
                  let timestampMs = json["timestamp"] as? Double,
                  let messageType = ChatMessageType(rawValue: messageTypeRaw) else { return }

            let msg = ChatMessage(
                id: messageId,
                roomId: roomId,
                senderId: senderId,
                senderName: senderName,
                messageType: messageType,
                payload: payload,
                timestamp: Date(timeIntervalSince1970: timestampMs / 1000.0)
            )
            messages.append(msg)
        case "removed":
            room = nil
            messages.removeAll()
            currentUserId = nil
            errorMessage = "You were removed from the room."
        case "error":
            errorMessage = json["message"] as? String
        default:
            break
        }
    }
}

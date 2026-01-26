import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject var chat: ChatService
    @Environment(\.colorScheme) private var scheme
    @State private var messageText: String = ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var isSendingMedia = false

    private let maxMediaBytes = 5 * 1024 * 1024

    var body: some View {
        VStack(spacing: 0) {
            header
            participantList
            Divider().opacity(0.2)
            messageList
            inputBar
        }
        .background(Color.black.opacity(scheme == .dark ? 0.9 : 0.05))
        .onChange(of: pickedItem) { newItem in
            guard let newItem else { return }
            Task { await handlePickedMedia(newItem) }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.room?.name ?? "Room")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if let roomId = chat.room?.id {
                        Text("Room ID: \(roomId)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Button("Exit") {
                    chat.leaveRoom()
                }
                .font(.footnote.bold())
                .foregroundColor(.pink)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
    }

    private var participantList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(chat.room?.participants ?? []) { user in
                    HStack(spacing: 6) {
                        Text(user.name)
                            .font(.footnote.bold())
                            .foregroundColor(.white)
                        if chat.room?.ownerId == user.id {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        if chat.room?.ownerId == chat.currentUserId,
                           chat.currentUserId != user.id {
                            Button {
                                chat.removeUser(user.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(chat.messages) { message in
                        MessageBubble(message: message, isMe: message.senderId == chat.currentUserId)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: chat.messages.count) { _ in
                if let last = chat.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            if let error = chat.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $pickedItem, matching: .any(of: [.images, .videos])) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(10)
                }
                .disabled(isSendingMedia)

                TextField("Message", text: $messageText)
                    .textInputAutocapitalization(.sentences)
                    .padding(12)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                Button {
                    let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    chat.sendText(text)
                    messageText = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.black.opacity(0.7))
    }

    private func handlePickedMedia(_ item: PhotosPickerItem) async {
        isSendingMedia = true
        defer { isSendingMedia = false }

        let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })
        if let data = try? await item.loadTransferable(type: Data.self) {
            guard data.count <= maxMediaBytes else {
                chat.errorMessage = "Media must be under 5 MB"
                return
            }
            let base64 = data.base64EncodedString()
            chat.sendMedia(base64, type: isVideo ? .video : .image)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer() }

            VStack(alignment: .leading, spacing: 6) {
                Text(message.senderName)
                    .font(.caption)
                    .foregroundColor(.gray)

                content
            }
            .padding()
            .background(isMe ? Color.pink.opacity(0.35) : Color.white.opacity(0.08))
            .cornerRadius(16)
            .frame(maxWidth: 280, alignment: .leading)

            if !isMe { Spacer() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.messageType {
        case .text:
            Text(message.payload)
                .foregroundColor(.white)
        case .image:
            if let data = Data(base64Encoded: message.payload),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            } else {
                Text("Image unavailable")
                    .foregroundColor(.gray)
            }
        case .video:
            if let url = VideoFileCache.shared.fileURL(for: message.payload) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 180)
                    .cornerRadius(12)
            } else {
                Text("Video unavailable")
                    .foregroundColor(.gray)
            }
        }
    }
}

final class VideoFileCache {
    static let shared = VideoFileCache()
    private init() {}

    func fileURL(for base64: String) -> URL? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}

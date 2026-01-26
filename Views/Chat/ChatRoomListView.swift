import SwiftUI
import UIKit

struct ChatRoomListView: View {
    @EnvironmentObject var chat: ChatService
    @Environment(\.colorScheme) private var scheme

    @State private var userName: String = ""
    @State private var roomName: String = ""
    @State private var roomId: String = ""
    @State private var maxUsers: Int = 2
    @State private var copiedToast: Bool = false

    private var background: some View {
        LinearGradient(
            colors: scheme == .dark ? [Color.black, Color(red: 0.1, green: 0.08, blue: 0.12)] : [Color.white, Color(red: 0.96, green: 0.94, blue: 0.98)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    var body: some View {
        ZStack {
            background

            if chat.room != nil {
                ChatView()
                    .environmentObject(chat)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 6) {
                            Text("Snapchat-Style Chat")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(scheme == .dark ? .white : .black)
                            Text("Create or join a room to chat in real time")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 30)

                        VStack(spacing: 14) {
                            TextField("Your name", text: $userName)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.white.opacity(scheme == .dark ? 0.08 : 0.9))
                                .cornerRadius(12)

                            TextField("Room name (for new room)", text: $roomName)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.white.opacity(scheme == .dark ? 0.08 : 0.9))
                                .cornerRadius(12)

                            HStack {
                                Text("Max users")
                                    .foregroundColor(.gray)
                                Spacer()
                                Stepper(value: $maxUsers, in: 2...10) {
                                    Text("\(maxUsers)")
                                        .foregroundColor(scheme == .dark ? .white : .black)
                                }
                                .labelsHidden()
                            }
                            .padding()
                            .background(Color.white.opacity(scheme == .dark ? 0.08 : 0.9))
                            .cornerRadius(12)

                            TextField("Room ID (to join)", text: $roomId)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white.opacity(scheme == .dark ? 0.08 : 0.9))
                                .cornerRadius(12)
                        }

                        VStack(spacing: 12) {
                            Button {
                                let name = userName.isEmpty ? "User" : userName
                                let room = roomName.isEmpty ? "Chat Room" : roomName
                                chat.createRoom(roomName: room, maxUsers: maxUsers, userName: name)
                            } label: {
                                Text("Create Room")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                            .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button {
                                let name = userName.isEmpty ? "User" : userName
                                chat.joinRoom(roomId: roomId.trimmingCharacters(in: .whitespacesAndNewlines), userName: name)
                            } label: {
                                Text("Join Room")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(scheme == .dark ? 0.12 : 0.95))
                                    .foregroundColor(scheme == .dark ? .white : .black)
                                    .cornerRadius(14)
                            }
                            .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || roomId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        if let lastRoomId = chat.lastRoomId {
                            HStack(spacing: 10) {
                                Text("Created Room ID: \(lastRoomId)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                Button("Copy") {
                                    UIPasteboard.general.string = lastRoomId
                                    copiedToast = true
                                }
                                .font(.footnote.bold())
                                .foregroundColor(.pink)
                            }
                        }

                        if let error = chat.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 450 : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }

            if copiedToast {
                VStack {
                    Text("Room ID copied")
                        .font(.footnote.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, 20)
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copiedToast = false
                    }
                }
            }
        }
    }
}

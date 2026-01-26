import SwiftUI

struct ChatRootView: View {
    @StateObject private var chatService = ChatService()

    var body: some View {
        ChatRoomListView()
            .environmentObject(chatService)
    }
}

#Preview {
    ChatRootView()
}

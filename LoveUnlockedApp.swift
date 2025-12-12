
import SwiftUI
import Combine
@main
struct LoveUnlockedApp: App {
    @StateObject private var posterVM = PosterViewModel()
    @StateObject private var store = StoreKitManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(posterVM)
                .environmentObject(store)
        }
    }
}

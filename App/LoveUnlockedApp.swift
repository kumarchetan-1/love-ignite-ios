
import SwiftUI
import Combine
@main
struct LoveUnlockedApp: App {
    @StateObject private var posterVM = PosterViewModel()
    @StateObject private var store = StoreKitManager.shared
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(posterVM)
                .environmentObject(store)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}

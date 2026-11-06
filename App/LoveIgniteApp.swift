
import SwiftUI
import FirebaseCore

@main
struct LoveIgniteApp: App {
    @StateObject private var posterVM = PosterViewModel()
    @StateObject private var themeManager = ThemeManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(posterVM)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}

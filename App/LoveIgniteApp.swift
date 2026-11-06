
import SwiftUI
import FirebaseCore

@main
struct LoveIgniteApp: App {
    @StateObject private var posterVM = PosterViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var diary = DiaryViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(posterVM)
                .environmentObject(themeManager)
                .environmentObject(diary)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}


import SwiftUI
import Combine
import GoogleSignIn
import FirebaseCore

@main
struct LoveIgniteApp: App {
    @StateObject private var posterVM = PosterViewModel()
    @StateObject private var store = StoreKitManager.shared
    @StateObject private var themeManager = ThemeManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(posterVM)
                .environmentObject(store)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

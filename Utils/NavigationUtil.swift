import SwiftUI
import UIKit

struct NavigationUtil {
    static func present<Content: View>(_ view: Content) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let root = window.rootViewController else { return }
        let hosting = UIHostingController(rootView: view)
        root.present(hosting, animated: true, completion: nil)
    }
}
import Foundation
import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    // Stored user preference: "dark", "light", "system"
    @AppStorage("theme_preference") var themePreference: String = "dark" {
        didSet { objectWillChange.send() }
    }
    
    var colorScheme: ColorScheme? {
        switch themePreference {
        case "dark": return .dark
        case "light": return .light
        default: return nil // system
        }
    }
}


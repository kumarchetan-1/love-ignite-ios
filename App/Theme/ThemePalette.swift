import SwiftUI

enum ThemePalette {
    // Romantic light theme colors
    static let lightStart = Color(red: 1.0, green: 0.92, blue: 0.95)   // soft blush
    static let lightEnd   = Color(red: 0.95, green: 0.80, blue: 0.95)  // lavender blush
    
    // Fallback dark colors reference existing assets
    static func backgroundColors(for scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [lightStart, lightEnd]
        default:
            return [Color("bg1"), Color("bg2")]
        }
    }
    
    static func cardBackground(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light:
            return Color.white.opacity(0.9)
        default:
            return Color("cardBg1")
        }
    }
    
    static func cardOverlay(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light:
            return Color.black.opacity(0.08)
        default:
            return Color.white.opacity(0.08)
        }
    }
    
    static func primaryText(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light:
            return Color.black.opacity(0.85)
        default:
            return .white
        }
    }
    
    static func secondaryText(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light:
            return Color.black.opacity(0.55)
        default:
            return Color.white.opacity(0.7)
        }
    }

    static let neonPurple = Color(red: 0.62, green: 0.36, blue: 1.0)
    static let neonGreen = Color(hue: 0.33, saturation: 0.92, brightness: 0.96)
    static let neonPink = Color(red: 1.0, green: 0.31, blue: 0.64)
}


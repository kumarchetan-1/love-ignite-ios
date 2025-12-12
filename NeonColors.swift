import SwiftUI

// Utility that provides neon-like colors for various difficulty levels.
// It works with either a string difficulty or an enum with a String rawValue.
public enum NeonColors {
    // Prefer bright, saturated colors to achieve a neon glow effect when combined with .neonGlow(_)
    public static func color(for difficulty: Any) -> Color {
        // Try to extract a lowercase string from common types
        let key = difficultyString(difficulty).lowercased()
        switch key {
        case "easy":
            return Color(hue: 0.33, saturation: 0.95, brightness: 0.95) // neon green
        case "medium", "normal":
            return Color(hue: 0.58, saturation: 0.95, brightness: 0.95) // neon blue
        case "hard":
            return Color(hue: 0.92, saturation: 0.95, brightness: 0.95) // neon pink/magenta
        case "extreme", "extrahot", "extra_hot", "extra hot":
            return Color(hue: 0.02, saturation: 0.98, brightness: 0.98) // neon orange/red
        default:
            return Color.cyan // sensible default neon-ish color
        }
    }

    private static func difficultyString(_ value: Any) -> String {
        // If it's already a String
        if let s = value as? String { return s }
        // If it's an enum with a String rawValue
        if let rawVal = (value as AnyObject) as? any RawRepresentable,
           let str = rawVal.rawValue as? String {
            return str
        }
        // Fallback to type name
        return String(describing: value)
    }
}

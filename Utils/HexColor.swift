import SwiftUI
import UIKit

enum HexColor {
    static func color(_ hex: String) -> Color {
        Color(uiColor: uiColor(hex))
    }

    static func uiColor(_ hex: String) -> UIColor {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
            return .label
        }
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

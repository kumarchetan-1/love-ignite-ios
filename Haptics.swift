import Foundation
import UIKit

struct Haptics {
    private static let key = "haptics_enabled"
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }
    
    static func success() {
        guard isEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func impact() {
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }
    
    static func light() {
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func selection() {
        guard isEnabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.selectionChanged()
    }
}

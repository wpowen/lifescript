import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum SoloFeedback {
    static func advance(isEnabled: Bool) {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }

    static func choiceSelected(isEnabled: Bool) {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func chapterEnd(isEnabled: Bool) {
        guard isEnabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

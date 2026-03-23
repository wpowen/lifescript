import SwiftUI

enum SoloMotion {
    static func ambient(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 8).repeatForever(autoreverses: true)
    }

    static func emphasize(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.35)
    }

    static func reading(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.25)
    }

    static func tap(isPressed: Bool) -> Animation {
        .easeOut(duration: isPressed ? 0.12 : 0.18)
    }
}

import SwiftUI

enum SoloTypography {
    static func posterTitle(size: CGFloat = 44, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func sceneHeadline(size: CGFloat = 28, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func chromeTitle(size: CGFloat = 18, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func sectionTitle(size: CGFloat = 24, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static let eyebrow: Font = .caption.weight(.bold)
    static let meta: Font = .footnote.weight(.semibold)
    static let label: Font = .subheadline.weight(.semibold)
    static let body: Font = .body
    static let bodyEmphasis: Font = .body.weight(.medium)
    static let caption: Font = .footnote
    static let detail: Font = .subheadline

    static func reading(emphasis: TextNode.Emphasis?, prefersLargeType: Bool) -> Font {
        switch emphasis {
        case .dramatic:
            return posterTitle(size: prefersLargeType ? 32 : 28, weight: .bold)
        case .whisper:
            return prefersLargeType ? .title3.italic() : .body.italic()
        case .system:
            return prefersLargeType ? .body.monospaced() : .footnote.monospaced()
        case .normal, .none:
            return prefersLargeType ? .title3 : .body
        }
    }
}

import SwiftUI

extension Font {
    // MARK: - Display (Large titles, hero text)
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .serif)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .serif)

    // MARK: - Title (Section headers)
    static let titleLarge = Font.system(size: 24, weight: .semibold)
    static let titleMedium = Font.system(size: 20, weight: .semibold)
    static let titleSmall = Font.system(size: 17, weight: .semibold)

    // MARK: - Body (Reading text)
    static let readingBody = Font.system(size: 18, weight: .regular, design: .serif)
    static let readingBodyLarge = Font.system(size: 20, weight: .regular, design: .serif)

    // MARK: - UI Text
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Labels
    static let labelLarge = Font.system(size: 17, weight: .semibold)
    static let labelMedium = Font.system(size: 15, weight: .medium)
    static let labelSmall = Font.system(size: 13, weight: .medium)

    // MARK: - Caption
    static let captionLarge = Font.system(size: 12, weight: .regular)
    static let captionSmall = Font.system(size: 11, weight: .regular)

    // MARK: - Special
    static let choiceTitle = Font.system(size: 16, weight: .semibold)
    static let statValue = Font.system(size: 22, weight: .bold, design: .rounded)
    static let chapterNumber = Font.system(size: 14, weight: .medium, design: .monospaced)
}

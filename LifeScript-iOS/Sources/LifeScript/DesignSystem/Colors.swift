import SwiftUI

extension Color {
    // MARK: - Semantic Colors (cinematic parchment theme)
    static let backgroundPrimary = Color(light: .hex(0xF4EEE3), dark: .hex(0x10161B))
    static let backgroundSecondary = Color(light: .hex(0xEBE1D0), dark: .hex(0x172027))
    static let backgroundTertiary = Color(light: .hex(0xD9C7AF), dark: .hex(0x23303A))

    static let surfacePrimary = Color(light: .hex(0xFFF8EE), dark: .hex(0x1B252D))
    static let surfaceSecondary = Color(light: .hex(0xF0E5D5), dark: .hex(0x26333D))
    static let surfaceHighlight = Color(light: .hex(0xE2CFAE), dark: .hex(0x334350))

    static let textPrimary = Color(light: .hex(0x221A13), dark: .hex(0xF6EEDF))
    static let textSecondary = Color(light: .hex(0x6E6154), dark: .hex(0xC8B79E))
    static let textTertiary = Color(light: .hex(0x9E8771), dark: .hex(0x887A69))

    // MARK: - Accent Colors (for different satisfaction types)
    static let accentGold = Color(light: .hex(0xCC8F36), dark: .hex(0xE2A24A))
    static let accentCrimson = Color(light: .hex(0xB95D47), dark: .hex(0xD1735B))
    static let accentAmber = Color(light: .hex(0xD9A24A), dark: .hex(0xE4B460))
    static let accentEmerald = Color(light: .hex(0x4A907A), dark: .hex(0x68B19B))
    static let accentViolet = Color(light: .hex(0xB46A78), dark: .hex(0xD98A99))
    static let accentSky = Color(light: .hex(0x4E8FA1), dark: .hex(0x72B6C8))

    // MARK: - Stat Colors
    static let statCombat = Color.accentCrimson
    static let statFame = Color.accentGold
    static let statStrategy = Color.accentSky
    static let statWealth = Color.accentAmber
    static let statCharm = Color.accentViolet
    static let statDarkness = Color(light: .hex(0x6C5A6C), dark: .hex(0x8E7690))
    static let statDestiny = Color(light: .hex(0x4E9A9A), dark: .hex(0x6AB9B9))

    // MARK: - Relationship Colors
    static let relationTrust = Color.accentEmerald
    static let relationAffection = Color(light: .hex(0xFB7185), dark: .hex(0xFB7185))
    static let relationHostility = Color.accentCrimson
    static let relationAwe = Color.accentGold
    static let relationDependence = Color.accentViolet

    // MARK: - Functional
    static let success = Color.accentEmerald
    static let warning = Color.accentAmber
    static let error = Color.accentCrimson
    static let info = Color.accentSky
}

// MARK: - Hex Initializer

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    static func hex(_ hex: UInt, opacity: Double = 1.0) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

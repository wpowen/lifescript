import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let primaryBrand = Color("PrimaryBrand", bundle: .main)
    static let secondaryBrand = Color("SecondaryBrand", bundle: .main)

    // MARK: - Semantic Colors (Dark-first atmospheric theme)
    static let backgroundPrimary = Color(light: .hex(0x0D0D12), dark: .hex(0x0D0D12))
    static let backgroundSecondary = Color(light: .hex(0x16161F), dark: .hex(0x16161F))
    static let backgroundTertiary = Color(light: .hex(0x1E1E2A), dark: .hex(0x1E1E2A))

    static let surfacePrimary = Color(light: .hex(0x1A1A26), dark: .hex(0x1A1A26))
    static let surfaceSecondary = Color(light: .hex(0x232333), dark: .hex(0x232333))
    static let surfaceHighlight = Color(light: .hex(0x2A2A3D), dark: .hex(0x2A2A3D))

    static let textPrimary = Color(light: .hex(0xECECF1), dark: .hex(0xECECF1))
    static let textSecondary = Color(light: .hex(0x9898A8), dark: .hex(0x9898A8))
    static let textTertiary = Color(light: .hex(0x5C5C6E), dark: .hex(0x5C5C6E))

    // MARK: - Accent Colors (for different satisfaction types)
    static let accentGold = Color(light: .hex(0xFFB800), dark: .hex(0xFFB800))
    static let accentCrimson = Color(light: .hex(0xFF3B4A), dark: .hex(0xFF3B4A))
    static let accentAmber = Color(light: .hex(0xFF8C00), dark: .hex(0xFF8C00))
    static let accentEmerald = Color(light: .hex(0x00D68F), dark: .hex(0x00D68F))
    static let accentViolet = Color(light: .hex(0xA855F7), dark: .hex(0xA855F7))
    static let accentSky = Color(light: .hex(0x38BDF8), dark: .hex(0x38BDF8))

    // MARK: - Stat Colors
    static let statCombat = Color.accentCrimson
    static let statFame = Color.accentGold
    static let statStrategy = Color.accentSky
    static let statWealth = Color.accentAmber
    static let statCharm = Color.accentViolet
    static let statDarkness = Color(light: .hex(0x6B21A8), dark: .hex(0x6B21A8))
    static let statDestiny = Color(light: .hex(0x06B6D4), dark: .hex(0x06B6D4))

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

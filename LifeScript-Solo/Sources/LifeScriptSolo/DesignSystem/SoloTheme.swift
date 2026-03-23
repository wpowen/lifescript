import SwiftUI

private struct SoloPalette {
    let background: Color
    let backgroundAlt: Color
    let surface: Color
    let surfaceRaised: Color
    let gold: Color
    let crimson: Color
    let jade: Color
    let ink: Color
    let warmInk: Color
    let muted: Color
    let heroStart: Color
    let heroEnd: Color
}

enum SoloTheme {
    private static var palette: SoloPalette {
        switch SoloStoryConfig.branding.palettePreset {
        case .ashCrimson:
            return SoloPalette(
                background: Color(red: 0.02, green: 0.02, blue: 0.04),
                backgroundAlt: Color(red: 0.08, green: 0.07, blue: 0.10),
                surface: Color(red: 0.12, green: 0.10, blue: 0.12),
                surfaceRaised: Color(red: 0.18, green: 0.13, blue: 0.14),
                gold: Color(red: 0.92, green: 0.74, blue: 0.44),
                crimson: Color(red: 0.79, green: 0.28, blue: 0.24),
                jade: Color(red: 0.53, green: 0.73, blue: 0.69),
                ink: Color(red: 0.97, green: 0.95, blue: 0.92),
                warmInk: Color(red: 0.96, green: 0.84, blue: 0.72),
                muted: Color.white.opacity(0.66),
                heroStart: Color(red: 0.93, green: 0.69, blue: 0.37),
                heroEnd: Color(red: 0.69, green: 0.21, blue: 0.18)
            )
        case .emberGold:
            return SoloPalette(
                background: Color(red: 0.03, green: 0.04, blue: 0.07),
                backgroundAlt: Color(red: 0.11, green: 0.08, blue: 0.11),
                surface: Color(red: 0.13, green: 0.10, blue: 0.14),
                surfaceRaised: Color(red: 0.20, green: 0.14, blue: 0.19),
                gold: Color(red: 0.94, green: 0.78, blue: 0.49),
                crimson: Color(red: 0.82, green: 0.33, blue: 0.28),
                jade: Color(red: 0.45, green: 0.79, blue: 0.68),
                ink: Color(red: 0.97, green: 0.95, blue: 0.90),
                warmInk: Color(red: 0.99, green: 0.89, blue: 0.70),
                muted: Color.white.opacity(0.68),
                heroStart: Color(red: 0.95, green: 0.79, blue: 0.52),
                heroEnd: Color(red: 0.78, green: 0.35, blue: 0.26)
            )
        case .moonJade:
            return SoloPalette(
                background: Color(red: 0.03, green: 0.07, blue: 0.08),
                backgroundAlt: Color(red: 0.05, green: 0.12, blue: 0.13),
                surface: Color(red: 0.08, green: 0.15, blue: 0.16),
                surfaceRaised: Color(red: 0.12, green: 0.21, blue: 0.22),
                gold: Color(red: 0.82, green: 0.90, blue: 0.74),
                crimson: Color(red: 0.57, green: 0.34, blue: 0.31),
                jade: Color(red: 0.42, green: 0.83, blue: 0.72),
                ink: Color(red: 0.95, green: 0.98, blue: 0.95),
                warmInk: Color(red: 0.77, green: 0.92, blue: 0.85),
                muted: Color.white.opacity(0.66),
                heroStart: Color(red: 0.45, green: 0.83, blue: 0.72),
                heroEnd: Color(red: 0.18, green: 0.46, blue: 0.43)
            )
        case .royalPlum:
            return SoloPalette(
                background: Color(red: 0.05, green: 0.03, blue: 0.08),
                backgroundAlt: Color(red: 0.10, green: 0.05, blue: 0.14),
                surface: Color(red: 0.15, green: 0.09, blue: 0.18),
                surfaceRaised: Color(red: 0.23, green: 0.13, blue: 0.25),
                gold: Color(red: 0.96, green: 0.75, blue: 0.63),
                crimson: Color(red: 0.86, green: 0.39, blue: 0.53),
                jade: Color(red: 0.58, green: 0.72, blue: 0.85),
                ink: Color(red: 0.98, green: 0.94, blue: 0.97),
                warmInk: Color(red: 0.95, green: 0.82, blue: 0.86),
                muted: Color.white.opacity(0.68),
                heroStart: Color(red: 0.82, green: 0.42, blue: 0.63),
                heroEnd: Color(red: 0.47, green: 0.24, blue: 0.59)
            )
        case .sapphireMist:
            return SoloPalette(
                background: Color(red: 0.03, green: 0.05, blue: 0.09),
                backgroundAlt: Color(red: 0.06, green: 0.10, blue: 0.16),
                surface: Color(red: 0.10, green: 0.14, blue: 0.20),
                surfaceRaised: Color(red: 0.14, green: 0.20, blue: 0.27),
                gold: Color(red: 0.83, green: 0.89, blue: 0.99),
                crimson: Color(red: 0.58, green: 0.54, blue: 0.92),
                jade: Color(red: 0.45, green: 0.74, blue: 0.95),
                ink: Color(red: 0.96, green: 0.98, blue: 1.00),
                warmInk: Color(red: 0.82, green: 0.90, blue: 0.99),
                muted: Color.white.opacity(0.68),
                heroStart: Color(red: 0.48, green: 0.74, blue: 0.98),
                heroEnd: Color(red: 0.30, green: 0.44, blue: 0.86)
            )
        }
    }

    static var background: Color { palette.background }
    static var backgroundAlt: Color { palette.backgroundAlt }
    static var surface: Color { palette.surface }
    static var surfaceRaised: Color { palette.surfaceRaised }
    static var gold: Color { palette.gold }
    static var crimson: Color { palette.crimson }
    static var jade: Color { palette.jade }
    static var ink: Color { palette.ink }
    static var warmInk: Color { palette.warmInk }
    static var muted: Color { palette.muted }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [palette.heroStart, palette.heroEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func displayFont(size: CGFloat, weight: Font.Weight) -> Font {
        SoloTypography.posterTitle(size: size, weight: weight)
    }

    static func navigationTitleFont(size: CGFloat = 19) -> Font {
        SoloTypography.chromeTitle(size: size, weight: .semibold)
    }

    static func sectionTitleFont(size: CGFloat = 22) -> Font {
        SoloTypography.sectionTitle(size: size, weight: .semibold)
    }

    static func accentColor(for preset: SoloPalettePreset) -> Color {
        switch preset {
        case .ashCrimson:
            return crimson
        case .emberGold:
            return gold
        case .moonJade:
            return jade
        case .royalPlum:
            return crimson
        case .sapphireMist:
            return warmInk
        }
    }
}

// Animated atmospheric backdrop — used on every screen in the app.
// Provides cinematic depth: slow-breathing multi-glow, no GeometryReader
// so ignoresSafeArea propagates correctly into the nav bar area.
struct SoloBackdrop: View {
    @AppStorage("solo.reduceMotion") private var reduceMotion = false

    var body: some View {
        if reduceMotion {
            staticView.ignoresSafeArea()
        } else {
            TimelineView(.animation(minimumInterval: 0.05)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                dynamicView(t: t)
            }
            .ignoresSafeArea()
        }
    }

    private var staticView: some View { dynamicView(t: 0) }

    @ViewBuilder
    private func dynamicView(t: Double) -> some View {
        // Three independent slow breath cycles (never in sync)
        let breathA = sin(t * .pi / 6.0)  * 0.5 + 0.5   // ~12s
        let breathB = sin(t * .pi / 8.5  + 2.1) * 0.5 + 0.5  // ~17s
        let breathC = sin(t * .pi / 11.5 + 4.7) * 0.5 + 0.5  // ~23s

        baseColor
            // ── Top-right ambient glow (primary theme colour) ──────────────
            .overlay(alignment: .top) {
                RadialGradient(
                    colors: [topGlow.opacity(0.22 + breathA * 0.16), Color.clear],
                    center: .center, startRadius: 0, endRadius: 320
                )
                .frame(width: 560, height: 560)
                .offset(x: 80 + breathA * 22, y: -200)
            }
            // ── Mid-left secondary glow ────────────────────────────────────
            .overlay(alignment: .center) {
                RadialGradient(
                    colors: [midGlow.opacity(0.16 + breathB * 0.12), Color.clear],
                    center: .center, startRadius: 0, endRadius: 280
                )
                .frame(width: 440, height: 440)
                .offset(x: -130 - breathB * 18, y: -60)
            }
            // ── Bottom warmth glow ─────────────────────────────────────────
            .overlay(alignment: .bottom) {
                RadialGradient(
                    colors: [bottomGlow.opacity(0.20 + breathC * 0.14), Color.clear],
                    center: .center, startRadius: 0, endRadius: 300
                )
                .frame(width: 500, height: 420)
                .offset(x: 30 + breathC * 20, y: 200)
            }
            // ── Subtle top film-burn (not black — theme colour darkened) ───
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [topBurn.opacity(0.55), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                .ignoresSafeArea()
            }
    }

    // Base colour: not pure black — slight warm/cool tint by theme
    private var baseColor: Color {
        switch SoloStoryConfig.branding.palettePreset {
        case .ashCrimson:   Color(red: 0.06, green: 0.02, blue: 0.05)
        case .moonJade:     Color(red: 0.02, green: 0.05, blue: 0.07)
        case .royalPlum:    Color(red: 0.05, green: 0.02, blue: 0.09)
        case .emberGold:    Color(red: 0.07, green: 0.03, blue: 0.03)
        case .sapphireMist: Color(red: 0.02, green: 0.03, blue: 0.09)
        }
    }
    // Top edge burn — theme-tinted dark, NOT black
    private var topBurn: Color {
        switch SoloStoryConfig.branding.palettePreset {
        case .ashCrimson:   Color(red: 0.12, green: 0.03, blue: 0.06)
        case .moonJade:     Color(red: 0.02, green: 0.08, blue: 0.12)
        case .royalPlum:    Color(red: 0.10, green: 0.02, blue: 0.16)
        case .emberGold:    Color(red: 0.14, green: 0.05, blue: 0.03)
        case .sapphireMist: Color(red: 0.02, green: 0.05, blue: 0.16)
        }
    }
    private var topGlow: Color {
        switch SoloStoryConfig.branding.palettePreset {
        case .ashCrimson:   Color(red: 0.80, green: 0.30, blue: 0.10)
        case .moonJade:     Color(red: 0.22, green: 0.72, blue: 0.62)
        case .royalPlum:    Color(red: 0.62, green: 0.20, blue: 0.88)
        case .emberGold:    Color(red: 0.92, green: 0.60, blue: 0.14)
        case .sapphireMist: Color(red: 0.28, green: 0.58, blue: 0.96)
        }
    }
    private var midGlow: Color {
        switch SoloStoryConfig.branding.palettePreset {
        case .ashCrimson:   Color(red: 0.62, green: 0.16, blue: 0.08)
        case .moonJade:     Color(red: 0.12, green: 0.54, blue: 0.50)
        case .royalPlum:    Color(red: 0.46, green: 0.12, blue: 0.70)
        case .emberGold:    Color(red: 0.84, green: 0.44, blue: 0.06)
        case .sapphireMist: Color(red: 0.18, green: 0.42, blue: 0.84)
        }
    }
    private var bottomGlow: Color {
        switch SoloStoryConfig.branding.palettePreset {
        case .ashCrimson:   Color(red: 0.58, green: 0.14, blue: 0.06)
        case .moonJade:     Color(red: 0.10, green: 0.44, blue: 0.42)
        case .royalPlum:    Color(red: 0.40, green: 0.10, blue: 0.64)
        case .emberGold:    Color(red: 0.74, green: 0.36, blue: 0.04)
        case .sapphireMist: Color(red: 0.14, green: 0.34, blue: 0.74)
        }
    }
}

private struct SoloCardModifier: ViewModifier {
    let prominence: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                SoloTheme.surface.opacity(0.98),
                                SoloTheme.surfaceRaised.opacity(0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08 + (prominence * 0.08)), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 12)
            )
    }
}

private struct SoloHeroCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                SoloTheme.surfaceRaised.opacity(0.94),
                                SoloTheme.surface.opacity(0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        SoloTheme.gold.opacity(0.26),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: SoloTheme.gold.opacity(0.10), radius: 22, x: 0, y: 14)
            )
    }
}

extension View {
    func soloCard(prominence: Double = 0) -> some View {
        modifier(SoloCardModifier(prominence: prominence))
    }

    func soloHeroCard() -> some View {
        modifier(SoloHeroCardModifier())
    }
}

struct SoloMetricBar: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundStyle(SoloTheme.muted)
                Spacer()
                Text("\(value)")
                    .foregroundStyle(SoloTheme.ink)
            }
            .font(.footnote.weight(.semibold))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.92),
                                    tint.opacity(0.56)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * (Double(value) / Double(ProtagonistStats.maxValue)))
                }
            }
            .frame(height: 8)
        }
    }
}

private struct SoloNavigationTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(SoloTheme.navigationTitleFont())
            .foregroundStyle(SoloTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }
}

extension View {
    func soloNavigationChrome(title: String) -> some View {
        toolbar {
            ToolbarItem(placement: .principal) {
                SoloNavigationTitle(title: title)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

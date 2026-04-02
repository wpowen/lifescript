import SwiftUI

struct SoloEntryHeroScene: View {
    let book: Book
    let snapshot: SoloEntrySnapshot
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let readingRoute: SoloRoute?
    let openWorld: () -> Void
    let animationsEnabled: Bool

    @AppStorage("solo.reduceMotion") private var reduceMotion = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackdrop

            // 内容叠层
            contentStack
        }
        .frame(maxWidth: .infinity, minHeight: isTianjiluVisualEnabled ? 620 : 520)
    }

    // MARK: - Content anchored to bottom (Netflix style)
    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 140)

            // Eyebrow label
            Text(snapshot.branding.entryEyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(3.5)
                .foregroundStyle(SoloTheme.gold)
                .padding(.bottom, 14)

            // Title — xianxia calligraphic style for 天机录
            if isTianjiluVisualEnabled {
                tianjiluCalligraphicTitle
                    .padding(.bottom, 10)
            } else {
                Text(SoloLocalization.localized(book.title))
                    .font(SoloTypography.posterTitle(size: 56))
                    .foregroundStyle(SoloTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
            }

            // Promise tagline
            Text(snapshot.branding.promise)
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(SoloTheme.ink.opacity(0.78))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 18)

            featureStatStrip
                .padding(.bottom, 12)

            if isTianjiluVisualEnabled {
                volumeSpotlight
                    .padding(.bottom, 14)
            }

            Text(snapshot.branding.landing.identityLabel + " · " + snapshot.currentIdentityValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.muted)
                .padding(.bottom, 8)

            Text(SoloLocalization.format("天命值 %d · %@", snapshot.destinyStatus.value, snapshot.destinyStatus.headline))
                .font(.caption.weight(.semibold))
                .foregroundStyle(destinyAccent.opacity(0.88))
                .padding(.bottom, 22)

            // Primary action — portal threshold button
            primaryPortalButton
                .padding(.bottom, 10)

            // Secondary action — ghost
            Button(action: openWorld) {
                HStack(spacing: 10) {
                    Image(systemName: "map")
                        .font(.caption.weight(.semibold))
                    Text(secondaryActionTitle)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.semibold))
                        .opacity(0.45)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .foregroundStyle(SoloTheme.ink.opacity(0.72))
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)

            // Hook teaser
            Text(snapshot.branding.atmosphereLine)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.warmInk.opacity(0.75))
                .lineSpacing(4)
                .lineLimit(2)
                .padding(.bottom, 36)
        }
        .padding(.horizontal, 24)
    }

    private var featureStatStrip: some View {
        HStack(spacing: 0) {
            statCapsule(
                icon: "book.pages",
                value: SoloLocalization.format("%d章", snapshot.plannedChapterCount),
                label: SoloLocalization.localized("已收录"),
                tint: SoloTheme.gold
            )

            statDivider

            statCapsule(
                icon: "arrow.triangle.branch",
                value: marketedEndingCount.map { SoloLocalization.format("%d结局", $0) }
                    ?? SoloLocalization.localized("多结局"),
                label: SoloLocalization.localized("结局"),
                tint: SoloTheme.crimson
            )

            statDivider

            statCapsule(
                icon: "hand.tap",
                value: SoloLocalization.localized("互动式"),
                label: SoloLocalization.localized("阅读方式"),
                tint: SoloTheme.jade
            )
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.36))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func statCapsule(
        icon: String,
        value: String,
        label: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint.opacity(0.85))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SoloTheme.ink)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(SoloTheme.muted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 20)
    }

    // MARK: - Portal Entry Button

    private var primaryPortalButton: some View {
        primaryPortalControl(pulse: portalPulse)
    }

    @ViewBuilder
    private func primaryPortalControl(pulse: Double) -> some View {
        if let readingRoute {
            NavigationLink(value: readingRoute) {
                portalButtonLabel(pulse: pulse)
            }
            .buttonStyle(.plain)
        } else {
            portalButtonLabel(pulse: pulse)
                .opacity(0.58)
        }
    }

    private func portalButtonLabel(pulse: Double) -> some View {
            VStack(alignment: .leading, spacing: 0) {
                // Eyebrow — ceremony / threshold language
                Text(SoloLocalization.localized("点击踏入"))
                    .font(.caption2.weight(.bold))
                    .tracking(5)
                    .foregroundStyle(Color.white.opacity(0.32 + pulse * 0.18))
                    .padding(.bottom, 12)

                // Main CTA row
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(SoloTheme.gold.opacity(0.18 + pulse * 0.14))
                            .frame(width: 42, height: 42)
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SoloTheme.gold)
                    }
                    Text(primaryActionTitle)
                        .font(SoloTypography.posterTitle(size: 26))
                        .foregroundStyle(SoloTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.bottom, 12)

                // Thin gold divider — animated width
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [SoloTheme.gold.opacity(0.55 + pulse * 0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.bottom, 10)

                // Destiny status line
                Text(snapshot.destinyStatusLine)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SoloTheme.warmInk.opacity(0.55))
                    .lineLimit(1)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Color.black.opacity(0.55)
                    RadialGradient(
                        colors: [
                            SoloTheme.crimson.opacity(0.12 + pulse * 0.16),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 220
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                SoloTheme.gold.opacity(0.20 + pulse * 0.55),
                                SoloTheme.crimson.opacity(0.14 + pulse * 0.20),
                                Color.white.opacity(0.04 + pulse * 0.07),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: SoloTheme.crimson.opacity(0.18 + pulse * 0.26),
                radius: CGFloat(10 + pulse * 14),
                x: 0, y: 5
            )
    }

    private var portalPulse: Double {
        if reduceMotion { return 0.42 }
        return animationsEnabled ? 0.74 : 0.42
    }

    private var marketedEndingCount: Int? {
        switch book.id {
        case "天机录":
            return 5
        default:
            return nil
        }
    }

    @ViewBuilder
    private var heroBackdrop: some View {
        if isTianjiluVisualEnabled {
            ZStack {
                TianjiluHomeScene(
                    illustration: TianjiluArtworkCatalog.homeHeroMaster,
                    animationsEnabled: animationsEnabled
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.26),
                        Color.black.opacity(0.76),
                        Color.black,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        SoloTheme.gold.opacity(0.16),
                        SoloTheme.crimson.opacity(0.10),
                        Color.clear,
                    ],
                    center: UnitPoint(x: 0.72, y: 0.22),
                    startRadius: 10,
                    endRadius: 320
                )
            }
            .clipped()
        } else {
            SoloHeroArtwork(preset: snapshot.branding.palettePreset)
        }
    }

    private var volumeSpotlight: some View {
        let volume = TianjiluArtworkCatalog.volume(for: max(snapshot.progress.currentChapterNumber, 1))

        return HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                SoloBundledArtworkImage(resourceName: volume.cover.resourceName, contentMode: .fill)
                    .frame(width: 86, height: 124)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(volume.localizedVolumeLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SoloTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(SoloLocalization.localized("当前卷面"))
                    .font(.caption2.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(SoloTheme.gold)
                Text(volume.cover.localizedSubtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SoloTheme.ink)
                if let caption = volume.cover.localizedCaption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(SoloTheme.warmInk)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(
            ZStack {
                Color.white.opacity(0.06)
                if isTianjiluVisualEnabled {
                    SoloBundledArtworkImage(
                        resourceName: TianjiluArtworkCatalog.homeHeroMaster.resourceName,
                        contentMode: .fill
                    )
                    .opacity(0.16)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var destinyAccent: Color {
        switch snapshot.destinyStatus.level {
        case .abundant:
            return SoloTheme.jade
        case .steady:
            return SoloTheme.gold
        case .strained, .critical:
            return SoloTheme.crimson
        }
    }

    private var isTianjiluVisualEnabled: Bool {
        book.id == "天机录"
    }

    // MARK: - 天机录 Calligraphic Title

    private var isCJKLocale: Bool {
        let lang = Locale.current.language.languageCode?.identifier ?? ""
        return ["zh", "ja", "ko"].contains(lang)
    }

    private var tianjiluCalligraphicTitle: some View {
        VStack(spacing: 0) {
            topOrnamentLine
                .padding(.bottom, 8)

            if isCJKLocale {
                let localizedTitle = SoloLocalization.localized("天机录")
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(localizedTitle.enumerated()), id: \.offset) { index, char in
                        let sizes: [CGFloat] = [62, 72, 58]
                        let offsets: [CGFloat] = [-2, 0, 2]
                        calligraphyChar(
                            String(char),
                            size: index < sizes.count ? sizes[index] : 64,
                            yOffset: index < offsets.count ? offsets[index] : 0
                        )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    SoloTheme.gold.opacity(0.40 + portalPulse * 0.20),
                                    SoloTheme.jade.opacity(0.20),
                                    Color.clear,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5)
                        .offset(y: 42)
                )
                .padding(.bottom, 10)
            } else {
                Text(SoloLocalization.localized("天机录"))
                    .font(.system(size: 56, weight: .black, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.86, blue: 0.52),
                                Color(red: 0.88, green: 0.72, blue: 0.38),
                                Color(red: 0.50, green: 0.82, blue: 0.76),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: SoloTheme.gold.opacity(0.55 + portalPulse * 0.30), radius: 12, x: 0, y: 4)
                    .shadow(color: SoloTheme.jade.opacity(0.20 + portalPulse * 0.10), radius: 24, x: 0, y: 0)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
            }

            bottomOrnamentLine
        }
    }

    private func calligraphyChar(_ char: String, size: CGFloat, yOffset: CGFloat) -> some View {
        Text(char)
            .font(.system(size: size, weight: .black, design: .serif))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.86, blue: 0.52),
                        Color(red: 0.88, green: 0.72, blue: 0.38),
                        Color(red: 0.50, green: 0.82, blue: 0.76),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: SoloTheme.gold.opacity(0.55 + portalPulse * 0.30), radius: 12, x: 0, y: 4)
            .shadow(color: SoloTheme.jade.opacity(0.20 + portalPulse * 0.10), radius: 24, x: 0, y: 0)
            .offset(y: yOffset)
    }

    private var topOrnamentLine: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, SoloTheme.gold.opacity(0.50)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 48, height: 1)

            Image(systemName: "diamond.fill")
                .font(.system(size: 5))
                .foregroundStyle(SoloTheme.gold.opacity(0.72))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [SoloTheme.gold.opacity(0.50), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 48, height: 1)
        }
    }

    private var bottomOrnamentLine: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, SoloTheme.jade.opacity(0.30)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 36, height: 0.8)

            Text(SoloLocalization.localized("谋天改命"))
                .font(.system(size: 10, weight: .medium))
                .tracking(4)
                .foregroundStyle(SoloTheme.gold.opacity(0.48 + portalPulse * 0.12))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [SoloTheme.jade.opacity(0.30), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 36, height: 0.8)
        }
    }
}

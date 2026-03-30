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
        .frame(maxWidth: .infinity, minHeight: isTianjiluVisualEnabled ? 780 : 680)
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
                Text(book.title)
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

            featureMarquee
                .padding(.bottom, 18)

            // Meta chips row
            HStack(spacing: 8) {
                cinemaChip(book.genre.displayName, SoloTheme.gold)
                cinemaChip(serialChipText, SoloTheme.crimson)
                cinemaChip(interactionChipText, SoloTheme.jade)
            }
            .padding(.bottom, 6)

            if isTianjiluVisualEnabled {
                volumeSpotlight
                    .padding(.bottom, 14)
            }

            Text(snapshot.branding.landing.identityLabel + " · " + snapshot.currentIdentityValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.muted)
                .padding(.bottom, 8)

            Text("天命值 \(snapshot.destinyStatus.value) · \(snapshot.destinyStatus.headline)")
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

    private var featureMarquee: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ForEach(heroCompactHighlights) { highlight in
                    featureCard(highlight)
                }
            }

            if let wideHighlight = heroWideHighlight {
                featureCard(wideHighlight)
            }
        }
    }

    private func featureCard(_ highlight: HeroFeatureHighlight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(highlight.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(highlight.tint.opacity(0.90))

            Text(highlight.value)
                .font(SoloTypography.sceneHeadline(size: highlight.isWide ? 24 : 22))
                .foregroundStyle(SoloTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(highlight.detail)
                .font(.caption)
                .foregroundStyle(SoloTheme.warmInk.opacity(0.80))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: highlight.isWide ? 94 : 118,
            alignment: .topLeading
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(highlight.isWide ? 0.42 : 0.36))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(highlight.tint.opacity(0.18), lineWidth: 1)
        )
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
                Text("点击踏入")
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

    private var heroCompactHighlights: [HeroFeatureHighlight] {
        [
            HeroFeatureHighlight(
                id: "chapter-scale",
                title: SoloLocalization.localized("已收录章节"),
                value: SoloLocalization.format("%d 章", snapshot.plannedChapterCount),
                detail: SoloLocalization.localized("当前版本完整接入"),
                tint: SoloTheme.gold,
                isWide: false
            ),
            HeroFeatureHighlight(
                id: "ending-scale",
                title: marketedEndingCount == nil
                    ? SoloLocalization.localized("互动结构")
                    : SoloLocalization.localized("结局规模"),
                value: marketedEndingCount.map { SoloLocalization.format("%d 个结局", $0) }
                    ?? interactionModeLabel,
                detail: marketedEndingCount == nil
                    ? SoloLocalization.localized("路线、人物与章节反馈会跟着你的选择偏转")
                    : SoloLocalization.localized("关键选择会把命途推向不同终局"),
                tint: SoloTheme.crimson,
                isWide: false
            ),
        ]
    }

    private var heroWideHighlight: HeroFeatureHighlight? {
        HeroFeatureHighlight(
            id: "interactive-fiction",
            title: SoloLocalization.localized("阅读方式"),
            value: SoloLocalization.localized("互动式小说"),
            detail: SoloLocalization.localized("不是翻页旁观，你的选择会改写人物关系、路线反馈与命途走向"),
            tint: SoloTheme.jade,
            isWide: true
        )
    }

    private var marketedEndingCount: Int? {
        switch book.id {
        case "天机录":
            return 5
        default:
            return nil
        }
    }

    private var interactionModeLabel: String {
        if book.interactionTags.contains("多结局") {
            return SoloLocalization.localized("多结局分支")
        }
        return interactionChipText
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

                Text(volume.volumeLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SoloTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("当前卷面")
                    .font(.caption2.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(SoloTheme.gold)
                Text(volume.cover.subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SoloTheme.ink)
                if let caption = volume.cover.caption {
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

    private func cinemaChip(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.14))
            )
    }

    private var serialChipText: String {
        guard snapshot.generatedChapterCount > 0 else { return "章节接入中" }
        return "\(snapshot.generatedChapterCount)\(snapshot.branding.chapterUnitName)内容"
    }

    private var interactionChipText: String {
        book.interactionTags.first ?? "多结局"
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

    private var tianjiluCalligraphicTitle: some View {
        VStack(spacing: 0) {
            topOrnamentLine
                .padding(.bottom, 8)

            HStack(alignment: .bottom, spacing: 6) {
                calligraphyChar("天", size: 62, yOffset: -2)
                calligraphyChar("机", size: 72, yOffset: 0)
                calligraphyChar("录", size: 58, yOffset: 2)
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

            Text("谋天改命")
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

private struct HeroFeatureHighlight: Identifiable {
    let id: String
    let title: String
    let value: String
    let detail: String
    let tint: Color
    let isWide: Bool
}

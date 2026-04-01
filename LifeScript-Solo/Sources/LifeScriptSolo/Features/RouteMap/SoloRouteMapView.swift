import SwiftUI

struct SoloRouteMapView: View {
    let book: Book
    let progressSummary: SoloProgressSummary
    let routeSnapshot: SoloRouteMapSnapshot
    let hubSnapshot: SoloRouteMapHubSnapshot
    let openDestinyAtlas: () -> Void
    let openHumanHearts: () -> Void
    let openDarklineBoard: () -> Void
    private let branding = SoloStoryConfig.branding

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    progressStrip
                    currentFocusPanel
                    navigationDeck
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .safeAreaInset(edge: .top) {
                Color.clear
                    .frame(height: 14)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .soloStoryChrome(title: branding.routeMapTitle, kicker: SoloLocalization.localized("总览"))
        .onAppear {
            SoloArtworkLibrary.preload(TianjiluArtworkCatalog.darklineArtifact.resourceName)
        }
    }

    private var progressStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(book.id == "天机录" ? SoloLocalization.localized("命途探索进度") : SoloLocalization.localized("探索进度"))
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.gold)
                Spacer()
                Text(SoloLocalization.format("%d / %d 已走完", progressSummary.completedChapterCount, progressSummary.totalChapterCount))
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.muted)
            }

            GeometryReader { geo in
                let ratio = CGFloat(progressSummary.completedChapterCount) / CGFloat(max(progressSummary.totalChapterCount, 1))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SoloTheme.crimson, SoloTheme.gold, SoloTheme.jade],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * ratio, height: 4)
                }
            }
            .frame(height: 4)

            HStack(spacing: 20) {
                progressPill(value: "\(progressSummary.completedChapterCount)", label: SoloLocalization.localized("章已走完"), tint: SoloTheme.jade)
                progressPill(value: "\(hubSnapshot.heartsCard.badge)", label: SoloLocalization.localized("人心盘面"), tint: SoloTheme.gold)
                progressPill(value: "\(hubSnapshot.darklineCard.badge)", label: SoloLocalization.localized("暗线信号"), tint: SoloTheme.crimson)
            }

            if routeSnapshot.generatedChapterCount < routeSnapshot.plannedChapterCount {
                Text(SoloLocalization.format("当前版本已收录 %d / %d %@，命途图只展示本次内容包已开放部分。", routeSnapshot.generatedChapterCount, routeSnapshot.plannedChapterCount, branding.chapterUnitName))
                    .font(.caption)
                    .foregroundStyle(SoloTheme.muted)
            }
        }
        .padding(18)
        .soloPanel(.hero, prominence: 0.14)
    }

    private var currentFocusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.id == "天机录" ? SoloLocalization.localized("当前命局") : SoloLocalization.localized("当前局面"))
                    .font(SoloTypography.meta)
                    .foregroundStyle(SoloTheme.gold)
                Text(routeSnapshot.currentStageTitle ?? SoloLocalization.localized("天机未显"))
                    .font(SoloTypography.sceneHeadline(size: 24))
                    .foregroundStyle(SoloTheme.ink)
            }

            if book.id == "天机录" {
                SoloArtworkCard(
                    asset: currentVolumeVisual.banner,
                    height: 180,
                    contentMode: .fill,
                    tint: SoloTheme.gold,
                    cornerRadius: 18
                )
            }

            strategicDeck(
                title: book.id == "天机录" ? SoloLocalization.localized("眼前破局点") : SoloLocalization.localized("眼前关键点"),
                headline: hubSnapshot.currentObjective,
                body: hubSnapshot.stageLine,
                footer: hubSnapshot.pressureLine,
                tint: SoloTheme.jade
            )

            strategicDeck(
                title: SoloLocalization.localized("天命状态"),
                headline: hubSnapshot.destinyStatus.headline,
                body: hubSnapshot.destinyStatus.detail,
                footer: hubSnapshot.destinySummary,
                tint: destinyTint
            )
        }
        .padding(18)
        .soloPanel(.stage, prominence: 0.18)
    }

    private var navigationDeck: some View {
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(SoloLocalization.localized("从哪一面入局"))
                    .font(SoloTypography.sectionTitle(size: 22))
                    .foregroundStyle(SoloTheme.ink)
                Text(SoloLocalization.localized("命途看走势，人心看立场，暗线看水下回声。三张入口卡都是可点击的，进入后会切到独立页面。"))
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.warmInk)
                    .lineSpacing(5)
            }
            .padding(20)
            .soloPanel(.hero, prominence: 0.12)

            perspectiveCard(
                icon: "dot.scope",
                card: hubSnapshot.destinyCard,
                tint: SoloTheme.jade,
                action: openDestinyAtlas
            )

            perspectiveCard(
                icon: "person.2.fill",
                card: hubSnapshot.heartsCard,
                tint: SoloTheme.gold,
                action: openHumanHearts
            )

            perspectiveCard(
                icon: "eye.trianglebadge.exclamationmark",
                card: hubSnapshot.darklineCard,
                tint: SoloTheme.crimson,
                action: openDarklineBoard
            )
        }
    }

    private func perspectiveCard(
        icon: String,
        card: SoloRouteMapHubCard,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        let artwork = portalArtwork(for: card.id)

        return Button(action: action) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    SoloBundledArtworkImage(resourceName: artwork.resourceName, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 176)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.10),
                                    Color.black.opacity(0.18),
                                    Color.black.opacity(0.86),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(card.title, systemImage: icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(tint)
                            Spacer()
                            labelChip(text: card.badge, tint: tint)
                        }

                        Text(card.subtitle)
                            .font(SoloTypography.sceneHeadline(size: 22))
                            .foregroundStyle(SoloTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(card.statusLine)
                            .font(.caption)
                            .foregroundStyle(SoloTheme.warmInk)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.callToAction)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SoloTheme.ink)
                        Text(artwork.title)
                            .font(.caption)
                            .foregroundStyle(tint.opacity(0.92))
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.04))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(tint.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: tint.opacity(0.10), radius: 16, x: 0, y: 8)
    }

    private func strategicDeck(title: String, headline: String, body: String, footer: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(SoloTypography.meta)
                .foregroundStyle(tint)
            Text(headline)
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(SoloTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(body)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Text(footer)
                .font(.caption)
                .foregroundStyle(tint.opacity(0.84))
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .soloPanel(.evidence, prominence: 0.16)
    }

    private func intelTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SoloTheme.muted)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func progressPill(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(SoloTypography.meta)
                .foregroundStyle(tint)
            Text(label)
                .font(.caption2)
                .foregroundStyle(SoloTheme.muted)
        }
    }

    private func labelChip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.12)))
    }

    private func portalArtwork(for id: String) -> SoloArtworkAsset {
        if book.id == "天机录" {
            switch id {
            case "destiny":
                return currentVolumeVisual.banner
            case "hearts":
                return TianjiluArtworkCatalog.dossierBackdrop
            case "darkline":
                return TianjiluArtworkCatalog.darklineArtifact
            default:
                return TianjiluArtworkCatalog.routeBanner
            }
        }

        return SoloArtworkAsset(
            resourceName: "solo_route_map_placeholder_\(id)",
            title: SoloLocalization.localized("进入视角"),
            subtitle: SoloLocalization.localized("切换到独立叙事页面"),
            caption: nil
        )
    }

    private var destinyTint: Color {
        switch routeSnapshot.destinyStatus.level {
        case .abundant:
            return SoloTheme.jade
        case .steady:
            return SoloTheme.gold
        case .strained, .critical:
            return SoloTheme.crimson
        }
    }

    private var currentVolumeVisual: TianjiluVolumeVisual {
        TianjiluArtworkCatalog.volume(for: max(progressSummary.currentChapterNumber, 1))
    }
}

import SwiftUI

struct SoloEntryContinueRail: View {
    let book: Book
    let snapshot: SoloEntrySnapshot
    let openDossier: () -> Void
    let openRouteMap: () -> Void
    let openSettings: () -> Void
    let openChapterBrowser: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            portalCards

            questTracker

            HStack(spacing: 12) {
                utilityCard(
                    icon: "list.number",
                    title: SoloLocalization.localized("章节目录"),
                    subtitle: SoloLocalization.localized("选卷 · 选章节"),
                    tint: SoloTheme.gold,
                    action: openChapterBrowser
                )
                utilityCard(
                    icon: "gearshape.fill",
                    title: SoloLocalization.localized("设置"),
                    subtitle: SoloLocalization.localized("微调字号与反馈"),
                    tint: SoloTheme.warmInk,
                    action: openSettings
                )
            }
        }
    }

    // MARK: - Portal Cards (Dossier + Route Map)

    @ViewBuilder
    private var portalCards: some View {
        if book.id == "天机录" {
            tianjiluPortalCard(
                title: snapshot.branding.dossierTitle,
                subtitle: snapshot.branding.landing.dossierSubtitle,
                artwork: TianjiluArtworkCatalog.dossierBackdrop,
                systemIcon: "person.text.rectangle",
                tint: SoloTheme.jade,
                action: openDossier
            )

            tianjiluPortalCard(
                title: snapshot.branding.routeMapTitle,
                subtitle: snapshot.branding.landing.routeMapSubtitle,
                artwork: TianjiluArtworkCatalog.routeBanner,
                systemIcon: "point.topleft.down.curvedto.point.bottomright.up",
                tint: SoloTheme.crimson,
                action: openRouteMap
            )
        } else {
            HStack(spacing: 12) {
                portalCard(
                    title: snapshot.branding.dossierTitle,
                    subtitle: SoloLocalization.localized("看关键人物与状态变化"),
                    systemImage: "person.text.rectangle",
                    tint: SoloTheme.jade,
                    action: openDossier
                )
                portalCard(
                    title: snapshot.branding.routeMapTitle,
                    subtitle: SoloLocalization.localized("看公开路线与暗线提示"),
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                    tint: SoloTheme.crimson,
                    action: openRouteMap
                )
            }
        }
    }

    // MARK: - Quest Tracker

    private var questTracker: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .font(.caption2.weight(.bold))
                Text(SoloLocalization.localized("当前任务").uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
            }
            .foregroundStyle(SoloTheme.gold)

            Text(snapshot.currentStageTitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(SoloTheme.muted)

            Text(snapshot.currentObjective)
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(SoloTheme.ink)
                .lineSpacing(4)

            questProgressBar

            HStack(spacing: 10) {
                questBadge(
                    label: SoloLocalization.localized("天命值"),
                    value: "\(snapshot.destinyStatus.value)",
                    detail: snapshot.destinyStatus.headline,
                    tint: destinyTint
                )
                questBadge(
                    label: snapshot.branding.landing.identityLabel,
                    value: snapshot.currentIdentityValue,
                    detail: nil,
                    tint: SoloTheme.gold
                )
            }

            if let recap = snapshot.recapSummary {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.quote")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SoloTheme.warmInk.opacity(0.50))
                        .padding(.top, 2)
                    Text(recap)
                        .font(.caption)
                        .foregroundStyle(SoloTheme.warmInk.opacity(0.70))
                        .lineSpacing(4)
                        .lineLimit(2)
                }
            }
        }
        .padding(18)
        .soloPanel(.stage, prominence: 0.3)
    }

    private var questProgressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SoloTheme.gold, SoloTheme.crimson],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * questProgress)
                }
            }
            .frame(height: 4)

            HStack {
                Text(SoloLocalization.format(
                    "%d / %d %@",
                    snapshot.progress.completedChapterCount,
                    snapshot.progress.totalChapterCount,
                    snapshot.branding.chapterUnitName
                ))
                .font(.caption2)
                .foregroundStyle(SoloTheme.muted)

                Spacer()

                Text("\(Int(questProgress * 100))%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SoloTheme.crimson)
            }
        }
    }

    private func questBadge(
        label: String,
        value: String,
        detail: String?,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(tint.opacity(0.80))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SoloTheme.ink)
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(SoloTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Utility Cards (Chapter Browser + Settings)

    private func utilityCard(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tint)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SoloTheme.muted.opacity(0.50))
                }
                Text(title)
                    .font(SoloTypography.label)
                    .foregroundStyle(SoloTheme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .soloPanel(.evidence, prominence: 0.15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Portal Card Variants

    private func portalCard(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(SoloTypography.label)
                    .foregroundStyle(SoloTheme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(3)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(14)
            .soloPanel(.evidence)
        }
        .buttonStyle(.plain)
    }

    private func tianjiluPortalCard(
        title: String,
        subtitle: String,
        artwork: SoloArtworkAsset,
        systemIcon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                SoloBundledArtworkImage(resourceName: artwork.resourceName, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.10),
                                Color.black.opacity(0.30),
                                Color.black.opacity(0.82),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RadialGradient(
                            colors: [
                                tint.opacity(0.16),
                                Color.clear,
                            ],
                            center: UnitPoint(x: 0.2, y: 0.8),
                            startRadius: 0,
                            endRadius: 200
                        )
                    )

                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: systemIcon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(tint)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [tint.opacity(0.60), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 28, height: 1)
                        }

                        Text(title)
                            .font(SoloTypography.posterTitle(size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        SoloTheme.ink,
                                        tint.opacity(0.80),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text(subtitle)
                            .font(SoloTypography.detail)
                            .foregroundStyle(SoloTheme.warmInk.opacity(0.78))
                            .lineSpacing(4)
                            .lineLimit(2)
                    }

                    Spacer()

                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(tint.opacity(0.16))
                                .frame(width: 44, height: 44)

                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [tint.opacity(0.48), tint.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(tint)
                        }

                        Text(SoloLocalization.localized("进入"))
                            .font(.caption2.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(tint.opacity(0.66))
                    }
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.30),
                                SoloTheme.gold.opacity(0.12),
                                Color.white.opacity(0.06),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: tint.opacity(0.18), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var questProgress: CGFloat {
        guard snapshot.progress.totalChapterCount > 0 else { return 0 }
        return CGFloat(snapshot.progress.completedChapterCount) / CGFloat(snapshot.progress.totalChapterCount)
    }

    private var destinyTint: Color {
        switch snapshot.destinyStatus.level {
        case .abundant:
            return SoloTheme.jade
        case .steady:
            return SoloTheme.gold
        case .strained, .critical:
            return SoloTheme.crimson
        }
    }
}

import SwiftUI

struct SoloEntryContinueRail: View {
    let book: Book
    let snapshot: SoloEntrySnapshot
    let openDossier: () -> Void
    let openRouteMap: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SoloEntrySectionHeader(
                eyebrow: "当前局势",
                title: snapshot.currentStageTitle,
                detail: snapshot.currentStageSummary
            )

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(snapshot.branding.objectiveTitle)
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.gold)
                        Text(snapshot.currentObjective)
                            .font(SoloTypography.sceneHeadline(size: 22))
                            .foregroundStyle(SoloTheme.ink)
                            .lineSpacing(4)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        SoloSignalChip(
                            text: book.genre.displayName,
                            tint: SoloTheme.jade
                        )
                        SoloSignalChip(
                            text: "\(snapshot.progress.completedChapterCount)/\(snapshot.progress.totalChapterCount) \(snapshot.branding.chapterUnitName)",
                            tint: SoloTheme.crimson
                        )
                    }
                }

                Text(snapshot.currentObjectiveSummary)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(6)

                HStack(spacing: 10) {
                    detailPanel(
                        title: snapshot.branding.currentRunTitle,
                        body: snapshot.currentIdentityValue,
                        tint: SoloTheme.gold
                    )

                    detailPanel(
                        title: snapshot.branding.recapTitle,
                        body: snapshot.recapSummary ?? "上一段推进还没有留下能被安全复述的回响，说明真正的余波还在后面。",
                        tint: SoloTheme.jade
                    )
                }

                HStack(spacing: 10) {
                    statusPanel(
                        title: "天机录状态",
                        headline: snapshot.destinyStatus.headline,
                        body: snapshot.destinyStatus.detail,
                        footer: "天命值 \(snapshot.destinyStatus.value) · \(snapshot.destinyStatus.thresholdHint)",
                        tint: destinyTint
                    )

                    statusPanel(
                        title: "当前版本内容",
                        headline: "\(snapshot.generatedChapterCount) / \(snapshot.plannedChapterCount) \(snapshot.branding.chapterUnitName)",
                        body: snapshot.serialReleaseLine,
                        footer: snapshot.visibleRouteTitles.isEmpty
                            ? "当前明线仍在继续显形"
                            : "当前棋局：" + snapshot.visibleRouteTitles.prefix(2).joined(separator: " / "),
                        tint: SoloTheme.crimson
                    )
                }

                if !snapshot.visibleRouteTitles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前棋局")
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.gold)
                        Text("你已经看见的明线，不代表真正完整的命途；它只是这盘局暂时露出来的那一层。")
                            .font(SoloTypography.detail)
                            .foregroundStyle(SoloTheme.muted)
                            .lineSpacing(5)

                        HStack(spacing: 8) {
                            ForEach(snapshot.visibleRouteTitles.prefix(3), id: \.self) { title in
                                SoloSignalChip(text: title, tint: SoloTheme.warmInk)
                            }
                        }
                    }
                    .padding(16)
                    .soloPanel(.evidence, prominence: 0.18)
                }

                if let hiddenRouteHint = snapshot.hiddenRouteHint {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SoloTheme.crimson)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("暗线信号")
                                .font(SoloTypography.meta)
                                .foregroundStyle(SoloTheme.crimson)
                            Text(hiddenRouteHint)
                                .font(SoloTypography.detail)
                                .foregroundStyle(SoloTheme.warmInk)
                                .lineSpacing(5)
                        }
                    }
                    .padding(16)
                    .soloPanel(.alert)
                }

                auxiliaryDoors
            }
            .padding(22)
            .soloPanel(.stage, prominence: 0.3)
        }
    }

    private var auxiliaryDoors: some View {
        let isTianjilu = book.id == "天机录"

        return VStack(spacing: 16) {
            if isTianjilu {
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
                    doorButton(
                        title: snapshot.branding.dossierTitle,
                        subtitle: "看关键人物与状态变化",
                        systemImage: "person.text.rectangle",
                        tint: SoloTheme.jade,
                        action: openDossier
                    )
                    doorButton(
                        title: snapshot.branding.routeMapTitle,
                        subtitle: "看公开路线与暗线提示",
                        systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                        tint: SoloTheme.crimson,
                        action: openRouteMap
                    )
                }
            }

            Button(action: openSettings) {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SoloTheme.warmInk)
                    Text("设置")
                        .font(SoloTypography.label)
                        .foregroundStyle(SoloTheme.ink)
                    Spacer()
                    Text("微调字号与章末反馈")
                        .font(.caption)
                        .foregroundStyle(SoloTheme.muted)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SoloTheme.muted.opacity(0.60))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .soloPanel(.quiet, prominence: 0.1)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tianjilu Portal Card

    private func tianjiluPortalCard(
        title: String,
        subtitle: String,
        artwork: SoloArtworkAsset,
        systemIcon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        return Button(action: action) {
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

                        Text("进入")
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

    private func detailPanel(title: String, body: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(SoloTypography.meta)
                .foregroundStyle(tint)
            Text(body)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.ink)
                .lineSpacing(5)
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .padding(16)
        .soloPanel(.evidence, prominence: 0.2)
    }

    private func statusPanel(
        title: String,
        headline: String,
        body: String,
        footer: String,
        tint: Color
    ) -> some View {
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
                .lineSpacing(5)
                .lineLimit(4)
            Text(footer)
                .font(.caption)
                .foregroundStyle(tint.opacity(0.82))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, minHeight: 156, alignment: .topLeading)
        .padding(16)
        .soloPanel(.evidence, prominence: 0.22)
    }

    private func doorButton(
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

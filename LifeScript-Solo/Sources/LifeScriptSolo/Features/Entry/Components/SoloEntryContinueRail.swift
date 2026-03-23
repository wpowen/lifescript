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
            doorButton(
                title: "设置",
                subtitle: "微调字号与章末反馈",
                systemImage: "gearshape.fill",
                tint: SoloTheme.warmInk,
                action: openSettings
            )
        }
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
}

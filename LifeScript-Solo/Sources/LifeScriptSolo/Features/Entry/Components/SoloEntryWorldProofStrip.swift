import SwiftUI

struct SoloEntryWorldProofStrip: View {
    let book: Book
    let snapshot: SoloEntrySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SoloEntrySectionHeader(
                eyebrow: "世界证据",
                title: "先看到这部作品如何运转，再决定你要不要把自己押进去",
                detail: "这里不解释系统，而是直接给你看人物、路线、代价和重玩价值这些证据。"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    evidenceCard(
                        title: "风险人物",
                        body: riskLine,
                        footnote: "人物不是摆设，他们会记住你在关键时刻站在哪边。",
                        tint: SoloTheme.gold
                    )

                    evidenceCard(
                        title: "公开路线",
                        body: routeLine,
                        footnote: "明线给承诺，暗线给代价，真正危险的变化通常来得更晚。",
                        tint: SoloTheme.crimson
                    )

                    evidenceCard(
                        title: "重玩价值",
                        body: replayLine,
                        footnote: "重开不是重读，而是验证另一种路线会把世界推向哪里。",
                        tint: SoloTheme.jade
                    )
                }
                .padding(.vertical, 4)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(snapshot.experienceStats) { stat in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stat.valueText)
                            .font(SoloTypography.sceneHeadline(size: 22))
                            .foregroundStyle(SoloTheme.ink)
                        Text(stat.title)
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .soloPanel(.evidence)
                }
            }
        }
    }

    private var riskLine: String {
        guard let character = book.characters.first else {
            return "关键人物还没有完全现身。"
        }
        return "\(character.name) · \(character.title)"
    }

    private var routeLine: String {
        if let visibleRoute = snapshot.visibleRouteTitles.first {
            return visibleRoute
        }
        if let hiddenRouteHint = snapshot.hiddenRouteHint {
            return hiddenRouteHint
        }
        return "公开路线还没有完全显形。"
    }

    private var replayLine: String {
        "\(snapshot.progress.totalChapterCount) \(snapshot.branding.chapterUnitName)长线体验 · \(book.characters.count) 名关键人物"
    }

    private func evidenceCard(title: String, body: String, footnote: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(SoloTypography.meta)
                .foregroundStyle(tint)
            Text(body)
                .font(SoloTypography.sceneHeadline(size: 22))
                .foregroundStyle(SoloTheme.ink)
                .lineSpacing(4)
            Text(footnote)
                .font(SoloTypography.caption)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(tint.opacity(0.32))
                .frame(width: 64, height: 4)
        }
        .frame(width: 260, alignment: .topLeading)
        .frame(minHeight: 196, alignment: .topLeading)
        .padding(18)
        .soloPanel(.evidence, prominence: 0.2)
    }
}

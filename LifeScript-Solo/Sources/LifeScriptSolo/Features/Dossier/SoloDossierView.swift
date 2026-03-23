import SwiftUI

struct SoloDossierView: View {
    let book: Book
    let relationships: [RelationshipState]
    let snapshot: SoloDossierSnapshot
    private let branding = SoloStoryConfig.branding

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    overviewPanel
                    spotlightPanel
                    systemModulesPanel
                    statsPanel
                    charactersPanel
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: branding.dossierTitle, kicker: "档案")
    }

    private var overviewPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(book.title)
                .font(SoloTypography.posterTitle(size: 32))
                .foregroundStyle(SoloTheme.ink)
            Text(book.synopsis)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(6)
            HStack(spacing: 10) {
                SoloSignalChip(text: spotlightSectionTitle, tint: SoloTheme.gold)
                SoloSignalChip(text: statsSectionTitle, tint: SoloTheme.crimson)
            }
        }
        .padding(22)
        .soloPanel(.hero, prominence: 0.25)
    }

    @ViewBuilder
    private var spotlightPanel: some View {
        if let spotlight = snapshot.relationshipSpotlight {
            VStack(alignment: .leading, spacing: 12) {
                Text(spotlightSectionTitle)
                    .font(SoloTypography.sectionTitle(size: 18))
                    .foregroundStyle(SoloTheme.gold)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(spotlight.characterName)
                            .font(SoloTypography.sceneHeadline(size: 22))
                            .foregroundStyle(SoloTheme.ink)
                        Text(spotlight.characterTitle)
                            .font(SoloTypography.meta)
                            .foregroundStyle(SoloTheme.warmInk)
                    }
                    Spacer()
                    relationChip(label: "态度", valueText: spotlight.attitudeLabel)
                }
                if let reason = spotlight.reason {
                    Text(reason)
                        .foregroundStyle(SoloTheme.muted)
                        .lineSpacing(5)
                }
            }
            .padding(22)
            .soloPanel(.alert, prominence: 0.25)
        }
    }

    private var systemModulesPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(systemModulesSectionTitle)
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            ForEach(snapshot.moduleCards) { card in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(card.title)
                            .font(SoloTypography.label)
                            .foregroundStyle(SoloTheme.ink)
                        Spacer()
                        Text(card.valueText)
                            .font(SoloTypography.sceneHeadline(size: 20))
                            .foregroundStyle(color(for: card.tint))
                    }
                    Text(card.detailText)
                        .foregroundStyle(SoloTheme.muted)
                        .lineSpacing(5)
                }
                .padding(18)
                .soloPanel(.evidence, prominence: 0.18)
            }
        }
        .padding(22)
        .soloPanel(.stage)
    }

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(statsSectionTitle)
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            ForEach(snapshot.statCards) { card in
                SoloMetricBar(title: card.title, value: card.value, tint: color(for: card.tint))
            }
        }
        .padding(22)
        .soloPanel(.stage)
    }

    private var charactersPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(relationshipsSectionTitle)
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            ForEach(book.characters) { character in
                let relation = relationships.first(where: { $0.characterId == character.id })

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(character.name)
                                .font(SoloTypography.label)
                                .foregroundStyle(SoloTheme.ink)
                            Text(character.title)
                                .font(.footnote)
                                .foregroundStyle(SoloTheme.gold)
                        }
                        Spacer()
                        Text(relation?.attitudeLabel ?? "未解锁")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SoloTheme.jade)
                    }

                    Text(character.description)
                        .foregroundStyle(SoloTheme.muted)
                        .lineSpacing(4)

                    if let relation {
                        HStack(spacing: 10) {
                            relationChip(label: "信任", value: relation.trust)
                            relationChip(label: "好感", value: relation.affection)
                            relationChip(label: "敌意", value: relation.hostility)
                        }
                    }
                }
                .padding(18)
                .soloPanel(.quiet)
            }
        }
    }

    private func relationChip(label: String, value: Int) -> some View {
        Text("\(label) \(value)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(SoloTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
    }

    private func relationChip(label: String, valueText: String) -> some View {
        Text("\(label) \(valueText)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(SoloTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
    }

    private func color(for preset: SoloPalettePreset) -> Color {
        switch preset {
        case .ashCrimson:
            return SoloTheme.crimson
        case .emberGold:
            return SoloTheme.gold
        case .moonJade:
            return SoloTheme.jade
        case .royalPlum:
            return SoloTheme.crimson
        case .sapphireMist:
            return SoloTheme.warmInk
        }
    }

    private var spotlightSectionTitle: String {
        switch book.genre {
        case .cultivation:
            return "当前关键人物"
        case .businessWar:
            return "当前关键合作者"
        case .suspenseSurvival:
            return "当前风险人物"
        case .apocalypsePower:
            return "当前生死绑定"
        case .urbanReversal:
            return "当前风暴人物"
        }
    }

    private var systemModulesSectionTitle: String {
        switch book.genre {
        case .cultivation:
            return "故事系统面"
        case .businessWar:
            return "局势系统面"
        case .suspenseSurvival:
            return "生存系统面"
        case .apocalypsePower:
            return "避难区态势"
        case .urbanReversal:
            return "翻盘系统面"
        }
    }

    private var statsSectionTitle: String {
        switch book.genre {
        case .cultivation:
            return "主角命格"
        case .businessWar:
            return "角色筹码"
        case .suspenseSurvival:
            return "生存状态"
        case .apocalypsePower:
            return "夜线状态"
        case .urbanReversal:
            return "主角牌面"
        }
    }

    private var relationshipsSectionTitle: String {
        switch book.genre {
        case .cultivation:
            return "因果人物谱"
        case .businessWar:
            return "关系网络"
        case .suspenseSurvival:
            return "人物危险谱"
        case .apocalypsePower:
            return "幸存者关系谱"
        case .urbanReversal:
            return "局中人网络"
        }
    }
}

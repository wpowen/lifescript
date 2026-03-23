import SwiftUI

struct SoloSettlementView: View {
    let book: Book
    let chapter: Chapter
    let stats: ProtagonistStats
    let previousStats: ProtagonistStats
    let relationships: [RelationshipState]
    let previousRelationships: [RelationshipState]
    let choices: [UserChoiceRecord]

    @Environment(\.dismiss) private var dismiss
    private let branding = SoloStoryConfig.branding

    private var statChanges: [StatEffect.StatType: Int] {
        stats.diff(from: previousStats)
    }

    private var resolvedChoices: [Choice] {
        chapter.nodes.compactMap { node in
            guard case .choice(let choiceNode) = node else { return nil }
            guard let record = choices.first(where: { $0.choiceNodeId == choiceNode.id }) else { return nil }
            return choiceNode.choices.first(where: { $0.id == record.selectedChoiceId })
        }
    }

    private var changedRelationships: [(Character, RelationshipState)] {
        let previousMap = Dictionary(uniqueKeysWithValues: previousRelationships.map { ($0.characterId, $0) })
        let currentMap = Dictionary(uniqueKeysWithValues: relationships.map { ($0.characterId, $0) })

        return book.characters.compactMap { character in
            guard let previous = previousMap[character.id], let current = currentMap[character.id] else { return nil }
            guard previous != current else { return nil }
            return (character, current)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoloBackdrop()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        section(title: chapter.title, content: "这一页不只是复盘结果，而是把这一章真正留下来的代价、余波和回响都重新照亮。")

                        if !resolvedChoices.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("你的选择")
                                    .font(.headline)
                                    .foregroundStyle(SoloTheme.gold)
                                ForEach(Array(resolvedChoices.enumerated()), id: \.offset) { _, choice in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(choice.text)
                                            .foregroundStyle(SoloTheme.ink)
                                        if let description = choice.description {
                                            Text(description)
                                                .font(.footnote)
                                                .foregroundStyle(SoloTheme.muted)
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                            }
                            .padding(22)
                            .soloCard()
                        }

                        if !statChanges.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("属性变化")
                                    .font(.headline)
                                    .foregroundStyle(SoloTheme.gold)
                                ForEach(Array(statChanges.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { stat in
                                    if let delta = statChanges[stat] {
                                        Text("\(stat.rawValue) \(delta > 0 ? "+" : "")\(delta)")
                                            .foregroundStyle(SoloTheme.ink)
                                    }
                                }
                            }
                            .padding(22)
                            .soloCard()
                        }

                        if !changedRelationships.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("关系变化")
                                    .font(.headline)
                                    .foregroundStyle(SoloTheme.gold)
                                ForEach(changedRelationships, id: \.0.id) { character, relation in
                                    Text("\(character.name) · \(relation.attitudeLabel)")
                                        .foregroundStyle(SoloTheme.ink)
                                }
                            }
                            .padding(22)
                            .soloCard()
                        }

                        if let hook = chapter.nextChapterHook {
                            section(title: "下一章回响", content: hook)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .soloStoryChrome(title: branding.settlementTitle, kicker: "余波")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(SoloTheme.gold)
                }
            }
        }
    }

    private func section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(SoloTypography.label)
                .foregroundStyle(SoloTheme.gold)
            Text(content)
                .foregroundStyle(SoloTheme.ink)
                .lineSpacing(6)
        }
        .padding(22)
        .soloPanel(.stage, prominence: 0.12)
    }
}

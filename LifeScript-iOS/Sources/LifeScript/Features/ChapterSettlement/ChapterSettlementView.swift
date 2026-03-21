import SwiftUI

struct ChapterSettlementView: View {
    let book: Book
    let chapter: Chapter
    let stats: ProtagonistStats
    let previousStats: ProtagonistStats
    let relationships: [RelationshipState]
    let previousRelationships: [RelationshipState]
    let choices: [UserChoiceRecord]
    var onContinue: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private var statChanges: [StatEffect.StatType: Int] {
        stats.diff(from: previousStats)
    }

    private var resolvedChoices: [ResolvedChoiceSummary] {
        chapter.nodes.compactMap { node in
            guard case .choice(let choiceNode) = node else { return nil }
            guard let record = choices.first(where: { $0.choiceNodeId == choiceNode.id }) else { return nil }
            guard let selectedChoice = choiceNode.choices.first(where: { $0.id == record.selectedChoiceId }) else { return nil }
            return ResolvedChoiceSummary(node: choiceNode, choice: selectedChoice)
        }
    }

    private var changedRelationships: [ChangedRelationshipSummary] {
        let previousMap = Dictionary(uniqueKeysWithValues: previousRelationships.map { ($0.characterId, $0) })
        let currentMap = Dictionary(uniqueKeysWithValues: relationships.map { ($0.characterId, $0) })

        return book.characters.compactMap { character in
            guard let current = currentMap[character.id], let previous = previousMap[character.id] else { return nil }
            guard current != previous else { return nil }
            return ChangedRelationshipSummary(character: character, current: current, previous: previous)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SceneBackdrop(palette: book.palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing24) {
                        headerSection
                        choicesSummarySection
                        statChangesSection
                        relationshipChangesSection
                        hookSection
                        continueButton
                    }
                    .padding(.horizontal, .spacing16)
                    .padding(.top, .spacing20)
                    .padding(.bottom, .spacing40)
                }
            }
            .navigationTitle("本章影响")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            ScenePageHeader(
                eyebrow: "第\(chapter.number)章 · 结果面板",
                title: chapter.title,
                subtitle: "这一页只回答一个问题: 你刚刚到底改写了什么。",
                accent: book.palette.primary
            )

            HStack(spacing: .spacing10) {
                SceneMetricPill(
                    title: "关键选择",
                    value: "\(resolvedChoices.count) 次",
                    systemImage: "checklist",
                    color: book.palette.primary
                )
                SceneMetricPill(
                    title: "属性变化",
                    value: "\(statChanges.count) 项",
                    systemImage: "chart.line.uptrend.xyaxis",
                    color: book.palette.secondary
                )
                SceneMetricPill(
                    title: "关系波动",
                    value: "\(changedRelationships.count) 位",
                    systemImage: "person.2.fill",
                    color: book.palette.tertiary
                )
            }
        }
    }

    private var choicesSummarySection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "你刚才的选择",
                subtitle: "不再展示内部 ID，而是直接说明你选了哪条路。",
                accent: book.palette.primary
            )

            if resolvedChoices.isEmpty {
                Text("本章没有出现需要你决策的关键节点。")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .scenePanel(accent: book.palette.primary, padding: .spacing16)
            } else {
                VStack(spacing: .spacing12) {
                    ForEach(resolvedChoices) { summary in
                        VStack(alignment: .leading, spacing: .spacing10) {
                            HStack {
                                SceneAccentBadge(text: summary.node.choiceType.displayName, color: book.palette.primary)
                                Spacer()
                                SceneAccentBadge(
                                    text: summary.choice.satisfactionType.displayName,
                                    color: summary.choice.satisfactionType.accentColor
                                )
                            }

                            Text(summary.choice.text)
                                .font(.labelLarge)
                                .foregroundStyle(Color.textPrimary)

                            if let description = summary.choice.description {
                                Text(description)
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                                    .lineSpacing(4)
                            }
                        }
                        .scenePanel(accent: book.palette.primary, padding: .spacing16)
                    }
                }
            }
        }
    }

    private var statChangesSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "主角属性变化",
                subtitle: "用数值和颜色明确说明本章对主角气质的推动。",
                accent: book.palette.secondary
            )

            if statChanges.isEmpty {
                Text("本章没有触发属性变化。")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .scenePanel(accent: book.palette.secondary, padding: .spacing16)
            } else {
                VStack(spacing: .spacing16) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: .spacing12) {
                        ForEach(Array(statChanges.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { stat in
                            if let delta = statChanges[stat] {
                                StatBadge(
                                    label: stat.rawValue,
                                    value: stats.value(for: stat),
                                    color: statColor(for: stat),
                                    change: delta
                                )
                                .scenePanel(accent: statColor(for: stat), padding: .spacing12)
                            }
                        }
                    }

                    VStack(spacing: .spacing12) {
                        ForEach(Array(statChanges.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { stat in
                            if let delta = statChanges[stat] {
                                StatBar(
                                    label: stat.rawValue,
                                    value: stats.value(for: stat),
                                    maxValue: ProtagonistStats.maxValue,
                                    color: statColor(for: stat),
                                    change: delta
                                )
                            }
                        }
                    }
                    .scenePanel(accent: book.palette.secondary, padding: .spacing16)
                }
            }
        }
    }

    private var relationshipChangesSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "角色关系变化",
                subtitle: "哪些角色被你推近了，哪些被你推远了，这里会直说。",
                accent: book.palette.tertiary
            )

            if changedRelationships.isEmpty {
                Text("本章没有触发关系变化。")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .scenePanel(accent: book.palette.tertiary, padding: .spacing16)
            } else {
                VStack(spacing: .spacing12) {
                    ForEach(changedRelationships) { summary in
                        VStack(alignment: .leading, spacing: .spacing12) {
                            HStack(spacing: .spacing12) {
                                Circle()
                                    .fill(Color.surfaceSecondary)
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Text(String(summary.character.name.prefix(1)))
                                            .font(.labelSmall)
                                            .foregroundStyle(book.palette.primary)
                                    )

                                VStack(alignment: .leading, spacing: .spacing4) {
                                    Text(summary.character.name)
                                        .font(.labelLarge)
                                        .foregroundStyle(Color.textPrimary)
                                    Text("当前态度: \(summary.current.attitudeLabel)")
                                        .font(.captionLarge)
                                        .foregroundStyle(Color.textSecondary)
                                }

                                Spacer()
                            }

                            relationshipDeltaRow("信任", summary.previous.trust, summary.current.trust, .relationTrust)
                            relationshipDeltaRow("好感", summary.previous.affection, summary.current.affection, .relationAffection)
                            relationshipDeltaRow("敌意", summary.previous.hostility, summary.current.hostility, .relationHostility)
                            relationshipDeltaRow("敬畏", summary.previous.awe, summary.current.awe, .relationAwe)
                            relationshipDeltaRow("依赖", summary.previous.dependence, summary.current.dependence, .relationDependence)
                        }
                        .scenePanel(accent: book.palette.tertiary, padding: .spacing16)
                    }
                }
            }
        }
    }

    private var hookSection: some View {
        Group {
            if let hook = chapter.nextChapterHook {
                VStack(alignment: .leading, spacing: .spacing10) {
                    SceneSectionHeader(
                        title: "下一章钩子",
                        subtitle: "继续读之前，先把悬念埋清楚。",
                        accent: book.palette.secondary
                    )

                    Text(hook)
                        .font(.readingBody)
                        .foregroundStyle(Color.textPrimary)
                        .italic()
                        .lineSpacing(6)
                        .scenePanel(accent: book.palette.secondary, padding: .spacing18)
                }
            }
        }
    }

    private var continueButton: some View {
        Button {
            dismiss()
            onContinue?()
        } label: {
            SceneCTAButtonLabel(
                title: onContinue == nil ? "返回章节结尾" : "继续下一章",
                subtitle: onContinue == nil ? "关掉结果面板，回到章节结束操作区" : "关掉结果面板并继续推进剧情",
                systemImage: onContinue == nil ? "arrow.uturn.backward.circle.fill" : "arrow.right.circle.fill"
            )
        }
        .buttonStyle(.primary)
    }

    private func relationshipDeltaRow(_ label: String, _ previous: Int, _ current: Int, _ color: Color) -> some View {
        let delta = current - previous

        return HStack(spacing: .spacing12) {
            Text(label)
                .font(.labelSmall)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 34, alignment: .leading)

            StatBar(
                label: "",
                value: current,
                maxValue: RelationshipState.maxValue,
                color: color,
                change: delta
            )

            Text(current.description)
                .font(.captionLarge)
                .foregroundStyle(Color.textPrimary)
                .frame(width: 26, alignment: .trailing)
        }
    }

    private func statColor(for stat: StatEffect.StatType) -> Color {
        switch stat {
        case .combat: return .statCombat
        case .fame: return .statFame
        case .strategy: return .statStrategy
        case .wealth: return .statWealth
        case .charm: return .statCharm
        case .darkness: return .statDarkness
        case .destiny: return .statDestiny
        }
    }
}

private struct ResolvedChoiceSummary: Identifiable {
    let node: ChoiceNode
    let choice: Choice

    var id: String { node.id }
}

private struct ChangedRelationshipSummary: Identifiable {
    let character: Character
    let current: RelationshipState
    let previous: RelationshipState

    var id: String { character.id }
}

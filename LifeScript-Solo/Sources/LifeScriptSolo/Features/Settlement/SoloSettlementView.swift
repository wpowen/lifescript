import SwiftUI

struct SoloSettlementView: View {
    private struct RelationshipShift: Identifiable {
        let id: String
        let characterName: String
        let attitudeLabel: String
        let headline: String
        let detail: String
    }

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

    private var keyMoves: [String] {
        var seen = Set<String>()
        return resolvedChoices.compactMap { choice in
            let label = choice.memoryLabel ?? choice.processLabel ?? choice.visibleReward ?? choice.text
            guard !label.isEmpty else { return nil }
            guard seen.insert(label).inserted else { return nil }
            return label
        }
    }

    private var visibleCosts: [String] {
        uniqueStrings(from: resolvedChoices.compactMap(\.visibleCost))
    }

    private var visibleRewards: [String] {
        uniqueStrings(from: resolvedChoices.compactMap(\.visibleReward))
    }

    private var visibleRiskHints: [String] {
        uniqueStrings(from: resolvedChoices.compactMap(\.riskHint))
    }

    private var relationshipShifts: [RelationshipShift] {
        let previousMap = Dictionary(uniqueKeysWithValues: previousRelationships.map { ($0.characterId, $0) })
        let currentMap = Dictionary(uniqueKeysWithValues: relationships.map { ($0.characterId, $0) })

        return book.characters.compactMap { character in
            guard let previous = previousMap[character.id], let current = currentMap[character.id] else { return nil }
            guard previous != current else { return nil }
            guard let strongestShift = strongestRelationshipShift(previous: previous, current: current) else { return nil }

            let sign = strongestShift.delta > 0 ? "+" : ""
            return RelationshipShift(
                id: character.id,
                characterName: character.name,
                attitudeLabel: current.attitudeLabel,
                headline: "\(strongestShift.dimension) \(sign)\(strongestShift.delta)",
                detail: "当前态度转向「\(current.attitudeLabel)」，说明这条因果线已经被你真正拨动了。"
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoloBackdrop()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        section(
                            title: chapter.title,
                            content: introBody
                        )

                        if !keyMoves.isEmpty {
                            detailBlock(title: "本章关键落子", tint: SoloTheme.gold) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(keyMoves.enumerated()), id: \.offset) { index, move in
                                        bulletRow(
                                            index: index + 1,
                                            title: move,
                                            detail: "这一步会在后续章节里继续发酵，它不是一段文本的结束，而是下一段因果的开端。"
                                        )
                                    }
                                }
                            }
                        }

                        if shouldShowDestinyPanel {
                            detailBlock(title: "天命与代价", tint: destinyTint) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(destinyHeadline)
                                            .font(SoloTypography.sceneHeadline(size: 22))
                                            .foregroundStyle(SoloTheme.ink)
                                        Spacer()
                                        Text("天命值 \(stats.destiny)")
                                            .font(SoloTypography.meta)
                                            .foregroundStyle(destinyTint)
                                    }

                                    Text(destinyDetail)
                                        .foregroundStyle(SoloTheme.muted)
                                        .lineSpacing(5)

                                    if !visibleCosts.isEmpty || !visibleRewards.isEmpty || !visibleRiskHints.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            if !visibleCosts.isEmpty {
                                                bulletLine(title: "消耗", items: visibleCosts, tint: SoloTheme.crimson)
                                            }
                                            if !visibleRewards.isEmpty {
                                                bulletLine(title: "得到", items: visibleRewards, tint: SoloTheme.jade)
                                            }
                                            if !visibleRiskHints.isEmpty {
                                                bulletLine(title: "风险", items: visibleRiskHints, tint: SoloTheme.gold)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !relationshipShifts.isEmpty {
                            detailBlock(title: "人心偏转", tint: SoloTheme.jade) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(relationshipShifts) { shift in
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(shift.characterName)
                                                    .font(SoloTypography.label)
                                                    .foregroundStyle(SoloTheme.ink)
                                                Spacer()
                                                relationChip(label: shift.attitudeLabel, tint: SoloTheme.jade)
                                            }
                                            Text(shift.headline)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(SoloTheme.jade)
                                            Text(shift.detail)
                                                .font(SoloTypography.detail)
                                                .foregroundStyle(SoloTheme.muted)
                                                .lineSpacing(5)
                                        }
                                        .padding(14)
                                        .soloPanel(.quiet, prominence: 0.06)
                                    }
                                }
                            }
                        }

                        if !resolvedChoices.isEmpty {
                            detailBlock(title: "你的选择余波", tint: SoloTheme.warmInk) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(Array(resolvedChoices.enumerated()), id: \.offset) { _, choice in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(choice.text)
                                                .foregroundStyle(SoloTheme.ink)
                                            if let description = choice.description {
                                                Text(description)
                                                    .font(.footnote)
                                                    .foregroundStyle(SoloTheme.muted)
                                            }
                                            if let processLabel = choice.processLabel {
                                                relationChip(label: processLabel, tint: SoloTheme.gold)
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color.white.opacity(0.05))
                                        )
                                    }
                                }
                            }
                        }

                        if let hook = chapter.nextChapterHook {
                            section(title: "下一章因果回响", content: hook)
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

    private var introBody: String {
        switch book.genre {
        case .cultivation:
            return "这一局不只是收尾。真正留下来的，是你把谁拉进了局里、把哪一步先落了下去，以及天机录为此替你烧掉了多少后手。"
        case .apocalypsePower:
            return "这一夜留下来的不只是数字，更是你把避难区的人心和生路分别推向了哪里。"
        case .suspenseSurvival:
            return "这一段封存下来的，不只是线索本身，还有你把真相拧向了哪一个方向。"
        case .businessWar:
            return "这一轮真正结算的，不只是输赢，而是你把牌桌上每个人的位置悄悄换成了什么。"
        case .urbanReversal:
            return "这一手翻过去以后，留下来的不只是结果，还有所有人重新看待你的角度。"
        }
    }

    private var shouldShowDestinyPanel: Bool {
        statChanges[.destiny] != nil ||
        statChanges[.darkness] != nil ||
        !visibleCosts.isEmpty ||
        !visibleRewards.isEmpty ||
        !visibleRiskHints.isEmpty
    }

    private var destinyHeadline: String {
        let destinyDelta = statChanges[.destiny] ?? 0
        let darknessDelta = statChanges[.darkness] ?? 0

        if destinyDelta < 0 && darknessDelta > 0 {
            return "窥天得势，反噬也在逼近"
        }
        if destinyDelta < 0 {
            return "你为这一步烧掉了天命"
        }
        if destinyDelta > 0 {
            return "这一局替你回收了天命"
        }
        if darknessDelta > 0 {
            return "局面虽然推进，代价也留在了身上"
        }
        return "这一步把后续代价彻底点亮了"
    }

    private var destinyDetail: String {
        let destinyDelta = statChanges[.destiny] ?? 0
        let darknessDelta = statChanges[.darkness] ?? 0
        let destinyText = destinyDelta == 0 ? nil : "天命 \(formatted(delta: destinyDelta))"
        let darknessText = darknessDelta == 0 ? nil : "心魇 \(formatted(delta: darknessDelta))"

        let parts = [destinyText, darknessText].compactMap { $0 }
        if !parts.isEmpty {
            return parts.joined(separator: "，") + "。真正危险的从来不是一次消耗，而是你为了赢这一局愿意连续烧掉多少未来。"
        }

        return "数值没有大幅跳动，不代表代价不存在；很多反噬会在下一章才把脸露出来。"
    }

    private var destinyTint: Color {
        let destinyDelta = statChanges[.destiny] ?? 0
        let darknessDelta = statChanges[.darkness] ?? 0
        if destinyDelta < 0 || darknessDelta > 0 {
            return SoloTheme.crimson
        }
        if destinyDelta > 0 {
            return SoloTheme.jade
        }
        return SoloTheme.gold
    }

    private func strongestRelationshipShift(
        previous: RelationshipState,
        current: RelationshipState
    ) -> (dimension: String, delta: Int)? {
        let dimensions = allRelationshipDimensions(previous: previous, current: current)

        return dimensions
            .map { dimension in
                let delta = current.value(for: dimension) - previous.value(for: dimension)
                return (dimension.rawValue, delta)
            }
            .filter { $0.1 != 0 }
            .max { abs($0.1) < abs($1.1) }
    }

    private func allRelationshipDimensions(
        previous: RelationshipState,
        current: RelationshipState
    ) -> [RelationshipEffect.RelationshipDimension] {
        let baseDimensions: [RelationshipEffect.RelationshipDimension] = [
            .trust, .affection, .hostility, .awe, .dependence,
            .curiosity, .vigilance, .contempt, .anger,
        ]
        let custom = Set(previous.customDimensions.keys).union(current.customDimensions.keys)
            .map(RelationshipEffect.RelationshipDimension.init(rawValue:))
        return baseDimensions + custom
    }

    private func formatted(delta: Int) -> String {
        delta > 0 ? "+\(delta)" : "\(delta)"
    }

    private func uniqueStrings(from values: [String]) -> [String] {
        var seen = Set<String>()
        return values.compactMap { value in
            guard seen.insert(value).inserted else { return nil }
            return value
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

    private func detailBlock<Content: View>(title: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(tint)
            content()
        }
        .padding(22)
        .soloCard()
    }

    private func bulletRow(index: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(SoloTheme.gold)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(SoloTheme.gold.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SoloTheme.ink)
                Text(detail)
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(5)
            }
        }
    }

    private func bulletLine(title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(SoloTypography.meta)
                .foregroundStyle(tint)
            Text(items.joined(separator: " / "))
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.ink)
                .lineSpacing(4)
        }
    }

    private func relationChip(label: String, tint: Color) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            )
    }
}

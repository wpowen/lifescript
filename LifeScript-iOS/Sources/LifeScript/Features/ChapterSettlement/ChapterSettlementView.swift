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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    headerSection
                    choicesSummarySection
                    statChangesSection
                    relationshipChangesSection
                    hookSection
                    continueButton
                }
                .padding(.spacing16)
                .padding(.bottom, .spacing32)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("章节结算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: .spacing8) {
            Text("第\(chapter.number)章")
                .font(.chapterNumber)
                .foregroundStyle(Color.accentGold)
            Text(chapter.title)
                .font(.titleLarge)
                .foregroundStyle(Color.textPrimary)
            Text("本章完成")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing16)
    }

    // MARK: - Choices Summary

    private var choicesSummarySection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            sectionTitle("你的关键选择", icon: "hand.tap")

            if choices.isEmpty {
                Text("本章没有做出互动选择")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            } else {
                ForEach(choices) { choice in
                    HStack(spacing: .spacing8) {
                        Circle()
                            .fill(Color.accentGold)
                            .frame(width: 8, height: 8)
                        Text(choice.selectedChoiceId)
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
        }
        .settlementCard()
    }

    // MARK: - Stat Changes

    private var statChangesSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            sectionTitle("属性变化", icon: "chart.bar")

            if statChanges.isEmpty {
                Text("本章属性未发生变化")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            } else {
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
                        }
                    }
                }
            }
        }
        .settlementCard()
    }

    // MARK: - Relationship Changes

    private var relationshipChangesSection: some View {
        let changedRelationships = relationships.enumerated().compactMap { index, rel -> (Character, RelationshipState, RelationshipState)? in
            guard index < previousRelationships.count else { return nil }
            let prev = previousRelationships[index]
            guard rel != prev else { return nil }
            guard let char = book.characters.first(where: { $0.id == rel.characterId }) else { return nil }
            return (char, rel, prev)
        }

        return VStack(alignment: .leading, spacing: .spacing12) {
            sectionTitle("关系变化", icon: "person.2")

            if changedRelationships.isEmpty {
                Text("本章关系未发生变化")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            } else {
                ForEach(changedRelationships, id: \.0.id) { char, current, _ in
                    HStack(spacing: .spacing12) {
                        Circle()
                            .fill(Color.surfaceHighlight)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(char.name.prefix(1)))
                                    .font(.labelSmall)
                                    .foregroundStyle(Color.accentGold)
                            )
                        VStack(alignment: .leading, spacing: .spacing2) {
                            Text(char.name)
                                .font(.labelMedium)
                                .foregroundStyle(Color.textPrimary)
                            Text("当前态度: \(current.attitudeLabel)")
                                .font(.captionLarge)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .settlementCard()
    }

    // MARK: - Hook

    private var hookSection: some View {
        Group {
            if let hook = chapter.nextChapterHook {
                VStack(spacing: .spacing8) {
                    Text("下一章预告")
                        .font(.labelSmall)
                        .foregroundStyle(Color.textTertiary)
                    Text(hook)
                        .font(.readingBody)
                        .foregroundStyle(Color.accentGold)
                        .multilineTextAlignment(.center)
                        .italic()
                }
                .frame(maxWidth: .infinity)
                .padding(.spacing16)
                .background(Color.accentGold.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
            }
        }
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button("继续下一章") {
            dismiss()
            onContinue?()
        }
        .buttonStyle(.primary)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.labelMedium)
            .foregroundStyle(Color.textSecondary)
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

// MARK: - Settlement Card Modifier

extension View {
    func settlementCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacing16)
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
    }
}

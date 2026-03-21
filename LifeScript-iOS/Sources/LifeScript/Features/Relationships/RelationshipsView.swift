import SwiftUI

struct RelationshipsView: View {
    let book: Book
    let relationships: [RelationshipState]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCharacterId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                SceneBackdrop(palette: book.palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing24) {
                        headerSection

                        VStack(spacing: .spacing16) {
                            ForEach(book.characters) { character in
                                if let relationship = relationships.first(where: { $0.characterId == character.id }) {
                                    CharacterRelationshipCard(
                                        character: character,
                                        relationship: relationship,
                                        isExpanded: selectedCharacterId == character.id,
                                        onToggle: {
                                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                                selectedCharacterId = selectedCharacterId == character.id ? nil : character.id
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, .spacing16)
                    .padding(.top, .spacing20)
                    .padding(.bottom, .spacing40)
                }
            }
            .navigationTitle("角色关系")
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
                eyebrow: "局势面板",
                title: "你和每个关键角色的关系，正在往哪边走",
                subtitle: "关系页不该只是数值堆叠，而要让用户一眼看懂谁在靠近、谁在疏远、谁已经开始危险。",
                accent: book.palette.secondary
            )

            HStack(spacing: .spacing10) {
                SceneMetricPill(title: "关键角色", value: "\(book.characters.count) 位", systemImage: "person.3.fill", color: book.palette.primary)
                SceneMetricPill(title: "当前焦点", value: selectedCharacterName, systemImage: "eye.fill", color: book.palette.secondary)
                SceneMetricPill(title: "关系目标", value: "明确可读", systemImage: "scope", color: book.palette.tertiary)
            }
        }
    }

    private var selectedCharacterName: String {
        guard let selectedCharacterId else { return "全部" }
        return book.characters.first(where: { $0.id == selectedCharacterId })?.name ?? "全部"
    }
}

struct CharacterRelationshipCard: View {
    let character: Character
    let relationship: RelationshipState
    var isExpanded: Bool = false
    var onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing14) {
            HStack(alignment: .top, spacing: .spacing12) {
                Circle()
                    .fill(Color.surfaceSecondary)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Text(String(character.name.prefix(1)))
                            .font(.titleMedium)
                            .foregroundStyle(roleColor)
                    )

                VStack(alignment: .leading, spacing: .spacing6) {
                    HStack {
                        Text(character.name)
                            .font(.labelLarge)
                            .foregroundStyle(Color.textPrimary)
                        SceneAccentBadge(text: character.role.rawValue, color: roleColor)
                    }

                    Text(character.title)
                        .font(.captionLarge)
                        .foregroundStyle(Color.textSecondary)

                    Text("当前态度: \(relationship.attitudeLabel)")
                        .font(.bodySmall)
                        .foregroundStyle(attitudeColor)
                }

                Spacer()
            }

            if let reason = relationship.lastChangeReason {
                Text(reason)
                    .font(.captionLarge)
                    .foregroundStyle(Color.textTertiary)
            }

            Button(isExpanded ? "收起关系细节" : "查看关系细节", action: onToggle)
                .buttonStyle(.secondary)

            if isExpanded {
                VStack(alignment: .leading, spacing: .spacing16) {
                    relationshipBar("信任", relationship.trust, .relationTrust)
                    relationshipBar("好感", relationship.affection, .relationAffection)
                    relationshipBar("敌意", relationship.hostility, .relationHostility)
                    relationshipBar("敬畏", relationship.awe, .relationAwe)
                    relationshipBar("依赖", relationship.dependence, .relationDependence)

                    Text(character.description)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(4)

                    if !relationship.unlockedEvents.isEmpty {
                        VStack(alignment: .leading, spacing: .spacing6) {
                            Text("已触发事件")
                                .font(.labelSmall)
                                .foregroundStyle(Color.textTertiary)

                            ForEach(relationship.unlockedEvents, id: \.self) { event in
                                HStack(spacing: .spacing6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.captionSmall)
                                        .foregroundStyle(Color.success)
                                    Text(event)
                                        .font(.captionLarge)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .scenePanel(accent: roleColor, padding: .spacing18)
    }

    private func relationshipBar(_ label: String, _ value: Int, _ color: Color) -> some View {
        StatBar(
            label: label,
            value: value,
            maxValue: RelationshipState.maxValue,
            color: color
        )
    }

    private var roleColor: Color {
        switch character.role {
        case .ally: return .accentEmerald
        case .rival, .antagonist: return .accentCrimson
        case .loveInterest: return .relationAffection
        case .mentor: return .accentSky
        case .family: return .accentAmber
        case .neutral: return .textTertiary
        }
    }

    private var attitudeColor: Color {
        switch relationship.attitudeLabel {
        case "倾心", "好感": return .relationAffection
        case "信任": return .relationTrust
        case "敬畏": return .relationAwe
        case "敌视", "警惕": return .relationHostility
        case "依赖": return .relationDependence
        default: return .textTertiary
        }
    }
}

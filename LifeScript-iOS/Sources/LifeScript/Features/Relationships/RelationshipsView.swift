import SwiftUI

struct RelationshipsView: View {
    let book: Book
    let relationships: [RelationshipState]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCharacterId: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing16) {
                    ForEach(book.characters) { character in
                        if let relationship = relationships.first(where: { $0.characterId == character.id }) {
                            CharacterRelationshipCard(
                                character: character,
                                relationship: relationship,
                                isExpanded: selectedCharacterId == character.id
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedCharacterId = selectedCharacterId == character.id ? nil : character.id
                                }
                            }
                        }
                    }
                }
                .padding(.spacing16)
            }
            .background(Color.backgroundPrimary)
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
}

// MARK: - Character Relationship Card

struct CharacterRelationshipCard: View {
    let character: Character
    let relationship: RelationshipState
    var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: .spacing12) {
            // Header row
            HStack(spacing: .spacing12) {
                Circle()
                    .fill(Color.surfaceHighlight)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(character.name.prefix(1)))
                            .font(.titleMedium)
                            .foregroundStyle(Color.accentGold)
                    )

                VStack(alignment: .leading, spacing: .spacing4) {
                    HStack {
                        Text(character.name)
                            .font(.labelLarge)
                            .foregroundStyle(Color.textPrimary)
                        TagView(text: character.role.rawValue, color: roleColor)
                    }
                    Text(character.title)
                        .font(.captionLarge)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: .spacing2) {
                    Text(relationship.attitudeLabel)
                        .font(.labelMedium)
                        .foregroundStyle(attitudeColor)
                    if let reason = relationship.lastChangeReason {
                        Text(reason)
                            .font(.captionSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }

            // Expanded details
            if isExpanded {
                VStack(spacing: .spacing12) {
                    Divider()
                        .background(Color.surfaceHighlight)

                    // Relationship dimensions
                    relationshipBar("信任", relationship.trust, .relationTrust)
                    relationshipBar("好感", relationship.affection, .relationAffection)
                    relationshipBar("敌意", relationship.hostility, .relationHostility)
                    relationshipBar("敬畏", relationship.awe, .relationAwe)
                    relationshipBar("依赖", relationship.dependence, .relationDependence)

                    // Character description
                    Text(character.description)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, .spacing4)

                    // Unlocked events
                    if !relationship.unlockedEvents.isEmpty {
                        VStack(alignment: .leading, spacing: .spacing4) {
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
        .padding(.spacing16)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
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

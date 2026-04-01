import SwiftUI

struct SoloCharacterBattleCard: View {
    let character: Character
    let relation: RelationshipState?
    let intel: SoloCharacterIntel

    private var accent: Color {
        SoloCharacterCodex.accent(for: character, relation: relation)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoloCharacterPortraitView(character: character, relation: relation, height: 148)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(character.name)
                        .font(SoloTypography.label)
                        .foregroundStyle(SoloTheme.ink)
                    Text(character.title)
                        .font(.caption2)
                        .foregroundStyle(SoloTheme.gold.opacity(0.84))
                        .lineLimit(1)
                }
                Spacer()
                chip(text: SoloLocalization.localized(intel.recommendedTag.rawValue), tint: chipTint)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                metric(title: SoloLocalization.localized("牵引"), value: intel.resonance, tint: accent)
                metric(title: SoloLocalization.localized("局重"), value: intel.influence, tint: SoloTheme.gold)
                metric(title: SoloLocalization.localized("危险"), value: intel.danger, tint: SoloTheme.crimson)
            }

            Text(intel.statusLine)
                .font(.caption)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(4)
                .lineLimit(3)
        }
        .padding(14)
        .soloPanel(.evidence, prominence: intel.isInPlay ? 0.16 : 0.06)
    }

    private var chipTint: Color {
        switch intel.recommendedTag {
        case .pullable:
            return SoloTheme.jade
        case .highRisk:
            return SoloTheme.crimson
        case .pivotal:
            return SoloTheme.gold
        case .latent:
            return SoloTheme.muted
        }
    }

    private func metric(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SoloTheme.muted)
            Text("\(value)")
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func chip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.14)))
    }
}


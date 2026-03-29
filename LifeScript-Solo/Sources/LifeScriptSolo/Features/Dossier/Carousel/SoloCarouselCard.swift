import SwiftUI

struct SoloCarouselCard: View {
    let character: Character
    let relation: RelationshipState?
    let intel: SoloCharacterIntel
    let isFocused: Bool

    private var accent: Color {
        SoloCharacterCodex.accent(for: character, relation: relation)
    }

    var body: some View {
        VStack(spacing: 0) {
            SoloCharacterPortraitView(character: character, relation: relation, height: 230)
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 96)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(character.name)
                                .font(SoloTypography.sceneHeadline(size: 22))
                                .foregroundStyle(SoloTheme.ink)
                                .lineLimit(1)
                            Text(character.title)
                                .font(.caption)
                                .foregroundStyle(SoloTheme.warmInk)
                                .lineLimit(1)
                        }
                        .padding(14)
                    }
                }

            HStack(spacing: 8) {
                capsule(text: SoloCharacterCodex.roleLabel(for: character.role), tint: accent)
                capsule(text: relation?.attitudeLabel ?? "未入局", tint: relation == nil ? SoloTheme.muted : accent)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.25))
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SoloTheme.surfaceRaised.opacity(0.95),
                            Color.black.opacity(0.96),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(accent.opacity(isFocused ? 0.85 : 0.22), lineWidth: isFocused ? 1.5 : 1)
        )
        .shadow(color: accent.opacity(isFocused ? 0.35 : 0.0), radius: isFocused ? 20 : 0, x: 0, y: 10)
    }

    private func capsule(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule(style: .continuous).fill(tint.opacity(0.14)))
    }
}


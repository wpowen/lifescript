import SwiftUI

struct SoloDestinyStrip: View {
    let snapshot: SoloDossierSnapshot
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(destinyTint)

                Text("天命 \(snapshot.destinyStatus.value)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(destinyTint)

                Text("·")
                    .foregroundStyle(SoloTheme.muted)

                Text(snapshot.destinyStatus.headline)
                    .font(.caption)
                    .foregroundStyle(SoloTheme.ink)
                    .lineLimit(1)

                if let spotlight = snapshot.relationshipSpotlight {
                    Text("·")
                        .foregroundStyle(SoloTheme.muted)
                    Text("关键人 \(spotlight.characterName) · \(spotlight.attitudeLabel)")
                        .font(.caption)
                        .foregroundStyle(SoloTheme.warmInk)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SoloTheme.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var destinyTint: Color {
        switch snapshot.destinyStatus.level {
        case .abundant:
            return SoloTheme.jade
        case .steady:
            return SoloTheme.gold
        case .strained, .critical:
            return SoloTheme.crimson
        }
    }
}


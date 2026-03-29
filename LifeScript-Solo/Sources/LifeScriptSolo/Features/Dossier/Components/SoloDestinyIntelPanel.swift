import SwiftUI

struct SoloDestinyIntelPanel: View {
    let snapshot: SoloDossierSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("天机侧情报", systemImage: "eye.trianglebadge.exclamationmark")
                .font(SoloTypography.meta)
                .foregroundStyle(SoloTheme.gold)

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.destinyStatus.headline)
                    .font(SoloTypography.sceneHeadline(size: 20))
                    .foregroundStyle(SoloTheme.ink)
                Text("天命值 \(snapshot.destinyStatus.value)")
                    .font(.caption)
                    .foregroundStyle(destinyTint)
            }

            Text(snapshot.destinyStatus.thresholdHint)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(4)

            if let spotlight = snapshot.relationshipSpotlight {
                Divider()
                    .overlay(Color.white.opacity(0.08))
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前关键人物")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SoloTheme.warmInk)
                    Text("\(spotlight.characterName) · \(spotlight.attitudeLabel)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SoloTheme.ink)
                    Text(spotlight.reason ?? "暂无新的波动记录。")
                        .font(.caption)
                        .foregroundStyle(SoloTheme.muted)
                        .lineLimit(3)
                }
            }

            if let module = snapshot.moduleCards.first {
                Divider()
                    .overlay(Color.white.opacity(0.08))
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SoloTheme.warmInk)
                    Text(module.valueText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tintColor(for: module.tint))
                    Text(module.detailText)
                        .font(.caption)
                        .foregroundStyle(SoloTheme.muted)
                        .lineLimit(3)
                }
            }
        }
        .padding(16)
        .soloPanel(.evidence, prominence: 0.14)
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

    private func tintColor(for preset: SoloPalettePreset) -> Color {
        switch preset {
        case .ashCrimson, .royalPlum:
            return SoloTheme.crimson
        case .emberGold:
            return SoloTheme.gold
        case .moonJade, .oracleJade:
            return SoloTheme.jade
        case .sapphireMist:
            return SoloTheme.warmInk
        }
    }
}


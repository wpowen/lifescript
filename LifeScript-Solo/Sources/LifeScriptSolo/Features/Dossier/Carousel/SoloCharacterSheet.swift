import SwiftUI

struct SoloCharacterSheet: View {
    let entry: SoloCarouselEntry
    let destinyStatus: SoloDestinyStatus

    private var character: Character { entry.character }
    private var relation: RelationshipState? { entry.relation }
    private var intel: SoloCharacterIntel { entry.intel }

    private var accent: Color {
        SoloCharacterCodex.accent(for: character, relation: relation)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            identitySection
            metricsSection
            relationSection
            intelSection
            suggestionSection
        }
        .padding(20)
        .soloPanel(.stage, prominence: 0.16)
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(character.name)
                .font(SoloTypography.posterTitle(size: 30))
                .foregroundStyle(SoloTheme.ink)
            Text(character.title)
                .font(SoloTypography.meta)
                .foregroundStyle(SoloTheme.gold)
            HStack(spacing: 8) {
                chip(SoloCharacterCodex.roleLabel(for: character.role), tint: accent)
                chip(relation?.attitudeLabel ?? SoloLocalization.localized("未入局"), tint: relation == nil ? SoloTheme.muted : accent)
            }
        }
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SoloLocalization.localized("核心指标"))
                .font(SoloTypography.sectionTitle(size: 20))
                .foregroundStyle(SoloTheme.ink)

            HStack(spacing: 10) {
                miniMetric(title: SoloLocalization.localized("牵引"), value: intel.resonance, tint: accent)
                miniMetric(title: SoloLocalization.localized("局重"), value: intel.influence, tint: SoloTheme.gold)
                miniMetric(title: SoloLocalization.localized("危险"), value: intel.danger, tint: SoloTheme.crimson)
            }
        }
    }

    @ViewBuilder
    private var relationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SoloLocalization.localized("关系维度"))
                .font(SoloTypography.sectionTitle(size: 20))
                .foregroundStyle(SoloTheme.ink)

            if let relation {
                ForEach(SoloCharacterCodex.dimensions(for: relation), id: \.0.rawValue) { dimension, value in
                    SoloCharacterMeterRow(
                        title: dimension.displayName,
                        value: value,
                        tint: SoloCharacterCodex.tint(for: dimension)
                    )
                }
            } else {
                Text(SoloLocalization.localized("该角色仍在暗纹区，继续推进章节可解锁具体关系属性。"))
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
            }
        }
    }

    private var intelSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(SoloLocalization.localized("局中情报"))
                .font(SoloTypography.sectionTitle(size: 20))
                .foregroundStyle(SoloTheme.ink)
            Text(intel.statusLine)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(4)
        }
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(SoloLocalization.localized("行动建议"))
                .font(SoloTypography.sectionTitle(size: 20))
                .foregroundStyle(accent)
            Text(SoloCharacterCodex.thresholdHint(for: character, relation: relation))
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.warmInk)
                .lineSpacing(4)
            Text(SoloLocalization.format("命局联动：%@ · %@", destinyStatus.headline, destinyStatus.thresholdHint))
                .font(.caption)
                .foregroundStyle(SoloTheme.muted)
        }
    }

    private func chip(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule(style: .continuous).fill(tint.opacity(0.14)))
    }

    private func miniMetric(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SoloTheme.muted)
            Text("\(value)")
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(tint)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.88))
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct SoloCharacterSheetSceneView: View {
    let entry: SoloCarouselEntry
    let destinyStatus: SoloDestinyStatus

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                SoloCharacterSheet(entry: entry, destinyStatus: destinyStatus)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: entry.character.name, kicker: SoloLocalization.localized("角色面板"))
    }
}


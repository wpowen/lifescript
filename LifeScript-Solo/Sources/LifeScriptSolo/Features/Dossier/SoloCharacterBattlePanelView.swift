import SwiftUI

struct SoloCharacterBattlePanelView: View {
    let character: Character
    let relation: RelationshipState?
    let destinyStatus: SoloDestinyStatus?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var intel: SoloCharacterIntel {
        SoloCharacterIntel.build(character: character, relation: relation)
    }

    private var accent: Color {
        SoloCharacterCodex.accent(for: character, relation: relation)
    }

    private var layout: SoloCharacterResponsiveLayout {
        SoloCharacterResponsiveLayout(horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    heroStage
                    coreMetrics
                    relationSection
                    intelSection
                    actionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: character.name, kicker: SoloLocalization.localized("战局面板"))
    }

    private var heroStage: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoloCharacterPortraitView(character: character, relation: relation, height: 240)

            if layout.isCompact {
                VStack(alignment: .leading, spacing: 10) {
                    identityBlock
                    HStack(spacing: 8) {
                        statusChip(SoloCharacterCodex.roleLabel(for: character.role), tint: accent)
                        statusChip(relation?.attitudeLabel ?? SoloLocalization.localized("未入局"), tint: intel.isInPlay ? accent : SoloTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .top) {
                    identityBlock
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        statusChip(SoloCharacterCodex.roleLabel(for: character.role), tint: accent)
                        statusChip(relation?.attitudeLabel ?? SoloLocalization.localized("未入局"), tint: intel.isInPlay ? accent : SoloTheme.muted)
                    }
                }
            }
        }
        .padding(20)
        .soloPanel(.hero, prominence: 0.2)
    }

    private var coreMetrics: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SoloLocalization.localized("核心战局指标"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 10),
                    count: layout.detailMetricColumnCount
                ),
                spacing: 10
            ) {
                metricCard(title: SoloLocalization.localized("牵引"), value: intel.resonance, tint: accent)
                metricCard(title: SoloLocalization.localized("局重"), value: intel.influence, tint: SoloTheme.gold)
                metricCard(title: SoloLocalization.localized("危险"), value: intel.danger, tint: SoloTheme.crimson)
            }
        }
        .padding(20)
        .soloPanel(.stage, prominence: 0.14)
    }

    @ViewBuilder
    private var relationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SoloLocalization.localized("关系维度"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            if let relation {
                ForEach(SoloCharacterCodex.dimensions(for: relation), id: \.0.rawValue) { dimension, value in
                    SoloCharacterMeterRow(
                        title: dimension.rawValue,
                        value: value,
                        tint: SoloCharacterCodex.tint(for: dimension)
                    )
                }
            } else {
                Text(SoloLocalization.localized("该角色尚未完全显形。继续推进主线后再查看，可解锁具体关系维度。"))
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .soloPanel(.stage, prominence: 0.1)
    }

    private var intelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SoloLocalization.localized("局中情报"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)
            infoRow(title: SoloLocalization.localized("人物定位"), detail: SoloCharacterCodex.roleLabel(for: character.role))
            infoRow(title: SoloLocalization.localized("当前判断"), detail: SoloCharacterCodex.stanceSummary(for: character, relation: relation))
            infoRow(title: SoloLocalization.localized("最近波动"), detail: intel.statusLine)
        }
        .padding(20)
        .soloPanel(.evidence, prominence: 0.15)
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SoloLocalization.localized("行动建议"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(accent)
            Text(SoloCharacterCodex.thresholdHint(for: character, relation: relation))
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.warmInk)
                .lineSpacing(4)
            if let destinyStatus {
                Text(SoloLocalization.format("命局联动：%@ · %@", destinyStatus.headline, destinyStatus.thresholdHint))
                    .font(.caption)
                    .foregroundStyle(SoloTheme.muted)
            }
        }
        .padding(20)
        .soloPanel(.alert, prominence: 0.12)
    }

    private func statusChip(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule(style: .continuous).fill(tint.opacity(0.12)))
    }

    private func metricCard(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SoloTheme.muted)
            Text("\(value)")
                .font(SoloTypography.sceneHeadline(size: 20))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(character.name)
                .font(SoloTypography.posterTitle(size: 30))
                .foregroundStyle(SoloTheme.ink)
            Text(character.title)
                .font(SoloTypography.meta)
                .foregroundStyle(SoloTheme.gold)
        }
    }

    private func infoRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SoloTheme.gold)
            Text(detail)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(4)
        }
    }
}


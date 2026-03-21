import SwiftUI

struct StatsView: View {
    let stats: ProtagonistStats
    let previousStats: ProtagonistStats

    @Environment(\.dismiss) private var dismiss

    private var changes: [StatEffect.StatType: Int] {
        stats.diff(from: previousStats)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacing24) {
                    // Stats Overview Grid
                    overviewGrid

                    // Detailed Bars
                    detailedBars

                    // Legend
                    legendSection
                }
                .padding(.spacing16)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("主角属性")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    // MARK: - Overview Grid

    private var overviewGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: .spacing16) {
            ForEach(allStats, id: \.0) { stat, value, color in
                StatBadge(
                    label: stat.rawValue,
                    value: value,
                    color: color,
                    change: changes[stat] ?? 0
                )
                .padding(.spacing8)
                .background(Color.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
            }
        }
    }

    // MARK: - Detailed Bars

    private var detailedBars: some View {
        VStack(spacing: .spacing16) {
            Text("属性详情")
                .font(.labelMedium)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(allStats, id: \.0) { stat, value, color in
                StatBar(
                    label: stat.rawValue,
                    value: value,
                    maxValue: ProtagonistStats.maxValue,
                    color: color,
                    change: changes[stat] ?? 0
                )
            }
        }
        .padding(.spacing16)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text("属性说明")
                .font(.labelSmall)
                .foregroundStyle(Color.textTertiary)

            Group {
                legendRow("战力", "战斗能力和实力等级")
                legendRow("名望", "在世界中的声望和影响力")
                legendRow("谋略", "智慧、策略和计谋能力")
                legendRow("财富", "金钱和资源积累")
                legendRow("魅力", "个人魅力和人际吸引力")
                legendRow("黑化值", "黑暗面倾向，影响剧情走向")
                legendRow("天命值", "命运眷顾程度，影响奇遇概率")
            }
        }
        .padding(.spacing16)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
    }

    private func legendRow(_ name: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: .spacing8) {
            Text(name)
                .font(.labelSmall)
                .foregroundStyle(Color.textPrimary)
                .frame(width: 50, alignment: .leading)
            Text(desc)
                .font(.captionLarge)
                .foregroundStyle(Color.textTertiary)
        }
    }

    // MARK: - Data

    private var allStats: [(StatEffect.StatType, Int, Color)] {
        [
            (.combat, stats.combat, .statCombat),
            (.fame, stats.fame, .statFame),
            (.strategy, stats.strategy, .statStrategy),
            (.wealth, stats.wealth, .statWealth),
            (.charm, stats.charm, .statCharm),
            (.darkness, stats.darkness, .statDarkness),
            (.destiny, stats.destiny, .statDestiny),
        ]
    }
}

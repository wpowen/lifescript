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
            ZStack {
                SceneBackdrop(palette: StoryPalette(primary: .accentGold, secondary: .accentCrimson, tertiary: .accentSky))

                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing24) {
                        headerSection
                        overviewGrid
                        detailedBars
                        legendSection
                    }
                    .padding(.horizontal, .spacing16)
                    .padding(.top, .spacing20)
                    .padding(.bottom, .spacing40)
                }
            }
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            ScenePageHeader(
                eyebrow: "操盘面板",
                title: "主角现在正在往哪种气质生长",
                subtitle: "把成长趋势说成用户能理解的戏剧方向，而不是孤立的数字堆。",
                accent: .accentGold
            )

            HStack(spacing: .spacing10) {
                SceneMetricPill(title: "主轴", value: dominantStat.label, systemImage: dominantStat.icon, color: dominantStat.color)
                SceneMetricPill(title: "本章变化", value: "\(changes.count) 项", systemImage: "sparkles", color: .accentCrimson)
                SceneMetricPill(title: "当前风格", value: currentTrajectory, systemImage: "point.topleft.down.curvedto.point.bottomright.up", color: .accentSky)
            }
        }
    }

    private var overviewGrid: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "当前数值总览",
                subtitle: "先快速看清哪几项最强。",
                accent: .accentGold
            )

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: .spacing12) {
                ForEach(allStats, id: \.0) { stat, value, color in
                    StatBadge(
                        label: stat.rawValue,
                        value: value,
                        color: color,
                        change: changes[stat] ?? 0
                    )
                    .scenePanel(accent: color, padding: .spacing12)
                }
            }
        }
    }

    private var detailedBars: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "成长细节",
                subtitle: "每条属性都带上本章增减，反馈更直接。",
                accent: .accentCrimson
            )

            VStack(spacing: .spacing16) {
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
            .scenePanel(accent: .accentCrimson, padding: .spacing18)
        }
    }

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "属性怎么影响剧情",
                subtitle: "把每个维度翻译成用户能预判的后果。",
                accent: .accentSky
            )

            VStack(alignment: .leading, spacing: .spacing12) {
                legendRow("战力", "决定正面碾压能力，越高越容易拿到直接爽。")
                legendRow("名望", "决定别人是否会主动注意到你，抬高打脸场面的分量。")
                legendRow("谋略", "决定布局、反转和借刀杀人的空间。")
                legendRow("财富", "决定资源调度和局势撬动能力。")
                legendRow("魅力", "决定角色互动的吸引力和压场能力。")
                legendRow("黑化值", "越高越容易走更狠、更冷、更危险的推进风格。")
                legendRow("天命值", "越高越容易出现奇遇、时机和命运偏向。")
            }
            .scenePanel(accent: .accentSky, padding: .spacing18)
        }
    }

    private func legendRow(_ name: String, _ desc: String) -> some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            Text(name)
                .font(.labelSmall)
                .foregroundStyle(Color.textPrimary)
            Text(desc)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
        }
    }

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

    private var dominantStat: (label: String, value: Int, color: Color, icon: String) {
        let items: [(String, Int, Color, String)] = [
            ("战力", stats.combat, .statCombat, "flame.fill"),
            ("名望", stats.fame, .statFame, "crown.fill"),
            ("谋略", stats.strategy, .statStrategy, "brain.head.profile"),
            ("财富", stats.wealth, .statWealth, "banknote.fill"),
            ("魅力", stats.charm, .statCharm, "heart.fill"),
            ("黑化", stats.darkness, .statDarkness, "moon.stars.fill"),
            ("天命", stats.destiny, .statDestiny, "sparkles"),
        ]
        return items.max(by: { $0.1 < $1.1 }) ?? ("未定", 0, .accentGold, "scope")
    }

    private var currentTrajectory: String {
        switch dominantStat.label {
        case "战力":
            "正面碾压"
        case "名望":
            "高调登场"
        case "谋略":
            "暗线布局"
        case "财富":
            "资源操盘"
        case "魅力":
            "人心收拢"
        case "黑化":
            "冷狠推进"
        case "天命":
            "命运偏爱"
        default:
            "走向未定"
        }
    }
}

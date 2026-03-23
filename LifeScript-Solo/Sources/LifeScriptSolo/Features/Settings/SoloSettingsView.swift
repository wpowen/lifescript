import SwiftUI

struct SoloSettingsView: View {
    @AppStorage("solo.reduceMotion") private var reduceMotion = false
    @AppStorage("solo.autoShowSettlement") private var autoShowSettlement = true
    @AppStorage("solo.largeReadingType") private var largeReadingType = false
    private let branding = SoloStoryConfig.branding

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroPanel
                    readingSection
                    positioningSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: "设置", kicker: "偏好")
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("阅读仪式")
                .font(SoloTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(SoloTheme.gold)
            Text(branding.storyDisplayName)
                .font(SoloTypography.posterTitle(size: 30))
                .foregroundStyle(SoloTheme.ink)
            Text("每一次打开，都从故事本身开始。这里只有真正影响阅读体验的选项。")
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(6)
        }
        .padding(24)
        .soloPanel(.hero, prominence: 0.18)
    }

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("阅读体验")
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(spacing: 12) {
                settingsToggleCard(
                    title: "本章结束后自动展开影响面板",
                    detail: "让章末情绪和属性变化直接接上，不需要再多点一步。",
                    isOn: $autoShowSettlement,
                    accent: SoloTheme.gold
                )
                settingsToggleCard(
                    title: "增大阅读字号",
                    detail: "提升单手长时间阅读的舒适度，适合更沉浸的文本体验。",
                    isOn: $largeReadingType,
                    accent: SoloTheme.jade
                )
                settingsToggleCard(
                    title: "降低界面动效",
                    detail: "保留结构反馈，但尽量减少转场和位移动画。",
                    isOn: $reduceMotion,
                    accent: SoloTheme.crimson
                )
            }
        }
        .padding(22)
        .soloPanel(.stage)
    }

    private var positioningSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("关于本作")
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            valueStatement(
                title: "买断，即完整体验",
                detail: "一次购买，所有章节全部开放，没有广告，没有追加内购。"
            )
            valueStatement(
                title: "专为 \(branding.storyDisplayName) 打造",
                detail: "这个应用只服务于这一部作品，界面节奏与故事本身同步打磨。"
            )
            valueStatement(
                title: "值得多次重玩",
                detail: "路线图、人物关系与章末结算，都为你想走另一条路而准备。"
            )
        }
        .padding(22)
        .soloPanel(.stage)
    }

    private func settingsToggleCard(
        title: String,
        detail: String,
        isOn: Binding<Bool>,
        accent: Color
    ) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(SoloTypography.label)
                    .foregroundStyle(SoloTheme.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(SoloTheme.muted)
                    .lineSpacing(4)
            }
        }
        .toggleStyle(.switch)
        .tint(accent)
        .padding(18)
        .soloPanel(.evidence, prominence: 0.14)
    }

    private func valueStatement(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SoloTypography.label)
                .foregroundStyle(SoloTheme.gold)
            Text(detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)
        }
        .padding(18)
        .soloPanel(.evidence)
    }
}

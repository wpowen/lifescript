import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            SceneBackdrop(palette: StoryPalette(primary: .accentAmber, secondary: .accentSky, tertiary: .accentCrimson))

            ScrollView {
                VStack(alignment: .leading, spacing: .spacing24) {
                    headerSection

                    settingsSection(title: "阅读体验", subtitle: "控制你看故事时的感受与反馈节奏", items: [
                        ("textformat.size", "字体大小", "让正文更适合长时间沉浸"),
                        ("moon.stars.fill", "夜间模式", "在不同光线下保持可读"),
                        ("speaker.wave.2.fill", "音效反馈", "保留轻微动态和提示音"),
                    ])

                    settingsSection(title: "账号与权益", subtitle: "同步进度、解锁内容和后续会员能力", items: [
                        ("person.badge.plus", "登录 / 注册", "保存你的故事档案"),
                        ("crown.fill", "会员订阅", "查看后续权益规划"),
                        ("creditcard.fill", "购买记录", "回看已解锁内容"),
                    ])

                    settingsSection(title: "帮助与说明", subtitle: "把产品边界和规则讲清楚", items: [
                        ("questionmark.circle.fill", "帮助与反馈", "遇到问题时快速反馈"),
                        ("doc.text.fill", "用户协议", "查看使用条款"),
                        ("lock.shield.fill", "隐私政策", "查看数据与隐私说明"),
                        ("info.circle.fill", "关于命书", "版本 1.0.0"),
                    ])
                }
                .padding(.horizontal, .spacing16)
                .padding(.top, .spacing20)
                .padding(.bottom, .spacing40)
            }
        }
        .navigationTitle("我的")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            ScenePageHeader(
                eyebrow: "个人操盘台",
                title: "你的身份、偏好和阅读设定都在这里",
                subtitle: "这一页不只是设置页，而是你的故事身份页。所有入口都用明确文字说明作用。",
                accent: .accentAmber
            )

            HStack(spacing: .spacing16) {
                Circle()
                    .fill(Color.surfaceSecondary)
                    .frame(width: 84, height: 84)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.accentAmber)
                    )

                VStack(alignment: .leading, spacing: .spacing6) {
                    Text("游客用户")
                        .font(.titleMedium)
                        .foregroundStyle(Color.textPrimary)

                    Text("登录后可同步你的故事进度、选择记录和关系变化。")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(4)

                    SceneAccentBadge(text: "身份未绑定", color: .accentCrimson)
                }
            }
            .scenePanel(accent: .accentAmber, padding: .spacing18)
        }
    }

    private func settingsSection(title: String, subtitle: String, items: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: title,
                subtitle: subtitle,
                accent: .accentSky
            )

            VStack(spacing: .spacing12) {
                ForEach(items, id: \.1) { icon, label, detail in
                    HStack(alignment: .top, spacing: .spacing12) {
                        Image(systemName: icon)
                            .font(.bodyMedium)
                            .foregroundStyle(Color.accentAmber)
                            .frame(width: 24, height: 24)

                        VStack(alignment: .leading, spacing: .spacing4) {
                            Text(label)
                                .font(.labelMedium)
                                .foregroundStyle(Color.textPrimary)

                            Text(detail)
                                .font(.captionLarge)
                                .foregroundStyle(Color.textSecondary)
                                .lineSpacing(3)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.captionSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .scenePanel(accent: .accentSky, padding: .spacing16)
                }
            }
        }
    }
}

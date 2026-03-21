import SwiftUI

struct ProfileView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(spacing: .spacing24) {
                // User avatar
                VStack(spacing: .spacing12) {
                    Circle()
                        .fill(Color.surfaceHighlight)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.textTertiary)
                        )
                    Text("游客用户")
                        .font(.titleMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text("登录后可同步阅读进度")
                        .font(.captionLarge)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacing24)

                // Settings sections
                settingsSection(title: "阅读设置", items: [
                    ("textformat.size", "字体大小", nil),
                    ("moon", "夜间模式", nil),
                    ("speaker.wave.2", "音效", nil),
                ])

                settingsSection(title: "账号", items: [
                    ("person.badge.plus", "登录 / 注册", nil),
                    ("crown", "会员订阅", nil),
                    ("creditcard", "购买记录", nil),
                ])

                settingsSection(title: "其他", items: [
                    ("questionmark.circle", "帮助与反馈", nil),
                    ("doc.text", "用户协议", nil),
                    ("lock.shield", "隐私政策", nil),
                    ("info.circle", "关于命书", "v1.0.0"),
                ])
            }
            .padding(.spacing16)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("我的")
    }

    private func settingsSection(title: String, items: [(String, String, String?)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.labelSmall)
                .foregroundStyle(Color.textTertiary)
                .padding(.bottom, .spacing8)

            VStack(spacing: 0) {
                ForEach(items, id: \.1) { icon, label, detail in
                    HStack {
                        Image(systemName: icon)
                            .font(.bodyMedium)
                            .foregroundStyle(Color.accentGold)
                            .frame(width: 24)
                        Text(label)
                            .font(.bodyLarge)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        if let detail {
                            Text(detail)
                                .font(.captionLarge)
                                .foregroundStyle(Color.textTertiary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.captionSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.vertical, .spacing12)
                    .padding(.horizontal, .spacing12)

                    if label != items.last?.1 {
                        Divider()
                            .background(Color.surfaceHighlight)
                            .padding(.leading, 48)
                    }
                }
            }
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
        }
    }
}

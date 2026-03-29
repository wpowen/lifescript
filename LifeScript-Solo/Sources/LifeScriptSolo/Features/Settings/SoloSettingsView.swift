import SwiftUI

struct SoloSettingsView: View {
    @AppStorage("solo.reduceMotion") private var reduceMotion = false
    @AppStorage("solo.largeReadingType") private var largeReadingType = false
    @AppStorage(SoloLocalization.storageKey) private var appLanguageRawValue = SoloAppLanguage.system.rawValue
    private let branding = SoloStoryConfig.branding
    let book: Book

    private var appLanguage: SoloAppLanguage {
        SoloAppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    private var translationAvailability: [SoloTranslationAvailability] {
        SoloTranslationCatalog.chapterAvailability(
            for: book.id,
            totalChapterCount: book.totalChapters
        )
    }

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroPanel
                    languageSection
                    readingSection
                    helpSection
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
                valueStatement(
                    title: "章节总结改为手动查看",
                    detail: "章末不会再自动弹出封存面板。你可以先看完最后一个决策的结果，再决定是否打开这一局总结或直接进入下一章。"
                )
            }
        }
        .padding(22)
        .soloPanel(.stage)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("语言与翻译")
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("界面语言")
                        .font(SoloTypography.label)
                        .foregroundStyle(SoloTheme.gold)

                    Picker("界面语言", selection: $appLanguageRawValue) {
                        ForEach(SoloAppLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(SoloTheme.gold)

                    Text(
                        SoloLocalization.format(
                            "当前会优先显示 %@ 文案；未完成翻译的章节会自动回退到中文原文。",
                            appLanguage.resolved.displayName
                        )
                    )
                        .font(.footnote)
                        .foregroundStyle(SoloTheme.muted)
                        .lineSpacing(4)
                }
                .padding(18)
                .soloPanel(.evidence, prominence: 0.14)

                VStack(alignment: .leading, spacing: 10) {
                    Text("章节翻译进度")
                        .font(SoloTypography.label)
                        .foregroundStyle(SoloTheme.gold)

                    ForEach(translationAvailability) { availability in
                        translationStatusCard(availability)
                    }
                }
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
                title: "当前版本完整体验",
                detail: "一次下载，当前版本已上线章节均可直接阅读，没有广告，没有追加内购。"
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

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("帮助与说明")
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(spacing: 12) {
                settingsLinkCard(
                    title: "隐私政策",
                    detail: "查看本地阅读数据、邮件联系与隐私处理方式。",
                    systemImage: "hand.raised.fill",
                    tint: SoloTheme.jade,
                    destination: .privacy
                )
                settingsLinkCard(
                    title: "用户支持",
                    detail: "遇到闪退、进度异常或章节问题时，从这里找到帮助。",
                    systemImage: "questionmark.circle.fill",
                    tint: SoloTheme.gold,
                    destination: .support
                )
                settingsLinkCard(
                    title: "联系我们",
                    detail: "反馈问题、商务合作或隐私请求，都可以从这里查看联系信息。",
                    systemImage: "envelope.fill",
                    tint: SoloTheme.crimson,
                    destination: .contact
                )
                settingsLinkCard(
                    title: "内容分级说明",
                    detail: "提前说明本作涉及的幻想暴力、血腥与黑暗主题范围。",
                    systemImage: "exclamationmark.shield.fill",
                    tint: SoloTheme.warmInk,
                    destination: .contentRating
                )
            }
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

    private func settingsLinkCard(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color,
        destination: SoloInfoDocumentKind
    ) -> some View {
        NavigationLink {
            SoloInfoDocumentView(kind: destination)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(SoloTypography.label)
                        .foregroundStyle(SoloTheme.ink)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(SoloTheme.muted)
                        .lineSpacing(4)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SoloTheme.muted)
            }
            .padding(18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private func translationStatusCard(_ availability: SoloTranslationAvailability) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(availability.language.displayName)
                    .font(SoloTypography.label)
                    .foregroundStyle(SoloTheme.ink)

                Spacer()

                Text("\(availability.translatedChapterCount) / \(availability.totalChapterCount)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SoloTheme.gold)
            }

            ProgressView(value: availability.coverageRatio)
                .tint(availability.language == .zhHans ? SoloTheme.jade : SoloTheme.gold)

            Text(
                availability.language == .zhHans
                    ? SoloLocalization.localized("中文原文已完整收录。")
                    : SoloLocalization.format(
                        "已完成 %d%% 章节翻译，其余章节会显示中文原文。",
                        Int((availability.coverageRatio * 100).rounded())
                    )
            )
                .font(.footnote)
                .foregroundStyle(SoloTheme.muted)
        }
        .padding(18)
        .soloPanel(.evidence, prominence: 0.14)
    }
}

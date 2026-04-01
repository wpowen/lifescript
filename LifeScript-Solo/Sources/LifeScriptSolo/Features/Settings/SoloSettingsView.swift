import SwiftUI

struct SoloSettingsView: View {
    @AppStorage("solo.reduceMotion") private var reduceMotion = false
    @AppStorage("solo.largeReadingType") private var largeReadingType = false
    @AppStorage(SoloLocalization.storageKey) private var appLanguageRawValue = SoloAppLanguage.system.rawValue
    private let branding = SoloStoryConfig.branding
    let book: Book
    let volumeStore: SoloVolumeStore

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
                    purchaseSection
                    helpSection
                    positioningSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: SoloLocalization.localized("设置"), kicker: SoloLocalization.localized("偏好"))
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SoloLocalization.localized("阅读仪式"))
                .font(SoloTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(SoloTheme.gold)
            Text(branding.storyDisplayName)
                .font(SoloTypography.posterTitle(size: 30))
                .foregroundStyle(SoloTheme.ink)
            Text(SoloLocalization.localized("每一次打开，都从故事本身开始。这里只有真正影响阅读体验的选项。"))
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(6)
        }
        .padding(24)
        .soloPanel(.hero, prominence: 0.18)
    }

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(SoloLocalization.localized("阅读体验"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(spacing: 12) {
                settingsToggleCard(
                    title: SoloLocalization.localized("增大阅读字号"),
                    detail: SoloLocalization.localized("提升单手长时间阅读的舒适度，适合更沉浸的文本体验。"),
                    isOn: $largeReadingType,
                    accent: SoloTheme.jade
                )
                settingsToggleCard(
                    title: SoloLocalization.localized("降低界面动效"),
                    detail: SoloLocalization.localized("保留结构反馈，但尽量减少转场和位移动画。"),
                    isOn: $reduceMotion,
                    accent: SoloTheme.crimson
                )
                valueStatement(
                    title: SoloLocalization.localized("章节总结改为手动查看"),
                    detail: SoloLocalization.localized("章末不会再自动弹出封存面板。你可以先看完最后一个决策的结果，再决定是否打开这一局总结或直接进入下一章。")
                )
            }
        }
        .padding(22)
        .soloPanel(.stage)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(SoloLocalization.localized("语言与翻译"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(SoloLocalization.localized("界面语言"))
                        .font(SoloTypography.label)
                        .foregroundStyle(SoloTheme.gold)

                    Picker(SoloLocalization.localized("界面语言"), selection: $appLanguageRawValue) {
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
                    Text(SoloLocalization.localized("章节翻译进度"))
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

    // MARK: - Purchase Management

    private var purchaseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(SoloLocalization.localized("购买管理"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(spacing: 12) {
                purchaseStatusCard

                Button {
                    Task { _ = await volumeStore.restorePurchases() }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SoloTheme.jade)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(SoloLocalization.localized("恢复购买"))
                                .font(SoloTypography.label)
                                .foregroundStyle(SoloTheme.ink)
                            Text(SoloLocalization.localized("换设备或重新安装后，可在此恢复之前购买过的卷。"))
                                .font(.footnote)
                                .foregroundStyle(SoloTheme.muted)
                                .lineSpacing(4)
                        }

                        Spacer()

                        if volumeStore.isRestoring {
                            ProgressView()
                                .tint(SoloTheme.gold)
                        }
                    }
                    .padding(18)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .soloPanel(.evidence, prominence: 0.14)
                .disabled(volumeStore.isOperationInProgress)

                if let statusMessage = volumeStore.statusMessage {
                    Text(statusMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SoloTheme.warmInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(22)
        .soloPanel(.stage)
    }

    private var purchaseStatusCard: some View {
        let unlockedCount = volumeStore.plans.filter { volumeStore.isUnlocked($0) }.count
        let totalCount = volumeStore.plans.count
        let allUnlocked = unlockedCount == totalCount

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(SoloLocalization.localized("卷解锁状态"))
                    .font(SoloTypography.label)
                    .foregroundStyle(SoloTheme.gold)
                Spacer()
                Text("\(unlockedCount) / \(totalCount)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(allUnlocked ? SoloTheme.jade : SoloTheme.gold)
            }
            ProgressView(value: Double(unlockedCount), total: Double(totalCount))
                .tint(allUnlocked ? SoloTheme.jade : SoloTheme.gold)
            Text(
                allUnlocked
                    ? SoloLocalization.localized("所有卷已解锁，可以畅读完整故事。")
                    : SoloLocalization.localized("卷一免费开放，后续按卷单独解锁，永久有效。")
            )
                .font(.footnote)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(4)
        }
        .padding(18)
        .soloPanel(.evidence, prominence: 0.14)
    }

    private var positioningSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(SoloLocalization.localized("关于本作"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            valueStatement(
                title: SoloLocalization.localized("卷一免费，后续按卷解锁"),
                detail: SoloLocalization.localized("卷一完整免费体验，后续每卷单独购买、永久有效。没有广告，没有订阅，没有消耗型道具。")
            )
            valueStatement(
                title: SoloLocalization.format("专为 %@ 打造", branding.storyDisplayName),
                detail: SoloLocalization.localized("这个应用只服务于这一部作品，界面节奏与故事本身同步打磨。")
            )
            valueStatement(
                title: SoloLocalization.localized("值得多次重玩"),
                detail: SoloLocalization.localized("路线图、人物关系与章末结算，都为你想走另一条路而准备。")
            )
        }
        .padding(22)
        .soloPanel(.stage)
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(SoloLocalization.localized("帮助与说明"))
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            VStack(spacing: 12) {
                settingsLinkCard(
                    title: SoloLocalization.localized("隐私政策"),
                    detail: SoloLocalization.localized("查看本地阅读数据、邮件联系与隐私处理方式。"),
                    systemImage: "hand.raised.fill",
                    tint: SoloTheme.jade,
                    destination: .privacy
                )
                settingsLinkCard(
                    title: SoloLocalization.localized("用户支持"),
                    detail: SoloLocalization.localized("遇到闪退、进度异常或章节问题时，从这里找到帮助。"),
                    systemImage: "questionmark.circle.fill",
                    tint: SoloTheme.gold,
                    destination: .support
                )
                settingsLinkCard(
                    title: SoloLocalization.localized("联系我们"),
                    detail: SoloLocalization.localized("反馈问题、商务合作或隐私请求，都可以从这里查看联系信息。"),
                    systemImage: "envelope.fill",
                    tint: SoloTheme.crimson,
                    destination: .contact
                )
                settingsLinkCard(
                    title: SoloLocalization.localized("内容分级说明"),
                    detail: SoloLocalization.localized("提前说明本作涉及的幻想暴力、血腥与黑暗主题范围。"),
                    systemImage: "exclamationmark.shield.fill",
                    tint: SoloTheme.warmInk,
                    destination: .contentRating
                )
            }
        }
        .padding(22)
        .soloPanel(.stage)
    }

    // MARK: - Reusable Components

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

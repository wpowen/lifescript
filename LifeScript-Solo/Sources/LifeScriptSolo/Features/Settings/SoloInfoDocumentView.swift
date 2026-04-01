import SwiftUI

enum SoloInfoDocumentKind: String, Hashable, CaseIterable, Identifiable {
    case privacy
    case support
    case contact
    case contentRating

    var id: String { rawValue }
}

struct SoloInfoSection: Identifiable {
    let id: String
    let title: String
    let body: String
    let bullets: [String]
}

struct SoloInfoDocument {
    let title: String
    let kicker: String
    let summary: String
    let footnote: String?
    let sections: [SoloInfoSection]
}

enum SoloInfoDocumentLibrary {
    static let supportEmail = "wpowening@gmail.com"

    static func document(for kind: SoloInfoDocumentKind) -> SoloInfoDocument {
        let appName = SoloStoryConfig.branding.storyDisplayName

        switch kind {
        case .privacy:
            return SoloInfoDocument(
                title: SoloLocalization.localized("隐私政策"),
                kicker: SoloLocalization.localized("法律与说明"),
                summary: SoloLocalization.format("%@ 以离线阅读为核心，不要求注册账号，也不以广告、埋点或第三方画像为前提来提供内容体验。", appName),
                footnote: SoloLocalization.localized("公开网页版上线后，本页内容可同步发布到 GitHub Pages。"),
                sections: [
                    SoloInfoSection(
                        id: "privacy-collected",
                        title: SoloLocalization.localized("1. 我们处理什么信息"),
                        body: SoloLocalization.localized("当前版本不会主动收集姓名、手机号、通讯录、相册、位置、麦克风、相机等个人信息。应用内只会在设备本地保存与阅读体验有关的数据。"),
                        bullets: [
                            SoloLocalization.localized("本地阅读进度与最近阅读时间"),
                            SoloLocalization.localized("阅读偏好，例如字号与动效开关"),
                            SoloLocalization.localized("你在章节中的本地选择结果，用于续读与结算"),
                        ]
                    ),
                    SoloInfoSection(
                        id: "privacy-purpose",
                        title: SoloLocalization.localized("2. 为什么需要这些信息"),
                        body: SoloLocalization.localized("这些信息只用于完成你已经触发的本地功能，不会用于广告投放、用户画像或出售给第三方。"),
                        bullets: [
                            SoloLocalization.localized("恢复你上次阅读到的章节位置"),
                            SoloLocalization.localized("保留角色关系、数值与章节余波"),
                            SoloLocalization.localized("记住你的阅读偏好，减少重复设置"),
                        ]
                    ),
                    SoloInfoSection(
                        id: "privacy-sharing",
                        title: SoloLocalization.localized("3. 共享与删除"),
                        body: SoloLocalization.localized("当前版本不内置第三方广告、统计或账号系统，因此不会将上述本地数据常规共享给第三方。若你需要协助删除本地阅读数据或咨询隐私问题，可通过下方邮箱联系我们。"),
                        bullets: [
                            SoloLocalization.localized("默认不做跨设备同步"),
                            SoloLocalization.localized("默认不做追踪与广告归因"),
                            SoloLocalization.localized("如你主动发邮件联系我们，邮件内容仅用于处理支持请求"),
                        ]
                    ),
                ]
            )

        case .support:
            return SoloInfoDocument(
                title: SoloLocalization.localized("用户支持"),
                kicker: SoloLocalization.localized("帮助中心"),
                summary: SoloLocalization.localized("如果你在阅读过程中遇到闪退、进度异常、章节装载失败或文案问题，可以直接联系支持邮箱。"),
                footnote: SoloLocalization.localized("建议在邮件里附上机型、系统版本、问题截图和复现步骤。"),
                sections: [
                    SoloInfoSection(
                        id: "support-scope",
                        title: SoloLocalization.localized("1. 可支持的问题"),
                        body: SoloLocalization.localized("我们优先处理影响阅读体验和稳定性的实际问题。"),
                        bullets: [
                            SoloLocalization.localized("应用无法启动或章节装载失败"),
                            SoloLocalization.localized("阅读进度丢失、章节顺序异常、结算不一致"),
                            SoloLocalization.localized("界面显示错误、文字错漏、按钮无响应"),
                            SoloLocalization.localized("对内容分级、隐私政策或版本说明的咨询"),
                        ]
                    ),
                    SoloInfoSection(
                        id: "support-contact",
                        title: SoloLocalization.localized("2. 联系方式"),
                        body: SoloLocalization.format("支持邮箱：%@", supportEmail),
                        bullets: [
                            SoloLocalization.format("邮件标题建议包含\"%@ 支持\"", appName),
                            SoloLocalization.localized("通常会在 3 个工作日内回复"),
                            SoloLocalization.localized("复杂问题会先确认信息，再同步进展"),
                        ]
                    ),
                ]
            )

        case .contact:
            return SoloInfoDocument(
                title: SoloLocalization.localized("联系我们"),
                kicker: SoloLocalization.localized("开发者信息"),
                summary: SoloLocalization.localized("若你有合作建议、内容反馈、隐私请求或媒体沟通需求，可以通过以下方式联系开发者。"),
                footnote: SoloLocalization.localized("后续公开网页链接上线后，可直接在该页展示外部联系入口。"),
                sections: [
                    SoloInfoSection(
                        id: "contact-primary",
                        title: SoloLocalization.localized("1. 首选联系渠道"),
                        body: SoloLocalization.format("邮箱：%@", supportEmail),
                        bullets: [
                            SoloLocalization.localized("问题反馈"),
                            SoloLocalization.localized("商务合作"),
                            SoloLocalization.localized("隐私与数据请求"),
                            SoloLocalization.localized("媒体与内容沟通"),
                        ]
                    ),
                    SoloInfoSection(
                        id: "contact-notes",
                        title: SoloLocalization.localized("2. 联系时建议说明"),
                        body: SoloLocalization.localized("为了更快处理，请尽量提供完整上下文。"),
                        bullets: [
                            SoloLocalization.localized("你的设备型号与系统版本"),
                            SoloLocalization.localized("发生问题的章节编号或页面位置"),
                            SoloLocalization.localized("出现问题前后的操作步骤"),
                            SoloLocalization.localized("必要时附上截图或录屏"),
                        ]
                    ),
                ]
            )

        case .contentRating:
            return SoloInfoDocument(
                title: SoloLocalization.localized("内容分级说明"),
                kicker: SoloLocalization.localized("适龄提示"),
                summary: SoloLocalization.format("%@ 属于剧情向互动小说，包含持续性的幻想暴力、血腥描述、死亡威胁、心理压迫与黑暗主题，不适合低龄用户。", appName),
                footnote: SoloLocalization.localized("提审时建议在 App Store 年龄分级与 Review Notes 中同步说明上述内容属性。"),
                sections: [
                    SoloInfoSection(
                        id: "rating-scope",
                        title: SoloLocalization.localized("1. 可能出现的内容"),
                        body: SoloLocalization.localized("作品核心冲突围绕修仙世界中的谋局、生死对抗与代价选择展开，因此会出现较明显的压迫性叙事。"),
                        bullets: [
                            SoloLocalization.localized("幻想暴力、战斗与追杀"),
                            SoloLocalization.localized("血腥或伤亡描述"),
                            SoloLocalization.localized("死亡、献祭、囚禁、折磨等黑暗情节"),
                            SoloLocalization.localized("角色之间的威胁、背叛与心理压迫"),
                        ]
                    ),
                    SoloInfoSection(
                        id: "rating-guidance",
                        title: SoloLocalization.localized("2. 建议分级"),
                        body: SoloLocalization.localized("从当前文本强度看，建议按较高年龄分级提交，并避免在首图或首屏宣传中过度弱化真实内容强度。"),
                        bullets: [
                            SoloLocalization.localized("建议按 17+ 的保守口径准备提审材料"),
                            SoloLocalization.localized("在商店文案中明确\"互动小说 / 剧情选择 / 幻想暴力\""),
                            SoloLocalization.localized("在审核备注中说明无露骨性内容、无用户生成内容"),
                        ]
                    ),
                ]
            )
        }
    }
}

struct SoloInfoDocumentView: View {
    let kind: SoloInfoDocumentKind

    private var document: SoloInfoDocument {
        SoloInfoDocumentLibrary.document(for: kind)
    }

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    ForEach(document.sections) { section in
                        sectionCard(section)
                    }

                    if let footnote = document.footnote {
                        Text(footnote)
                            .font(.footnote)
                            .foregroundStyle(SoloTheme.muted)
                            .lineSpacing(4)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: document.title, kicker: document.kicker)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(document.title)
                .font(SoloTypography.posterTitle(size: 30))
                .foregroundStyle(SoloTheme.ink)
            Text(document.summary)
                .foregroundStyle(SoloTheme.warmInk)
                .lineSpacing(6)
        }
        .padding(22)
        .soloPanel(.hero, prominence: 0.16)
    }

    private func sectionCard(_ section: SoloInfoSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(SoloTypography.sectionTitle())
                .foregroundStyle(SoloTheme.ink)

            Text(section.body)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)

            if !section.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(section.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(SoloTheme.gold.opacity(0.85))
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                            Text(bullet)
                                .foregroundStyle(SoloTheme.warmInk)
                                .lineSpacing(4)
                        }
                    }
                }
            }
        }
        .padding(20)
        .soloPanel(.stage, prominence: 0.16)
    }
}

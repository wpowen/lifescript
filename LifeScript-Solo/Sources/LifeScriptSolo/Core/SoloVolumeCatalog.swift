import Foundation

struct SoloVolumePlan: Identifiable, Equatable, Sendable {
    let storyId: String
    let index: Int
    let chapterRange: ClosedRange<Int>
    let title: String
    let teaser: String
    let productID: String?
    let fallbackPriceText: String

    var id: String {
        "\(storyId).volume.\(index)"
    }

    var isFree: Bool {
        productID == nil
    }

    var shortTitle: String {
        SoloLocalization.format("第%d卷", index)
    }

    var localizedTitle: String {
        SoloLocalization.localized(title)
    }

    var localizedTeaser: String {
        SoloLocalization.localized(teaser)
    }
}

struct SoloChapterAccessState: Equatable, Sendable {
    let chapterId: String
    let isLocked: Bool
    let volume: SoloVolumePlan?
    let primaryActionTitle: String
    let supportingLine: String?
}

enum SoloVolumeCatalog {
    static func plans(for storyId: String) -> [SoloVolumePlan] {
        switch storyId {
        case "天机录":
            return tianjiluPlans
        default:
            return []
        }
    }

    static func volume(for storyId: String, chapterNumber: Int) -> SoloVolumePlan? {
        let allPlans = plans(for: storyId)
        let match = allPlans.first(where: { $0.chapterRange.contains(chapterNumber) })
        #if DEBUG
        if match == nil && !allPlans.isEmpty && chapterNumber > 0 {
            assertionFailure(
                "Chapter \(chapterNumber) not covered by any volume in '\(storyId)'. "
                + "Update SoloVolumeCatalog to include this range."
            )
        }
        #endif
        return match
    }

    private static let tianjiluPlans: [SoloVolumePlan] = [
        .init(
            storyId: "天机录",
            index: 1,
            chapterRange: 1...120,
            title: "卷一 · 废材觉醒",
            teaser: "卷一整卷免费，先让用户完整吃到第一次命书觉醒与宗门打脸的爽点。",
            productID: nil,
            fallbackPriceText: "免费"
        ),
        .init(
            storyId: "天机录",
            index: 2,
            chapterRange: 121...240,
            title: "卷二 · 宗门暗战",
            teaser: "真正的暗战从这一卷开始，局不再只是赢一场冲突，而是开始试探谁在背后看你。",
            productID: "com.lifescript.solo.tianjilu.volume2",
            fallbackPriceText: "1元"
        ),
        .init(
            storyId: "天机录",
            index: 3,
            chapterRange: 241...360,
            title: "卷三 · 秘境争锋",
            teaser: "战场第一次被拉出宗门，资源、盟友和真相都开始变得稀缺。",
            productID: "com.lifescript.solo.tianjilu.volume3",
            fallbackPriceText: "1元"
        ),
        .init(
            storyId: "天机录",
            index: 4,
            chapterRange: 361...480,
            title: "卷四 · 魔道渗透",
            teaser: "从这一卷开始，敌我边界松动，夜清和魔道势力会把整盘棋再拧一次。",
            productID: "com.lifescript.solo.tianjilu.volume4",
            fallbackPriceText: "1元"
        ),
        .init(
            storyId: "天机录",
            index: 5,
            chapterRange: 481...600,
            title: "卷五 · 天命反噬",
            teaser: "付费卷可以稳稳卡在必死劫预言和假死逃脱前后，这是最自然的一次追更驱动。",
            productID: "com.lifescript.solo.tianjilu.volume5",
            fallbackPriceText: "1元"
        ),
        .init(
            storyId: "天机录",
            index: 6,
            chapterRange: 601...720,
            title: "卷六 · 大陆格局",
            teaser: "宗门局升格成天下局之后，玩家会更愿意为每一卷的阶段性升级买单。",
            productID: "com.lifescript.solo.tianjilu.volume6",
            fallbackPriceText: "1元"
        ),
        .init(
            storyId: "天机录",
            index: 7,
            chapterRange: 721...840,
            title: "卷七 · 上古真相",
            teaser: "这卷负责揭世界观的底，适合用“真相临门一脚”的方式驱动解锁。",
            productID: "com.lifescript.solo.tianjilu.volume7",
            fallbackPriceText: "1元"
        ),
        .init(
            storyId: "天机录",
            index: 8,
            chapterRange: 841...960,
            title: "卷八 · 魔道大战",
            teaser: "阵营级大战开始兑现前面积累，单卷购买的感知价值会更强。",
            productID: "com.lifescript.solo.tianjilu.volume8",
            fallbackPriceText: "1元"
        ),
        .init(
            storyId: "天机录",
            index: 9,
            chapterRange: 961...1080,
            title: "卷九 · 天道裂变",
            teaser: "从这里开始正式抬升到天道对局，付费理由会从“追更”变成“看终盘”。",
            productID: "com.lifescript.solo.tianjilu.volume9",
            fallbackPriceText: "1元"
        ),
        .init(
            storyId: "天机录",
            index: 10,
            chapterRange: 1081...1200,
            title: "卷十 · 棋局终局",
            teaser: "所有分支和因果都会在终卷汇合，终卷单独售卖可以最大化结局价值感。",
            productID: "com.lifescript.solo.tianjilu.volume10",
            fallbackPriceText: "1元"
        ),
    ]
}

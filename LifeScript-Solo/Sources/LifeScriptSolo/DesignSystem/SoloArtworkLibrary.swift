import SwiftUI
import UIKit

struct SoloArtworkAsset: Equatable, Sendable {
    let resourceName: String
    let title: String
    let subtitle: String
    let caption: String?
}

struct SoloBundledArtworkImage: View {
    let resourceName: String
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let image = SoloArtworkLibrary.image(named: resourceName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                LinearGradient(
                    colors: [
                        SoloTheme.surfaceRaised,
                        Color.black.opacity(0.92),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "photo")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SoloTheme.gold.opacity(0.42))
                )
            }
        }
    }
}

struct SoloArtworkCard: View {
    let asset: SoloArtworkAsset
    var height: CGFloat
    var contentMode: ContentMode = .fill
    var tint: Color = SoloTheme.gold
    var cornerRadius: CGFloat = 22

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SoloBundledArtworkImage(resourceName: asset.resourceName, contentMode: contentMode)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.06),
                            Color.black.opacity(0.22),
                            Color.black.opacity(0.86),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(asset.title)
                    .font(SoloTypography.meta)
                    .foregroundStyle(tint)
                Text(asset.subtitle)
                    .font(SoloTypography.sceneHeadline(size: 20))
                    .foregroundStyle(SoloTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let caption = asset.caption {
                    Text(caption)
                        .font(SoloTypography.detail)
                        .foregroundStyle(SoloTheme.warmInk)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

enum SoloArtworkLibrary {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(named resourceName: String) -> UIImage? {
        let key = resourceName as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        if let bundled = UIImage(named: resourceName) {
            cache.setObject(bundled, forKey: key)
            return bundled
        }

        guard let path = Bundle.main.path(forResource: resourceName, ofType: "png"),
              let image = UIImage(contentsOfFile: path) else {
            return nil
        }

        cache.setObject(image, forKey: key)
        return image
    }
}

struct TianjiluVolumeVisual: Equatable, Sendable {
    let index: Int
    let range: ClosedRange<Int>
    let volumeLabel: String
    let cover: SoloArtworkAsset
    let banner: SoloArtworkAsset
    let keyframe: SoloArtworkAsset
}

enum TianjiluArtworkCatalog {
    static let welcomeCover = SoloArtworkAsset(
        resourceName: "tianjilu_cover_vol1_awakening",
        title: "卷一 · 废材觉醒",
        subtitle: "命书初亮，棋局开场",
        caption: "第一次看见残页发光之前，陈机只是宗门里最不值得被注意的人。"
    )

    static let welcomeArtifact = SoloArtworkAsset(
        resourceName: "tianjilu_artifact_tianjilu",
        title: "天机录残页",
        subtitle: "改命的代价，从翻开它开始。",
        caption: nil
    )

    static let homeHeroMaster = SoloArtworkAsset(
        resourceName: "tianjilu_home_hero_master",
        title: "仙域绘卷",
        subtitle: "浮山、云海与命纹一起张开。",
        caption: "首页不再只是封面，而是《天机录》世界在你眼前缓缓显形的第一镜。"
    )

    static let entryHero = SoloArtworkAsset(
        resourceName: "tianjilu_cosmic_chessboard",
        title: "天机棋局",
        subtitle: "众生还没落子，因果已经先动。",
        caption: "《天机录》的视觉核心不是打斗，而是预见、布局与改命。"
    )

    static let routeBanner = SoloArtworkAsset(
        resourceName: "tianjilu_spiritual_sea",
        title: "识海观测",
        subtitle: "命途、人心与暗线都该被分层看清。",
        caption: "命途图不再只是文字列表，而是一张能回看整条因果链的战局面板。"
    )

    static let dossierBackdrop = SoloArtworkAsset(
        resourceName: "tianjilu_inner_sect_jade_hall",
        title: "天青宗内门",
        subtitle: "每个关键人物，都有自己的一面局。",
        caption: "人物页不只是关系值，而是带立绘、态度、局重和建议的完整角色面板。"
    )

    static let destinyArtifact = SoloArtworkAsset(
        resourceName: "tianjilu_artifact_tianjilu",
        title: "天机录残页",
        subtitle: "每一次动用，都在让命数重新对齐。",
        caption: nil
    )

    static let darklineArtifact = SoloArtworkAsset(
        resourceName: "tianjilu_artifact_destiny_chessboard",
        title: "天道棋盘",
        subtitle: "暗线不是彩蛋，而是仍在等待你触发的另一盘棋。",
        caption: nil
    )

    private static let portraits: [String: SoloArtworkAsset] = [
        "char_chenji": .init(
            resourceName: "tianjilu_chen_ji_portrait",
            title: "陈机",
            subtitle: "杂役灰袍下的第一层伪装",
            caption: "真正的威胁不在他看上去有多强，而在他总是比别人先知道一步。"
        ),
        "char_suqingyao": .init(
            resourceName: "tianjilu_su_qingyao_portrait",
            title: "苏青瑶",
            subtitle: "冷锋一样的首席剑修",
            caption: "信任、警惕与欣赏会同时出现在她的关系线上。"
        ),
        "char_yeqing": .init(
            resourceName: "tianjilu_ye_qing_portrait",
            title: "夜清",
            subtitle: "危险与好奇并存的魔道圣女",
            caption: "她既可能是最锋利的盟友，也可能是最昂贵的赌注。"
        ),
        "char_lingyuan": .init(
            resourceName: "tianjilu_ling_yuan_portrait",
            title: "凌渊",
            subtitle: "仁善外衣下的旧棋手",
            caption: "真正难读的不是他的表情，而是他到底把你放在棋盘哪一格。"
        ),
        "char_hanlie": .init(
            resourceName: "tianjilu_han_lie_portrait",
            title: "韩烈",
            subtitle: "玄武宗最锋利的明牌",
            caption: "他代表的不是阴谋，而是能够直接撞碎布局的暴烈正面。"
        ),
        "char_moxiansheng": .init(
            resourceName: "tianjilu_mo_xiansheng_portrait",
            title: "墨先生",
            subtitle: "残页里的旧时代见证者",
            caption: "当他愿意说真话时，往往意味着更大的代价已经靠近。"
        ),
        "char_chenian": .init(
            resourceName: "tianjilu_chen_nian_portrait",
            title: "陈念",
            subtitle: "陈机最柔软也最危险的命门",
            caption: "她不是背景设定，而是整条命途里最不能输掉的一枚核心子。"
        ),
        "char_tiandaozhiyan": .init(
            resourceName: "tianjilu_tiandao_eye",
            title: "天道之眼",
            subtitle: "抬头时，你看到的是世界正在回看你。",
            caption: "它让《天机录》的终局不只是一场争斗，而是与命运本身对局。"
        ),
    ]

    private static let volumes: [TianjiluVolumeVisual] = [
        .init(
            index: 1,
            range: 1...120,
            volumeLabel: "卷一 · 废材觉醒",
            cover: .init(resourceName: "tianjilu_cover_vol1_awakening", title: "卷一", subtitle: "废材觉醒", caption: "命数第一次回响，真正的陈机从这里开始出手。"),
            banner: .init(resourceName: "tianjilu_tianqing_sect_overview", title: "天青宗", subtitle: "局从宗门最底层开始长出来。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_tianjilu_activation", title: "关键帧", subtitle: "天机录初次激活", caption: "你第一次意识到，这不是一件法宝，而是一张会反噬使用者的命书。")
        ),
        .init(
            index: 2,
            range: 121...240,
            volumeLabel: "卷二 · 宗门暗战",
            cover: .init(resourceName: "tianjilu_cover_vol2_shadow_war", title: "卷二", subtitle: "宗门暗战", caption: "从外门到内门，明面秩序开始被暗线撬动。"),
            banner: .init(resourceName: "tianjilu_inner_sect_jade_hall", title: "内门深处", subtitle: "真正危险的，不是刀，而是知道你底牌的人。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_su_confrontation", title: "关键帧", subtitle: "苏青瑶逼近真相", caption: "关系线在这里不再只是好感，而开始牵扯立场和试探。")
        ),
        .init(
            index: 3,
            range: 241...360,
            volumeLabel: "卷三 · 秘境争锋",
            cover: .init(resourceName: "tianjilu_cover_vol3_secret_realm", title: "卷三", subtitle: "秘境争锋", caption: "局第一次被拉到宗门之外，真相与资源同时变得稀缺。"),
            banner: .init(resourceName: "tianjilu_ancient_secret_realm_entrance", title: "上古秘境", subtitle: "外部势力入局后，每一步都不再只影响一宗。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_reversal_moment", title: "关键帧", subtitle: "扮猪吃虎反转", caption: "真正的爽点来自提前铺好的后手终于被你亲手点燃。")
        ),
        .init(
            index: 4,
            range: 361...480,
            volumeLabel: "卷四 · 魔道渗透",
            cover: .init(resourceName: "tianjilu_cover_vol4_demon_infiltration", title: "卷四", subtitle: "魔道渗透", caption: "正魔边界开始失真，盟友与敌人的定义一起松动。"),
            banner: .init(resourceName: "tianjilu_demon_sect_base", title: "魔道圣宗", subtitle: "一切合作都带着代价，一切代价都在改写命途。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_ye_qing_rescue", title: "关键帧", subtitle: "夜清黑雾救援", caption: "当她出手时，危险和吸引往往会同时靠近。")
        ),
        .init(
            index: 5,
            range: 481...600,
            volumeLabel: "卷五 · 天命反噬",
            cover: .init(resourceName: "tianjilu_cover_vol5_fate_backlash", title: "卷五", subtitle: "天命反噬", caption: "越想快一步赢，命书就越会向你讨回代价。"),
            banner: .init(resourceName: "tianjilu_spiritual_sea", title: "识海深处", subtitle: "这时最可怕的敌人，可能是你自己。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_false_death_escape", title: "关键帧", subtitle: "假死逃脱", caption: "反转不只是逃出生天，更是主动把别人送进你安排的误判。")
        ),
        .init(
            index: 6,
            range: 601...720,
            volumeLabel: "卷六 · 大陆格局",
            cover: .init(resourceName: "tianjilu_cover_vol6_continental", title: "卷六", subtitle: "大陆格局", caption: "从宗门一局，正式走到天下一局。"),
            banner: .init(resourceName: "tianjilu_imperial_capital", title: "皇朝京城", subtitle: "棋盘被放大之后，谁都不再只是配角。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_grand_strategy", title: "关键帧", subtitle: "统筹各方势力", caption: "这是《天机录》最游戏化的一段，所有之前积累的关系与判断都开始兑现。")
        ),
        .init(
            index: 7,
            range: 721...840,
            volumeLabel: "卷七 · 上古真相",
            cover: .init(resourceName: "tianjilu_cover_vol7_ancient_truth", title: "卷七", subtitle: "上古真相", caption: "你终于开始接近命书本身为什么会存在。"),
            banner: .init(resourceName: "tianjilu_chenxuan_relic_interior", title: "陈玄遗迹", subtitle: "旧时代留下来的，从来不只有答案。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_mo_emergence", title: "关键帧", subtitle: "墨先生浮现", caption: "当旧时代真正说话时，世界观也会跟着一起翻面。")
        ),
        .init(
            index: 8,
            range: 841...960,
            volumeLabel: "卷八 · 魔道大战",
            cover: .init(resourceName: "tianjilu_cover_vol8_demon_war", title: "卷八", subtitle: "魔道大战", caption: "局面全面失控时，你的每个决定都开始影响阵营级后果。"),
            banner: .init(resourceName: "tianjilu_three_sect_battle", title: "三宗激战", subtitle: "到了这一卷，任何一步迟疑都会被放大。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_ling_yuan_reveal", title: "关键帧", subtitle: "凌渊面具破碎", caption: "真正震荡玩家的，不是揭晓，而是你终于看懂他一直在算什么。")
        ),
        .init(
            index: 9,
            range: 961...1080,
            volumeLabel: "卷九 · 天道裂变",
            cover: .init(resourceName: "tianjilu_cover_vol9_heaven_fracture", title: "卷九", subtitle: "天道裂变", caption: "《天机录》的终盘不只是对人，而是对天道本身。"),
            banner: .init(resourceName: "tianjilu_cosmic_chessboard", title: "天道棋盘", subtitle: "你看见的不是未来，而是未来如何试图吞掉你。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_fate_confrontation", title: "关键帧", subtitle: "陈机对抗天道之眼", caption: "抬头那一刻，故事正式从权谋修仙跃迁到命运战争。")
        ),
        .init(
            index: 10,
            range: 1081...1200,
            volumeLabel: "卷十 · 棋局终局",
            cover: .init(resourceName: "tianjilu_cover_vol10_endgame", title: "卷十", subtitle: "棋局终局", caption: "一切分支、好感、暗线与命数压力都会在这里汇合。"),
            banner: .init(resourceName: "tianjilu_cosmic_chessboard", title: "终局前夜", subtitle: "你终于走到那枚最后的未落之子面前。", caption: nil),
            keyframe: .init(resourceName: "tianjilu_key_ending_beyond_fate", title: "关键帧", subtitle: "踏出预言之外", caption: "最好的结局感，不是赢，而是你真的把自己从既定命运里拿了出来。")
        ),
    ]

    static func portrait(for character: Character) -> SoloArtworkAsset? {
        portraits[character.id]
    }

    static func portrait(for characterId: String) -> SoloArtworkAsset? {
        portraits[characterId]
    }

    static func volume(for chapterNumber: Int) -> TianjiluVolumeVisual {
        volumes.first(where: { $0.range.contains(chapterNumber) }) ?? volumes[0]
    }

    static func volume(stageIndex: Int, stageCount: Int) -> TianjiluVolumeVisual {
        guard stageCount > 0 else { return volumes[0] }
        let normalized = Double(stageIndex) / Double(max(stageCount - 1, 1))
        let mappedIndex = min(
            max(Int(round(normalized * Double(volumes.count - 1))), 0),
            volumes.count - 1
        )
        return volumes[mappedIndex]
    }
}

import Foundation
@testable import LifeScript

enum TestFixtures {
    static func makeBook(
        id: String = "test_book",
        title: String = "测试书籍",
        totalChapters: Int = 3
    ) -> Book {
        Book(
            id: id,
            title: title,
            author: "测试作者",
            coverImageName: "test_cover",
            synopsis: "测试简介",
            genre: .urbanReversal,
            tags: ["测试标签"],
            interactionTags: ["高互动"],
            totalChapters: totalChapters,
            freeChapters: 2,
            characters: [makeCharacter()],
            initialStats: .initial
        )
    }

    static func makeCharacter(
        id: String = "test_char",
        name: String = "测试角色",
        role: Character.CharacterRole = .neutral
    ) -> Character {
        Character(
            id: id,
            name: name,
            title: "测试身份",
            avatarImageName: "test_avatar",
            description: "测试描述",
            role: role
        )
    }

    static func makeChapter(
        id: String = "test_chapter",
        bookId: String = "test_book",
        number: Int = 1,
        nodes: [StoryNode] = []
    ) -> Chapter {
        Chapter(
            id: id,
            bookId: bookId,
            number: number,
            title: "测试章节\(number)",
            nodes: nodes,
            isPaid: false,
            nextChapterHook: "下一章预告"
        )
    }

    static func makeChoice(
        id: String = "test_choice",
        statEffects: [StatEffect] = [],
        relationshipEffects: [RelationshipEffect] = [],
        resultNodes: [StoryNode]? = nil
    ) -> Choice {
        Choice(
            id: id,
            text: "测试选项",
            description: "测试描述",
            satisfactionType: .immediatePower,
            statEffects: statEffects,
            relationshipEffects: relationshipEffects,
            resultNodeIds: [],
            resultNodes: resultNodes
        )
    }

    static func makeWalkthrough(
        bookId: String = "test_book",
        chapterId: String = "test_chapter",
        stageId: String = "stage_1",
        stageTitle: String = "第一幕"
    ) -> BookWalkthrough {
        BookWalkthrough(
            bookId: bookId,
            title: "测试攻略图",
            stages: [
                WalkthroughStage(
                    id: stageId,
                    title: stageTitle,
                    summary: "主线从这里开启",
                    chapterIds: [chapterId]
                )
            ],
            chapterGuides: [
                WalkthroughChapterGuide(
                    chapterId: chapterId,
                    stageId: stageId,
                    publicSummary: "这一章会建立主线冲突并打开第一条分线。",
                    objective: "拿到主动权",
                    estimatedMinutes: 4,
                    interactionCount: 2,
                    visibleRoutes: [
                        WalkthroughRoute(
                            id: "route_1",
                            title: "正面硬压",
                            style: "直接爽",
                            unlockHint: "高战力倾向",
                            payoff: "快速建立压制感",
                            processFocus: "正面对抗"
                        ),
                        WalkthroughRoute(
                            id: "route_2",
                            title: "暗手布局",
                            style: "延迟爽",
                            unlockHint: "高谋略倾向",
                            payoff: "埋下后续反杀点",
                            processFocus: "信息与人心"
                        )
                    ],
                    hiddenRouteHint: "暗线和旧案有关"
                )
            ]
        )
    }
}

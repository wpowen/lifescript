import Foundation
@testable import LifeScriptSolo

enum TestFixtures {
    static func makeBook(id: String = SoloStoryConfig.storyId) -> Book {
        Book(
            id: id,
            title: "残剑问仙",
            author: "命书工作室",
            coverImageName: "cover",
            synopsis: "测试简介",
            genre: .cultivation,
            tags: ["测试"],
            interactionTags: ["高互动"],
            totalChapters: 3,
            freeChapters: 3,
            characters: [
                Character(
                    id: "char_1",
                    name: "秦霜",
                    title: "执剑师姐",
                    avatarImageName: "avatar",
                    description: "角色描述",
                    role: .loveInterest
                )
            ],
            initialStats: .initial
        )
    }

    static func makeChapter(
        id: String,
        number: Int,
        nodes: [StoryNode] = [.text(TextNode(id: "default_node", content: "正文"))]
    ) -> Chapter {
        Chapter(
            id: id,
            bookId: SoloStoryConfig.storyId,
            number: number,
            title: "第\(number)章",
            nodes: nodes,
            isPaid: false,
            nextChapterHook: "下一章钩子"
        )
    }

    static func makeWalkthrough() -> BookWalkthrough {
        BookWalkthrough(
            bookId: SoloStoryConfig.storyId,
            title: "路线图",
            stages: [
                WalkthroughStage(
                    id: "stage_1",
                    title: "开局试剑",
                    summary: "建立主问题",
                    chapterIds: ["chapter_1", "chapter_2"]
                )
            ],
            chapterGuides: [
                WalkthroughChapterGuide(
                    chapterId: "chapter_1",
                    stageId: "stage_1",
                    publicSummary: "公开建立冲突",
                    objective: "拿到主动权",
                    estimatedMinutes: 4,
                    interactionCount: 2,
                    visibleRoutes: [
                        WalkthroughRoute(
                            id: "route_1",
                            title: "正面硬压",
                            style: "直接爽",
                            unlockHint: "优先堆战力",
                            payoff: "快速立威",
                            processFocus: "正面对抗"
                        )
                    ],
                    hiddenRouteHint: "旧案有关"
                )
            ]
        )
    }
}

import XCTest
@testable import LifeScriptSolo

@MainActor
final class SoloStoryStoreTests: XCTestCase {
    func test_reload_populatesBookChaptersAndWalkthrough() async {
        let loader = MockContentLoader()
        loader.stubbedBook = TestFixtures.makeBook()
        loader.stubbedChapters = [
            TestFixtures.makeChapter(id: "chapter_2", number: 2),
            TestFixtures.makeChapter(id: "chapter_1", number: 1),
        ]
        loader.stubbedWalkthrough = TestFixtures.makeWalkthrough()

        let sut = SoloStoryStore(contentLoader: loader)

        await sut.reload()

        XCTAssertEqual(sut.book?.id, SoloStoryConfig.storyId)
        XCTAssertEqual(sut.chapters.map(\.id), ["chapter_1", "chapter_2"])
        XCTAssertEqual(sut.walkthrough?.bookId, SoloStoryConfig.storyId)
        XCTAssertEqual(sut.state, .ready)
    }

    func test_progressSummary_usesReadingProgressWhenAvailable() async {
        let loader = MockContentLoader()
        loader.stubbedBook = TestFixtures.makeBook()
        loader.stubbedChapters = [
            TestFixtures.makeChapter(id: "chapter_1", number: 1),
            TestFixtures.makeChapter(id: "chapter_2", number: 2),
        ]

        let sut = SoloStoryStore(contentLoader: loader)
        await sut.reload()

        let progress = ReadingProgress(bookId: SoloStoryConfig.storyId, currentChapterId: "chapter_2")
        progress.completedChapterIds = ["chapter_1"]

        let summary = sut.progressSummary(progress: progress)

        XCTAssertEqual(summary.currentChapterNumber, 2)
        XCTAssertEqual(summary.completedChapterCount, 1)
        XCTAssertEqual(summary.totalChapterCount, 2)
        XCTAssertEqual(sut.resumeChapterId(progress: progress), "chapter_2")
    }

    func test_entrySnapshot_tracksCurrentGuideAndRecapFromProgress() async {
        let loader = MockContentLoader()
        loader.stubbedBook = TestFixtures.makeBook()
        loader.stubbedChapters = [
            TestFixtures.makeChapter(id: "chapter_1", number: 1),
            TestFixtures.makeChapter(id: "chapter_2", number: 2),
            TestFixtures.makeChapter(id: "chapter_3", number: 3),
        ]
        loader.stubbedWalkthrough = BookWalkthrough(
            bookId: SoloStoryConfig.storyId,
            title: "路线图",
            stages: [
                WalkthroughStage(
                    id: "stage_1",
                    title: "锋芒初露",
                    summary: "你必须在众目睽睽下抢回主动。",
                    chapterIds: ["chapter_1"]
                ),
                WalkthroughStage(
                    id: "stage_2",
                    title: "暗潮试探",
                    summary: "局势表面平静，实则人人都在试探你的底牌。",
                    chapterIds: ["chapter_2", "chapter_3"]
                ),
            ],
            chapterGuides: [
                WalkthroughChapterGuide(
                    chapterId: "chapter_1",
                    stageId: "stage_1",
                    publicSummary: "你在众人面前第一次亮剑，强行改写了局势。",
                    objective: "抢下开场势能",
                    estimatedMinutes: 4,
                    interactionCount: 2,
                    visibleRoutes: [],
                    hiddenRouteHint: nil
                ),
                WalkthroughChapterGuide(
                    chapterId: "chapter_2",
                    stageId: "stage_2",
                    publicSummary: "风平浪静只是表象，真正危险的是没人说出口的那部分。",
                    objective: "守住你刚抢来的优势",
                    estimatedMinutes: 5,
                    interactionCount: 3,
                    visibleRoutes: [],
                    hiddenRouteHint: "有人在暗中盯你"
                ),
            ]
        )

        let sut = SoloStoryStore(contentLoader: loader)
        await sut.reload()

        let progress = ReadingProgress(bookId: SoloStoryConfig.storyId, currentChapterId: "chapter_2")
        progress.completedChapterIds = ["chapter_1"]

        let snapshot = sut.entrySnapshot(progress: progress)

        XCTAssertEqual(snapshot.progress.currentChapterNumber, 2)
        XCTAssertEqual(snapshot.currentStageTitle, "暗潮试探")
        XCTAssertEqual(snapshot.currentObjective, "守住你刚抢来的优势")
        XCTAssertEqual(snapshot.recapSummary, "你在众人面前第一次亮剑，强行改写了局势。")
        XCTAssertEqual(snapshot.hiddenRouteHint, "有人在暗中盯你")
        XCTAssertEqual(snapshot.currentIdentityValue, "第 2 章 · 暗潮试探")
        XCTAssertEqual(snapshot.destinyStatusLine, "守住你刚抢来的优势")
        XCTAssertEqual(snapshot.hookLine, "下一章钩子")
        XCTAssertEqual(snapshot.experienceStats.map(\.title), ["章节规模", "公开分路", "关键人物", "交互密度"])
        XCTAssertEqual(snapshot.experienceStats.map(\.valueText), ["3 章", "0 条", "1 人", "5 次"])
    }

    func test_routeMapSnapshot_tracksCurrentStageAndCompletedChapters() async {
        let loader = MockContentLoader()
        loader.stubbedBook = TestFixtures.makeBook()
        loader.stubbedChapters = [
            TestFixtures.makeChapter(id: "chapter_1", number: 1),
            TestFixtures.makeChapter(id: "chapter_2", number: 2),
            TestFixtures.makeChapter(id: "chapter_3", number: 3),
        ]
        loader.stubbedWalkthrough = BookWalkthrough(
            bookId: SoloStoryConfig.storyId,
            title: "路线图",
            stages: [
                WalkthroughStage(
                    id: "stage_1",
                    title: "锋芒初露",
                    summary: "第一阶段",
                    chapterIds: ["chapter_1"]
                ),
                WalkthroughStage(
                    id: "stage_2",
                    title: "暗潮试探",
                    summary: "第二阶段",
                    chapterIds: ["chapter_2", "chapter_3"]
                ),
            ],
            chapterGuides: [
                WalkthroughChapterGuide(
                    chapterId: "chapter_1",
                    stageId: "stage_1",
                    publicSummary: "阶段一",
                    objective: "开局",
                    estimatedMinutes: 4,
                    interactionCount: 2,
                    visibleRoutes: [],
                    hiddenRouteHint: nil
                ),
                WalkthroughChapterGuide(
                    chapterId: "chapter_2",
                    stageId: "stage_2",
                    publicSummary: "阶段二",
                    objective: "推进",
                    estimatedMinutes: 5,
                    interactionCount: 2,
                    visibleRoutes: [],
                    hiddenRouteHint: nil
                ),
            ]
        )

        let sut = SoloStoryStore(contentLoader: loader)
        await sut.reload()

        let progress = ReadingProgress(bookId: SoloStoryConfig.storyId, currentChapterId: "chapter_2")
        progress.completedChapterIds = ["chapter_1"]

        let snapshot = sut.routeMapSnapshot(progress: progress)

        XCTAssertEqual(snapshot.currentChapterID, "chapter_2")
        XCTAssertEqual(snapshot.currentStageID, "stage_2")
        XCTAssertEqual(snapshot.completedChapterIDs, ["chapter_1"])
    }

    func test_dossierSnapshot_buildsGenreAwareModulesAndRelationshipSpotlight() async {
        let loader = MockContentLoader()
        loader.stubbedBook = TestFixtures.makeBook()

        let sut = SoloStoryStore(contentLoader: loader)
        let relationships = [
            RelationshipState(
                characterId: "char_1",
                trust: 78,
                affection: 42,
                hostility: 8,
                awe: 55,
                dependence: 12,
                lastChangeReason: "曾在夜雨中替你压下一场祸事",
                unlockedEvents: []
            )
        ]

        let snapshot = sut.dossierSnapshot(
            book: TestFixtures.makeBook(),
            stats: ProtagonistStats(combat: 62, fame: 48, strategy: 73, wealth: 31, charm: 40, darkness: 18, destiny: 67),
            relationships: relationships
        )

        XCTAssertEqual(snapshot.statCards.map(\.title), ["剑势", "声名", "机锋", "灵资", "气度", "心魇", "天命"])
        XCTAssertEqual(snapshot.moduleCards.count, 3)
        XCTAssertEqual(snapshot.moduleCards.map(\.title), ["境界势能", "人脉因果", "名望与筹码"])
        XCTAssertEqual(snapshot.relationshipSpotlight?.characterName, "秦霜")
        XCTAssertEqual(snapshot.relationshipSpotlight?.attitudeLabel, "信任")
    }

    func test_dossierSnapshot_buildsApocalypseModulesForApocalypseGenre() {
        let sut = SoloStoryStore(contentLoader: MockContentLoader())
        let book = Book(
            id: "apocalypse_001",
            title: "灰烬执政官",
            author: "命书工作室",
            coverImageName: "cover_apocalypse_001",
            synopsis: "测试简介",
            genre: .apocalypsePower,
            tags: ["末日"],
            interactionTags: ["高压选择"],
            totalChapters: 6,
            freeChapters: 3,
            characters: [
                Character(
                    id: "char_1",
                    name: "沈砚",
                    title: "野战医生",
                    avatarImageName: "avatar",
                    description: "角色描述",
                    role: .ally
                )
            ],
            initialStats: .initial
        )
        let relationships = [
            RelationshipState(
                characterId: "char_1",
                trust: 64,
                affection: 28,
                hostility: 14,
                awe: 48,
                dependence: 31,
                lastChangeReason: "你在停电夜里把最后一支镇静剂给了他。",
                unlockedEvents: []
            )
        ]

        let snapshot = sut.dossierSnapshot(
            book: book,
            stats: ProtagonistStats(combat: 58, fame: 41, strategy: 76, wealth: 35, charm: 46, darkness: 54, destiny: 72),
            relationships: relationships
        )

        XCTAssertEqual(snapshot.statCards.map(\.title), ["战备", "声噪", "决断", "补给", "凝聚", "异化", "火种"])
        XCTAssertEqual(snapshot.moduleCards.map(\.title), ["避难区承压", "队伍信号", "生存筹码"])
        XCTAssertEqual(snapshot.relationshipSpotlight?.characterName, "沈砚")
        XCTAssertEqual(snapshot.relationshipSpotlight?.attitudeLabel, "关注")
    }

    func test_progressSummary_andRouteSnapshot_treatFinishedNodeIndexAsCompletedChapter() async {
        let loader = MockContentLoader()
        loader.stubbedBook = TestFixtures.makeBook()
        loader.stubbedChapters = [
            TestFixtures.makeChapter(
                id: "chapter_1",
                number: 1,
                nodes: [
                    .text(TextNode(id: "chapter_1_node_1", content: "第一章", emphasis: .normal))
                ]
            ),
            TestFixtures.makeChapter(
                id: "chapter_2",
                number: 2,
                nodes: [
                    .text(TextNode(id: "chapter_2_node_1", content: "第二章", emphasis: .normal))
                ]
            ),
        ]

        let sut = SoloStoryStore(contentLoader: loader)
        await sut.reload()

        let progress = ReadingProgress(bookId: SoloStoryConfig.storyId, currentChapterId: "chapter_1", currentNodeIndex: 1)
        progress.completedChapterIds = []

        let summary = sut.progressSummary(progress: progress)
        let routeSnapshot = sut.routeMapSnapshot(progress: progress)

        XCTAssertEqual(summary.completedChapterCount, 1)
        XCTAssertTrue(routeSnapshot.completedChapterIDs.contains("chapter_1"))
    }
}

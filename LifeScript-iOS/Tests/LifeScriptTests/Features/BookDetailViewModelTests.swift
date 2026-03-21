import XCTest
@testable import LifeScript

@MainActor
final class BookDetailViewModelTests: XCTestCase {
    func test_onAppear_loadsWalkthroughMetadataIntoChapterSnapshots() async {
        let book = TestFixtures.makeBook()
        let loader = MockContentLoader()
        let chapter = TestFixtures.makeChapter(id: "chapter_1", bookId: book.id, number: 1)
        loader.stubbedChapters[book.id] = [chapter]
        loader.stubbedWalkthroughs[book.id] = TestFixtures.makeWalkthrough(
            bookId: book.id,
            chapterId: chapter.id,
            stageTitle: "断脉开锋"
        )

        let sut = BookDetailViewModel(book: book, contentLoader: loader)

        await sut.onAppear()
        let snapshots = sut.chapterSnapshots(progress: nil)

        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.stage?.title, "断脉开锋")
        XCTAssertEqual(snapshots.first?.guide?.objective, "拿到主动权")
        XCTAssertEqual(snapshots.first?.guide?.visibleRoutes.count, 2)
    }

    func test_publicRouteCount_sumsVisibleRoutesAcrossGuides() async {
        let book = TestFixtures.makeBook(totalChapters: 2)
        let loader = MockContentLoader()

        let firstChapter = TestFixtures.makeChapter(id: "chapter_1", bookId: book.id, number: 1)
        let secondChapter = TestFixtures.makeChapter(id: "chapter_2", bookId: book.id, number: 2)
        loader.stubbedChapters[book.id] = [firstChapter, secondChapter]

        loader.stubbedWalkthroughs[book.id] = BookWalkthrough(
            bookId: book.id,
            title: "测试攻略图",
            stages: [
                WalkthroughStage(
                    id: "stage_1",
                    title: "起局",
                    summary: "建立冲突",
                    chapterIds: [firstChapter.id, secondChapter.id]
                )
            ],
            chapterGuides: [
                WalkthroughChapterGuide(
                    chapterId: firstChapter.id,
                    stageId: "stage_1",
                    publicSummary: "第一章摘要",
                    objective: "抢到第一手主动权",
                    estimatedMinutes: 4,
                    interactionCount: 2,
                    visibleRoutes: [
                        WalkthroughRoute(id: "r_1", title: "强打", style: "直接爽", unlockHint: "战力", payoff: "抢气势", processFocus: "战斗"),
                        WalkthroughRoute(id: "r_2", title: "钓鱼", style: "阴谋爽", unlockHint: "谋略", payoff: "埋暗线", processFocus: "布局")
                    ],
                    hiddenRouteHint: nil
                ),
                WalkthroughChapterGuide(
                    chapterId: secondChapter.id,
                    stageId: "stage_1",
                    publicSummary: "第二章摘要",
                    objective: "打开真相缺口",
                    estimatedMinutes: 5,
                    interactionCount: 3,
                    visibleRoutes: [
                        WalkthroughRoute(id: "r_3", title: "追问", style: "延迟爽", unlockHint: "关系", payoff: "解锁人心线", processFocus: "关系"),
                        WalkthroughRoute(id: "r_4", title: "压证", style: "扮猪吃虎", unlockHint: "隐藏", payoff: "保留筹码", processFocus: "证据"),
                        WalkthroughRoute(id: "r_5", title: "亮牌", style: "碾压爽", unlockHint: "名望", payoff: "快速震场", processFocus: "公开对抗")
                    ],
                    hiddenRouteHint: "第三章会收这条暗线"
                )
            ]
        )

        let sut = BookDetailViewModel(book: book, contentLoader: loader)

        await sut.onAppear()

        XCTAssertEqual(sut.publicRouteCount, 5)
    }
}

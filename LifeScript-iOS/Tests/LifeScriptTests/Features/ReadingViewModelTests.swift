import XCTest
@testable import LifeScript

@MainActor
final class ReadingViewModelTests: XCTestCase {
    func test_proceedToNextChapter_advancesToSortedNextChapter() async {
        let book = TestFixtures.makeBook()
        let loader = MockContentLoader()

        let chapterOne = TestFixtures.makeChapter(
            id: "chapter_1",
            number: 1,
            nodes: [
                .text(TextNode(id: "chapter_1_opening", content: "第一章开场"))
            ]
        )
        let chapterTwo = TestFixtures.makeChapter(
            id: "chapter_2",
            number: 2,
            nodes: [
                .text(TextNode(id: "chapter_2_opening", content: "第二章开场"))
            ]
        )

        // Intentionally unsorted to verify the view model resolves chronology itself.
        loader.stubbedChapters[book.id] = [chapterTwo, chapterOne]

        let sut = ReadingViewModel(
            book: book,
            chapterId: chapterOne.id,
            contentLoader: loader
        )

        await sut.loadChapter(id: chapterOne.id)
        XCTAssertTrue(sut.hasNextChapter)

        await sut.proceedToNextChapter()

        XCTAssertEqual(sut.currentChapter?.id, chapterTwo.id)
        XCTAssertEqual(sut.currentChapter?.number, 2)
        XCTAssertEqual(sut.displayedNodes.map(\.id), ["chapter_2_opening"])
        XCTAssertFalse(sut.hasNextChapter)
    }

    func test_selectChoice_appendsInlineResultNodesBeforeNotifications() async {
        let book = TestFixtures.makeBook()
        let loader = MockContentLoader()

        let resultNodes: [StoryNode] = [
            .text(TextNode(
                id: "result_text_1",
                content: "你侧身让开第一拳，借着擂台边缘的反震把力道卸进地砖，裂纹一路蔓到对手脚下。"
            )),
            .dialogue(DialogueNode(
                id: "result_dialogue_1",
                characterId: book.characters[0].id,
                content: "原来你一直在藏锋？",
                emotion: "震惊"
            )),
        ]

        let choice = TestFixtures.makeChoice(
            statEffects: [StatEffect(stat: .combat, delta: 5)],
            resultNodes: resultNodes
        )

        let choiceNode = ChoiceNode(
            id: "choice_1",
            prompt: "你决定怎么出手？",
            choices: [choice],
            choiceType: .keyDecision
        )

        let chapter = TestFixtures.makeChapter(
            nodes: [.choice(choiceNode)]
        )

        loader.stubbedChapters[book.id] = [chapter]

        let sut = ReadingViewModel(
            book: book,
            chapterId: chapter.id,
            contentLoader: loader
        )

        await sut.loadChapter(id: chapter.id)

        if case .choosing = sut.state {
            // expected
        } else {
            XCTFail("Expected choosing state before selection")
        }

        sut.selectChoice(choice, in: choiceNode)

        XCTAssertEqual(
            sut.displayedNodes.map(\.id),
            [
                "choice_1",
                "result_text_1",
                "result_dialogue_1",
                "stat_\(choice.id)_战力",
            ]
        )
        XCTAssertEqual(sut.stats.combat, book.initialStats.combat + 5)
    }

    func test_loadChapter_populatesCurrentChapterGuideFromWalkthrough() async {
        let book = TestFixtures.makeBook()
        let loader = MockContentLoader()

        let chapter = TestFixtures.makeChapter(
            id: "chapter_1",
            bookId: book.id,
            number: 1,
            nodes: [.text(TextNode(id: "chapter_1_opening", content: "第一章开场"))]
        )

        loader.stubbedChapters[book.id] = [chapter]
        loader.stubbedWalkthroughs[book.id] = TestFixtures.makeWalkthrough(
            bookId: book.id,
            chapterId: chapter.id,
            stageTitle: "剑冢夜行"
        )

        let sut = ReadingViewModel(
            book: book,
            chapterId: chapter.id,
            contentLoader: loader
        )

        await sut.loadChapter(id: chapter.id)

        XCTAssertEqual(sut.chapterGuide?.chapterId, chapter.id)
        XCTAssertEqual(sut.chapterGuide?.objective, "拿到主动权")
        XCTAssertEqual(sut.chapterStage?.title, "剑冢夜行")
    }
}

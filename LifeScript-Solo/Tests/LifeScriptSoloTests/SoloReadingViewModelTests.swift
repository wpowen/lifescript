import SwiftData
import XCTest
@testable import LifeScriptSolo

@MainActor
final class SoloReadingViewModelTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: StoryContentVersioning.versionDefaultsKey(for: "book_content_reset"))
    }

    func test_onAppear_restoresPendingChoiceAsChoosingState() async throws {
        let book = TestFixtures.makeBook()
        let loader = MockContentLoader()
        let choice = try makeChoice(id: "choice_pending", text: "抢先一步")
        let choiceNode = ChoiceNode(
            id: "choice_node_pending",
            prompt: "此刻该如何落子？",
            choices: [choice],
            timeLimit: nil,
            choiceType: .keyDecision
        )

        let chapter = Chapter(
            id: "chapter_pending_choice",
            bookId: book.id,
            number: 1,
            title: "待选抉择",
            nodes: [
                .text(TextNode(id: "node_1", content: "山门风起", emphasis: .normal)),
                .choice(choiceNode),
                .text(TextNode(id: "node_2", content: "后续正文", emphasis: .normal)),
            ],
            isPaid: false,
            nextChapterHook: "下一章钩子"
        )

        loader.stubbedBook = book
        loader.stubbedChapters = [chapter]

        let container = try ModelContainer(
            for: ReadingProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let progress = ReadingProgress(bookId: book.id, currentChapterId: chapter.id, currentNodeIndex: 2)
        context.insert(progress)
        try context.save()

        let sut = ReadingViewModel(
            book: book,
            chapterId: chapter.id,
            contentLoader: loader
        )

        await sut.onAppear(modelContext: context)

        XCTAssertEqual(sut.currentNodeIndex, 2)
        XCTAssertEqual(sut.displayedNodes.map(\.id), ["node_1", "choice_node_pending"])
        XCTAssertTrue(sut.selectedChoiceIds.isEmpty)
        guard case .choosing(let restoredChoiceNode) = sut.state else {
            return XCTFail("Expected choosing state after restoring a pending choice")
        }
        XCTAssertEqual(restoredChoiceNode.id, "choice_node_pending")
    }

    func test_onAppear_restoresSelectedChoiceIdsFromSavedChoiceRecords() async throws {
        let book = TestFixtures.makeBook()
        let loader = MockContentLoader()
        let choice = try makeChoice(id: "choice_saved", text: "先藏锋")
        let choiceNode = ChoiceNode(
            id: "choice_node_saved",
            prompt: "你决定先稳住局面。",
            choices: [choice],
            timeLimit: nil,
            choiceType: .styleChoice
        )

        let chapter = Chapter(
            id: "chapter_saved_choice",
            bookId: book.id,
            number: 1,
            title: "已选抉择",
            nodes: [
                .choice(choiceNode),
                .text(TextNode(id: "node_after_choice", content: "暗线继续推进", emphasis: .normal)),
            ],
            isPaid: false,
            nextChapterHook: "下一章钩子"
        )

        loader.stubbedBook = book
        loader.stubbedChapters = [chapter]

        let container = try ModelContainer(
            for: ReadingProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let progress = ReadingProgress(bookId: book.id, currentChapterId: chapter.id, currentNodeIndex: 1)
        progress.choiceRecords = [
            UserChoiceRecord(
                chapterId: chapter.id,
                choiceNodeId: choiceNode.id,
                selectedChoiceId: choice.id,
                timestamp: Date()
            )
        ]
        context.insert(progress)
        try context.save()

        let sut = ReadingViewModel(
            book: book,
            chapterId: chapter.id,
            contentLoader: loader
        )

        await sut.onAppear(modelContext: context)

        XCTAssertEqual(sut.selectedChoiceIds[choiceNode.id], choice.id)
        if case .reading = sut.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected reading state after restoring a completed choice")
        }
    }

    func test_onAppear_restoresSavedNodeIndexWithinCurrentChapter() async throws {
        let book = TestFixtures.makeBook()
        let loader = MockContentLoader()

        let chapter = Chapter(
            id: "chapter_resume",
            bookId: book.id,
            number: 1,
            title: "可恢复章节",
            nodes: [
                .text(TextNode(id: "node_1", content: "第一段", emphasis: .normal)),
                .text(TextNode(id: "node_2", content: "第二段", emphasis: .dramatic)),
                .text(TextNode(id: "node_3", content: "第三段", emphasis: .normal)),
                .text(TextNode(id: "node_4", content: "第四段", emphasis: .dramatic)),
                .text(TextNode(id: "node_5", content: "第五段", emphasis: .normal)),
            ],
            isPaid: false,
            nextChapterHook: "下一章钩子"
        )

        loader.stubbedBook = book
        loader.stubbedChapters = [chapter]

        let container = try ModelContainer(
            for: ReadingProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let progress = ReadingProgress(bookId: book.id, currentChapterId: chapter.id, currentNodeIndex: 4)
        context.insert(progress)
        try context.save()

        let sut = ReadingViewModel(
            book: book,
            chapterId: chapter.id,
            contentLoader: loader
        )

        await sut.onAppear(modelContext: context)

        XCTAssertEqual(sut.currentNodeIndex, 4)
        XCTAssertEqual(sut.displayedNodes.map(\.id), ["node_1", "node_2", "node_3", "node_4"])
        if case .reading = sut.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected reading state after restoring an in-progress chapter")
        }
    }

    func test_onAppear_discardsOldProgressWhenContentVersionChanges() async throws {
        let book = TestFixtures.makeBook(id: "book_content_reset")
        let loader = MockContentLoader()
        loader.stubbedBook = book
        loader.stubbedContentVersion = "content-v2"

        let choice = try makeChoice(id: "choice_after_refresh", text: "重新落子")
        let chapter = Chapter(
            id: "chapter_content_reset",
            bookId: book.id,
            number: 1,
            title: "内容更新后的章节",
            nodes: [
                .text(TextNode(id: "node_intro", content: "新的正文开场", emphasis: .normal)),
                .choice(
                    ChoiceNode(
                        id: "choice_node_refresh",
                        prompt: "更新后第一次抉择",
                        choices: [choice],
                        timeLimit: nil,
                        choiceType: .keyDecision
                    )
                ),
            ],
            isPaid: false,
            nextChapterHook: "下一章钩子"
        )
        loader.stubbedChapters = [chapter]

        let defaults = UserDefaults.standard
        defaults.set("content-v1", forKey: StoryContentVersioning.versionDefaultsKey(for: book.id))

        let container = try ModelContainer(
            for: ReadingProgress.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let progress = ReadingProgress(bookId: book.id, currentChapterId: chapter.id, currentNodeIndex: 2)
        progress.choiceRecords = [
            UserChoiceRecord(
                chapterId: chapter.id,
                choiceNodeId: "choice_node_refresh",
                selectedChoiceId: choice.id,
                timestamp: Date()
            )
        ]
        context.insert(progress)
        try context.save()

        let sut = ReadingViewModel(
            book: book,
            chapterId: chapter.id,
            contentLoader: loader
        )

        await sut.onAppear(modelContext: context)

        XCTAssertEqual(sut.displayedNodes.map(\.id), ["node_intro", "choice_node_refresh"])
        XCTAssertTrue(sut.selectedChoiceIds.isEmpty)
        guard case .choosing(let restoredChoiceNode) = sut.state else {
            return XCTFail("Expected fresh choosing state after discarding stale content progress")
        }
        XCTAssertEqual(restoredChoiceNode.id, "choice_node_refresh")

        let descriptor = FetchDescriptor<ReadingProgress>(
            predicate: #Predicate { $0.bookId == book.id }
        )
        let storedProgress = try XCTUnwrap(context.fetch(descriptor).first)
        XCTAssertEqual(storedProgress.currentNodeIndex, 2)
        XCTAssertEqual(storedProgress.choiceRecords?.count ?? 0, 0)
        XCTAssertEqual(
            defaults.string(forKey: StoryContentVersioning.versionDefaultsKey(for: book.id)),
            "content-v2"
        )
    }

    private func makeChoice(id: String, text: String) throws -> Choice {
        let payload = """
        {
          "id": "\(id)",
          "text": "\(text)",
          "description": "测试抉择",
          "memoryLabel": "测试抉择",
          "satisfactionType": "谋略爽",
          "statEffects": [],
          "relationshipEffects": [],
          "resultNodeIds": [],
          "resultNodes": [],
          "visibleCost": null,
          "visibleReward": null,
          "riskHint": null,
          "processLabel": "试探",
          "isPremium": false
        }
        """
        return try JSONDecoder().decode(Choice.self, from: Data(payload.utf8))
    }
}

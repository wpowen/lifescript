import SwiftData
import XCTest
@testable import LifeScriptSolo

@MainActor
final class SoloReadingViewModelTests: XCTestCase {
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
}

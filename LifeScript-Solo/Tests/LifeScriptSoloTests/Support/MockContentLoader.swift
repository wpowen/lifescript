import Foundation
@testable import LifeScriptSolo

final class MockContentLoader: ContentProviding {
    var stubbedBook: Book?
    var stubbedChapters: [Chapter] = []
    var stubbedWalkthrough: BookWalkthrough?
    var shouldThrow = false

    func listBooks() async throws -> [Book] {
        if shouldThrow { throw ContentError.fileNotFound("mock") }
        return stubbedBook.map { [$0] } ?? []
    }

    func loadBook(id: String) async throws -> Book {
        if shouldThrow { throw ContentError.bookNotFound(id) }
        guard let stubbedBook, stubbedBook.id == id else {
            throw ContentError.bookNotFound(id)
        }
        return stubbedBook
    }

    func loadChapter(bookId: String, chapterId: String) async throws -> Chapter {
        if shouldThrow { throw ContentError.chapterNotFound(chapterId) }
        guard let chapter = stubbedChapters.first(where: { $0.bookId == bookId && $0.id == chapterId }) else {
            throw ContentError.chapterNotFound(chapterId)
        }
        return chapter
    }

    func loadAllChapters(bookId: String) async throws -> [Chapter] {
        if shouldThrow { throw ContentError.fileNotFound("mock_chapters") }
        return stubbedChapters.filter { $0.bookId == bookId }
    }

    func loadWalkthrough(bookId: String) async throws -> BookWalkthrough? {
        if shouldThrow { throw ContentError.fileNotFound("mock_walkthrough") }
        guard stubbedWalkthrough?.bookId == bookId else { return nil }
        return stubbedWalkthrough
    }
}

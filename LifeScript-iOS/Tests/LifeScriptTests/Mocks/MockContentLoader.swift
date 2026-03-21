import Foundation
@testable import LifeScript

final class MockContentLoader: ContentProviding {
    var stubbedBooks: [Book] = []
    var stubbedChapters: [String: [Chapter]] = [:]
    var shouldThrow = false

    func listBooks() async throws -> [Book] {
        if shouldThrow { throw ContentError.fileNotFound("mock") }
        return stubbedBooks
    }

    func loadBook(id: String) async throws -> Book {
        if shouldThrow { throw ContentError.bookNotFound(id) }
        guard let book = stubbedBooks.first(where: { $0.id == id }) else {
            throw ContentError.bookNotFound(id)
        }
        return book
    }

    func loadChapter(bookId: String, chapterId: String) async throws -> Chapter {
        if shouldThrow { throw ContentError.chapterNotFound(chapterId) }
        guard let chapters = stubbedChapters[bookId],
              let chapter = chapters.first(where: { $0.id == chapterId }) else {
            throw ContentError.chapterNotFound(chapterId)
        }
        return chapter
    }

    func loadAllChapters(bookId: String) async throws -> [Chapter] {
        if shouldThrow { throw ContentError.fileNotFound("mock_chapters") }
        return stubbedChapters[bookId] ?? []
    }
}

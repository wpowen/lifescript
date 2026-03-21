import Foundation

/// Loads book and chapter content from bundled JSON files.
/// Designed for easy migration to REST API in future versions.
protocol ContentProviding: Sendable {
    func listBooks() async throws -> [Book]
    func loadBook(id: String) async throws -> Book
    func loadChapter(bookId: String, chapterId: String) async throws -> Chapter
    func loadAllChapters(bookId: String) async throws -> [Chapter]
}

final class BundledContentLoader: ContentProviding {
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func listBooks() async throws -> [Book] {
        try loadJSON(filename: "books", type: [Book].self)
    }

    func loadBook(id: String) async throws -> Book {
        let books = try await listBooks()
        guard let book = books.first(where: { $0.id == id }) else {
            throw ContentError.bookNotFound(id)
        }
        return book
    }

    func loadChapter(bookId: String, chapterId: String) async throws -> Chapter {
        let chapters = try await loadAllChapters(bookId: bookId)
        guard let chapter = chapters.first(where: { $0.id == chapterId }) else {
            throw ContentError.chapterNotFound(chapterId)
        }
        return chapter
    }

    func loadAllChapters(bookId: String) async throws -> [Chapter] {
        try loadJSON(filename: "chapters_\(bookId)", type: [Chapter].self)
    }

    // MARK: - Private

    private func loadJSON<T: Decodable>(filename: String, type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ContentError.fileNotFound(filename)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
}

enum ContentError: LocalizedError {
    case fileNotFound(String)
    case bookNotFound(String)
    case chapterNotFound(String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "内容文件未找到: \(name)"
        case .bookNotFound(let id):
            return "书籍不存在: \(id)"
        case .chapterNotFound(let id):
            return "章节不存在: \(id)"
        case .decodingFailed(let error):
            return "内容解析失败: \(error.localizedDescription)"
        }
    }
}

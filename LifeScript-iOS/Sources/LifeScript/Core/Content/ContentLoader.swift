import Foundation

/// Loads book and chapter content from bundled JSON files.
/// Designed for easy migration to REST API in future versions.
protocol ContentProviding: Sendable {
    func listBooks() async throws -> [Book]
    func loadBook(id: String) async throws -> Book
    func loadChapter(bookId: String, chapterId: String) async throws -> Chapter
    func loadAllChapters(bookId: String) async throws -> [Chapter]
    func loadWalkthrough(bookId: String) async throws -> BookWalkthrough?
}

extension ContentProviding {
    func loadWalkthrough(bookId: String) async throws -> BookWalkthrough? {
        nil
    }
}

final class BundledContentLoader: ContentProviding {
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func listBooks() async throws -> [Book] {
        let manifestBooks = (try? loadJSON(filename: "books", type: [Book].self)) ?? []
        let generatedBooks = try loadGeneratedBooks()
        return mergeBookCatalogs(manifest: manifestBooks, generated: generatedBooks)
    }

    func loadBook(id: String) async throws -> Book {
        if let generated = try loadJSONIfPresent(filename: "book_\(id)", type: Book.self) {
            return generated
        }
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

    func loadWalkthrough(bookId: String) async throws -> BookWalkthrough? {
        try loadJSONIfPresent(filename: "walkthrough_\(bookId)", type: BookWalkthrough.self)
    }

    // MARK: - Private

    private func loadJSON<T: Decodable>(filename: String, type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ContentError.fileNotFound(filename)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private func loadJSONIfPresent<T: Decodable>(filename: String, type: T.Type) throws -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private func loadGeneratedBooks() throws -> [Book] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            return []
        }

        return try urls
            .filter { $0.deletingPathExtension().lastPathComponent.hasPrefix("book_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                let data = try Data(contentsOf: url)
                return try decoder.decode(Book.self, from: data)
            }
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

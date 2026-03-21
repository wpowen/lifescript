import Foundation

/// Loads book and chapter content from bundled resources.
/// Supports JSON files (existing) and Lifescript DSL files (.ls).
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
        // Prefer DSL format (.ls) over JSON for richer authoring experience.
        // Falls back to JSON if no .ls file exists.
        if let dsLChapters = try? await loadChaptersFromDSL(bookId: bookId) {
            return dsLChapters
        }
        return try loadJSON(filename: "chapters_\(bookId)", type: [Chapter].self)
    }

    // MARK: - DSL Loading

    /// Loads all chapters for a book from a Lifescript DSL file.
    /// The DSL file is named `chapters_<bookId>.ls` in the bundle.
    private func loadChaptersFromDSL(bookId: String) async throws -> [Chapter] {
        let filename = "chapters_\(bookId)"
        guard let url = Bundle.main.url(forResource: filename, withExtension: "ls") else {
            throw ContentError.fileNotFound("\(filename).ls")
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        let book = try await loadBook(id: bookId)

        return try await parseDSLContent(content, book: book)
    }

    /// Parses a multi-chapter DSL file.
    /// Chapters are separated by `===` dividers.
    private func parseDSLContent(_ content: String, book: Book) async throws -> [Chapter] {
        let chapterBlocks = content.components(separatedBy: "\n===\n")
        var chapters: [Chapter] = []

        for block in chapterBlocks {
            let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let metadata = try extractMetadata(from: trimmed, book: book)
            let parser = LifescriptParser()
            let chapter = try await parser.parse(content: trimmed, metadata: metadata)
            chapters.append(chapter)
        }

        return chapters.sorted { $0.number < $1.number }
    }

    /// Extracts chapter metadata from the header lines of a DSL block.
    private func extractMetadata(from block: String, book: Book) throws -> NovelMetadata {
        let lines = block.components(separatedBy: "\n")

        // First non-empty line must be: # chapterId | number | Title
        guard let headerLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
              headerLine.hasPrefix("# ") else {
            throw NovelParseError.malformedHeader(lines.first ?? "")
        }

        let headerContent = String(headerLine.dropFirst(2))
        let headerParts = headerContent.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }

        guard headerParts.count >= 3,
              let chapterNumber = Int(headerParts[1]) else {
            throw NovelParseError.malformedHeader(headerLine)
        }

        let chapterId = headerParts[0]
        let title = headerParts[2]

        var isPaid = false
        var hook: String? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("paid:") {
                isPaid = trimmed.dropFirst("paid:".count).trimmingCharacters(in: .whitespaces) == "true"
            } else if trimmed.hasPrefix("hook:") {
                hook = String(trimmed.dropFirst("hook:".count)).trimmingCharacters(in: .whitespaces)
            }
        }

        return NovelMetadata(
            bookId: book.id,
            chapterId: chapterId,
            chapterNumber: chapterNumber,
            title: title,
            isPaid: isPaid,
            nextChapterHook: hook,
            characters: book.characters
        )
    }

    // MARK: - JSON Loading

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

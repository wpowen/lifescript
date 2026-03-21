import Foundation

// MARK: - Novel Parser Protocol

/// Core capability: converts structured text content into a fully-loaded Chapter.
/// Any format (DSL, plain text, EPUB, etc.) can implement this protocol and
/// plug into the existing ContentLoader / ReadingViewModel pipeline unchanged.
protocol NovelParser: Sendable {
    func parse(content: String, metadata: NovelMetadata) async throws -> Chapter
}

// MARK: - Metadata

struct NovelMetadata: Sendable {
    let bookId: String
    let chapterId: String
    let chapterNumber: Int
    let title: String
    let isPaid: Bool
    let nextChapterHook: String?
    /// Characters from the parent Book — used for name→ID resolution
    let characters: [Character]

    init(
        bookId: String,
        chapterId: String,
        chapterNumber: Int,
        title: String,
        isPaid: Bool = false,
        nextChapterHook: String? = nil,
        characters: [Character] = []
    ) {
        self.bookId = bookId
        self.chapterId = chapterId
        self.chapterNumber = chapterNumber
        self.title = title
        self.isPaid = isPaid
        self.nextChapterHook = nextChapterHook
        self.characters = characters
    }
}

// MARK: - Parse Error

enum NovelParseError: LocalizedError {
    case emptyContent
    case malformedHeader(String)
    case unknownCharacter(String)
    case invalidEffect(String)
    case invalidChoiceBlock(String)
    case missingField(String)

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "内容为空"
        case .malformedHeader(let line):
            return "章节头部格式错误: \(line)"
        case .unknownCharacter(let name):
            return "未知角色: \(name)（请在书籍角色列表中添加）"
        case .invalidEffect(let text):
            return "效果格式错误: \(text)"
        case .invalidChoiceBlock(let detail):
            return "选择块格式错误: \(detail)"
        case .missingField(let field):
            return "缺少必要字段: \(field)"
        }
    }
}

// MARK: - Parser Factory

/// Returns the appropriate parser for a given file extension.
enum NovelParserFactory {
    static func parser(for fileExtension: String) -> any NovelParser {
        switch fileExtension.lowercased() {
        case "ls", "lifescript":
            return LifescriptParser()
        default:
            return LifescriptParser()
        }
    }
}

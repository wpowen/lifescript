import Foundation

/// A single chapter of a book, containing story nodes and interaction points.
struct Chapter: Codable, Identifiable, Sendable {
    let id: String
    let bookId: String
    let number: Int
    let title: String
    let nodes: [StoryNode]
    let isPaid: Bool

    /// The hook/teaser shown at the end of this chapter for the next one
    let nextChapterHook: String?

    var openingPreviewSnippet: String? {
        for node in nodes {
            let content: String

            switch node {
            case .text(let textNode):
                content = textNode.content
            case .dialogue(let dialogueNode):
                content = dialogueNode.content
            case .choice, .notification:
                continue
            }

            let normalized = Self.normalizedOpeningPreview(content)
            if !normalized.isEmpty {
                return normalized
            }
        }

        return nil
    }

    private static func normalizedOpeningPreview(_ content: String) -> String {
        let collapsed = content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsed.isEmpty else { return "" }

        let maxLength = 86
        guard collapsed.count > maxLength else { return collapsed }
        return String(collapsed.prefix(maxLength)) + "…"
    }
}

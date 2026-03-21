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
}

import Foundation

/// A single unit of story content within a chapter.
/// Chapters are composed of an ordered list of story nodes.
enum StoryNode: Codable, Identifiable, Sendable {
    /// Plain narrative text
    case text(TextNode)

    /// A character speaks or appears
    case dialogue(DialogueNode)

    /// An interactive choice point
    case choice(ChoiceNode)

    /// A system notification (stat change, relationship change, etc.)
    case notification(NotificationNode)

    var id: String {
        switch self {
        case .text(let n): return n.id
        case .dialogue(let n): return n.id
        case .choice(let n): return n.id
        case .notification(let n): return n.id
        }
    }
}

struct TextNode: Codable, Identifiable, Sendable {
    let id: String
    let content: String
    /// Optional emphasis style for dramatic moments
    var emphasis: Emphasis?

    enum Emphasis: String, Codable, Sendable {
        case normal
        case dramatic    // Larger font, center-aligned
        case whisper     // Smaller, italicized
        case system      // Inner voice / system prompt style
    }
}

struct DialogueNode: Codable, Identifiable, Sendable {
    let id: String
    let characterId: String
    let content: String
    var emotion: String?  // e.g. "冷笑", "震惊", "愤怒"
}

struct ChoiceNode: Codable, Identifiable, Sendable {
    let id: String
    let prompt: String
    let choices: [Choice]
    var timeLimit: TimeInterval?  // Optional countdown in seconds
    var choiceType: ChoiceType

    enum ChoiceType: String, Codable, Sendable {
        case keyDecision    // 关键抉择
        case styleChoice    // 风格选择
        case characterPref  // 角色倾向
    }
}

struct NotificationNode: Codable, Identifiable, Sendable {
    let id: String
    let message: String
    var type: NotificationType

    enum NotificationType: String, Codable, Sendable {
        case statChange
        case relationshipChange
        case itemGained
        case storyHint
    }
}

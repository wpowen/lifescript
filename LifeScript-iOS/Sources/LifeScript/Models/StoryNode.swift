import Foundation

/// A single unit of story content within a chapter.
/// Chapters are composed of an ordered list of story nodes.
///
/// JSON format uses case name as key with payload as value:
/// `{"text": {"id": "...", "content": "..."}}`
enum StoryNode: Identifiable, Sendable {
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

// MARK: - Custom Codable (JSON uses {"caseName": {payload}} format)

extension StoryNode: Codable {
    private enum CodingKeys: String, CodingKey {
        case text, dialogue, choice, notification
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(TextNode.self, forKey: .text) {
            self = .text(value)
        } else if let value = try container.decodeIfPresent(DialogueNode.self, forKey: .dialogue) {
            self = .dialogue(value)
        } else if let value = try container.decodeIfPresent(ChoiceNode.self, forKey: .choice) {
            self = .choice(value)
        } else if let value = try container.decodeIfPresent(NotificationNode.self, forKey: .notification) {
            self = .notification(value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "StoryNode must contain one of: text, dialogue, choice, notification"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode(value, forKey: .text)
        case .dialogue(let value):
            try container.encode(value, forKey: .dialogue)
        case .choice(let value):
            try container.encode(value, forKey: .choice)
        case .notification(let value):
            try container.encode(value, forKey: .notification)
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

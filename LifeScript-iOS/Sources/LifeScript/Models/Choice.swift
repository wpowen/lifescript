import Foundation

/// A single choice option within a ChoiceNode.
struct Choice: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let description: String?

    /// The satisfaction style this choice represents
    let satisfactionType: SatisfactionType

    /// Effects on protagonist stats when chosen
    let statEffects: [StatEffect]

    /// Effects on character relationships when chosen
    let relationshipEffects: [RelationshipEffect]

    /// Story nodes to display after this choice is made
    let resultNodeIds: [String]

    /// Whether this choice requires payment to unlock
    var isPremium: Bool = false
}

enum SatisfactionType: String, Codable, Sendable {
    case immediatePower = "直接爽"      // Immediate face-slap / power display
    case delayedRevenge = "延迟爽"      // Hold back, bigger payoff later
    case cunningScheme = "阴谋爽"       // Cunning manipulation
    case dominantCrush = "碾压爽"       // Overwhelming dominance
    case emotionalPlay = "情感爽"       // Emotional manipulation / romance
    case undercover = "扮猪吃虎"        // Playing weak, reveal later

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .immediatePower: return "bolt.fill"
        case .delayedRevenge: return "hourglass"
        case .cunningScheme: return "brain.head.profile"
        case .dominantCrush: return "flame.fill"
        case .emotionalPlay: return "heart.fill"
        case .undercover: return "theatermasks"
        }
    }
}

struct StatEffect: Codable, Sendable {
    let stat: StatType
    let delta: Int

    enum StatType: String, Codable, Sendable {
        case combat = "战力"
        case fame = "名望"
        case strategy = "谋略"
        case wealth = "财富"
        case charm = "魅力"
        case darkness = "黑化值"
        case destiny = "天命值"
    }
}

struct RelationshipEffect: Codable, Sendable {
    let characterId: String
    let dimension: RelationshipDimension
    let delta: Int

    enum RelationshipDimension: String, Codable, Sendable {
        case trust = "信任"
        case affection = "好感"
        case hostility = "敌意"
        case awe = "敬畏"
        case dependence = "依赖"
    }
}

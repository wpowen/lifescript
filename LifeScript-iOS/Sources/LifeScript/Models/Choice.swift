import Foundation

/// A single choice option within a ChoiceNode.
struct Choice: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let description: String?
    let satisfactionType: SatisfactionType
    let statEffects: [StatEffect]
    let relationshipEffects: [RelationshipEffect]
    var resultNodeIds: [String]
    var resultNodes: [StoryNode]?
    var visibleCost: String?
    var visibleReward: String?
    var riskHint: String?
    var processLabel: String?
    var isPremium: Bool

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        satisfactionType = try c.decode(SatisfactionType.self, forKey: .satisfactionType)
        statEffects = (try? c.decode([StatEffect].self, forKey: .statEffects)) ?? []
        relationshipEffects = (try? c.decode([RelationshipEffect].self, forKey: .relationshipEffects)) ?? []
        resultNodeIds = (try? c.decode([String].self, forKey: .resultNodeIds)) ?? []
        resultNodes = try? c.decode([StoryNode].self, forKey: .resultNodes)
        visibleCost = try c.decodeIfPresent(String.self, forKey: .visibleCost)
        visibleReward = try c.decodeIfPresent(String.self, forKey: .visibleReward)
        riskHint = try c.decodeIfPresent(String.self, forKey: .riskHint)
        processLabel = try c.decodeIfPresent(String.self, forKey: .processLabel)
        isPremium = (try? c.decode(Bool.self, forKey: .isPremium)) ?? false
    }
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

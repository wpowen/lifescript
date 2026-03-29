import Foundation

/// A single choice option within a ChoiceNode.
struct Choice: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let description: String?
    let memoryLabel: String?
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
        memoryLabel = try c.decodeIfPresent(String.self, forKey: .memoryLabel)
        satisfactionType = (try? c.decode(SatisfactionType.self, forKey: .satisfactionType)) ?? .generic
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

struct SatisfactionType: RawRepresentable, Codable, Sendable, Hashable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: (try? container.decode(String.self)) ?? Self.generic.rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static let immediatePower = SatisfactionType(rawValue: "直接爽")
    static let delayedRevenge = SatisfactionType(rawValue: "延迟爽")
    static let cunningScheme = SatisfactionType(rawValue: "阴谋爽")
    static let dominantCrush = SatisfactionType(rawValue: "碾压爽")
    static let emotionalPlay = SatisfactionType(rawValue: "情感爽")
    static let undercover = SatisfactionType(rawValue: "扮猪吃虎")
    static let strategyPlay = SatisfactionType(rawValue: "谋略爽")
    static let sharpFaceSlap = SatisfactionType(rawValue: "嘴毒打脸")
    static let indignation = SatisfactionType(rawValue: "愤慨")
    static let cunningWin = SatisfactionType(rawValue: "智取")
    static let generic = SatisfactionType(rawValue: "策略推进")

    var displayName: String {
        let key = rawValue.isEmpty ? Self.generic.rawValue : rawValue
        return SoloLocalization.localized(key)
    }

    var iconName: String {
        switch rawValue {
        case Self.immediatePower.rawValue:
            return "bolt.fill"
        case Self.delayedRevenge.rawValue:
            return "hourglass"
        case Self.cunningScheme.rawValue, Self.strategyPlay.rawValue, Self.cunningWin.rawValue:
            return "brain.head.profile"
        case Self.dominantCrush.rawValue:
            return "flame.fill"
        case Self.emotionalPlay.rawValue:
            return "heart.fill"
        case Self.undercover.rawValue:
            return "theatermasks"
        case Self.sharpFaceSlap.rawValue:
            return "quote.bubble.fill"
        case Self.indignation.rawValue:
            return "exclamationmark.bubble.fill"
        default:
            return "sparkles"
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

        var displayName: String { SoloLocalization.localized(rawValue) }
    }
}

struct RelationshipEffect: Codable, Sendable {
    let characterId: String
    let dimension: RelationshipDimension
    let delta: Int

    struct RelationshipDimension: RawRepresentable, Codable, Sendable, Hashable {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.init(rawValue: (try? container.decode(String.self)) ?? Self.trust.rawValue)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        static let trust = RelationshipDimension(rawValue: "信任")
        static let affection = RelationshipDimension(rawValue: "好感")
        static let hostility = RelationshipDimension(rawValue: "敌意")
        static let awe = RelationshipDimension(rawValue: "敬畏")
        static let dependence = RelationshipDimension(rawValue: "依赖")
        static let curiosity = RelationshipDimension(rawValue: "好奇")
        static let vigilance = RelationshipDimension(rawValue: "警惕")
        static let contempt = RelationshipDimension(rawValue: "轻视")
        static let anger = RelationshipDimension(rawValue: "愤怒")

        var displayName: String { SoloLocalization.localized(rawValue) }

        var isCoreDimension: Bool {
            switch self {
            case .trust, .affection, .hostility, .awe, .dependence:
                return true
            default:
                return false
            }
        }
    }
}

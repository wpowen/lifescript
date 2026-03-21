import Foundation

/// Tracks the protagonist's relationship with one character
struct RelationshipState: Codable, Identifiable, Sendable, Equatable {
    var id: String { characterId }
    let characterId: String
    var trust: Int        // 信任 0-100
    var affection: Int    // 好感 0-100
    var hostility: Int    // 敌意 0-100
    var awe: Int          // 敬畏 0-100
    var dependence: Int   // 依赖 0-100
    var lastChangeReason: String?
    var unlockedEvents: [String]

    static let maxValue = 100

    var attitudeLabel: String {
        let dominant = dominantDimension
        switch dominant {
        case (.affection, let v) where v >= 80: return "倾心"
        case (.affection, let v) where v >= 50: return "好感"
        case (.trust, let v) where v >= 70: return "信任"
        case (.awe, let v) where v >= 60: return "敬畏"
        case (.hostility, let v) where v >= 70: return "敌视"
        case (.hostility, let v) where v >= 40: return "警惕"
        case (.dependence, let v) where v >= 60: return "依赖"
        default:
            if trust + affection > hostility + 20 { return "关注" }
            return "冷淡"
        }
    }

    private var dominantDimension: (RelationshipEffect.RelationshipDimension, Int) {
        let all: [(RelationshipEffect.RelationshipDimension, Int)] = [
            (.trust, trust),
            (.affection, affection),
            (.hostility, hostility),
            (.awe, awe),
            (.dependence, dependence),
        ]
        return all.max(by: { $0.1 < $1.1 }) ?? (.trust, 0)
    }

    /// Apply relationship effects immutably
    func applying(effects: [RelationshipEffect]) -> RelationshipState {
        var result = self
        for effect in effects where effect.characterId == characterId {
            switch effect.dimension {
            case .trust:      result.trust = clamp(result.trust + effect.delta)
            case .affection:  result.affection = clamp(result.affection + effect.delta)
            case .hostility:  result.hostility = clamp(result.hostility + effect.delta)
            case .awe:        result.awe = clamp(result.awe + effect.delta)
            case .dependence: result.dependence = clamp(result.dependence + effect.delta)
            }
            result.lastChangeReason = "第\(effect.delta > 0 ? "增" : "减")了\(abs(effect.delta))点\(effect.dimension.rawValue)"
        }
        return result
    }

    func value(for dimension: RelationshipEffect.RelationshipDimension) -> Int {
        switch dimension {
        case .trust: return trust
        case .affection: return affection
        case .hostility: return hostility
        case .awe: return awe
        case .dependence: return dependence
        }
    }
}

private func clamp(_ value: Int) -> Int {
    max(0, min(RelationshipState.maxValue, value))
}

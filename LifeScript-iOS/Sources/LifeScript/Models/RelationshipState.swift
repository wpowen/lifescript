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
    var customDimensions: [String: Int] = [:]
    var lastChangeReason: String?
    var unlockedEvents: [String]

    static let maxValue = 100

    var attitudeLabel: String {
        let dominant = dominantDimension
        let dimension = dominant.0.rawValue
        let value = dominant.1

        if dimension == RelationshipEffect.RelationshipDimension.affection.rawValue && value >= 80 {
            return SoloLocalization.localized("倾心")
        }
        if dimension == RelationshipEffect.RelationshipDimension.affection.rawValue && value >= 50 {
            return SoloLocalization.localized("好感")
        }
        if dimension == RelationshipEffect.RelationshipDimension.trust.rawValue && value >= 70 {
            return SoloLocalization.localized("信任")
        }
        if dimension == RelationshipEffect.RelationshipDimension.awe.rawValue && value >= 60 {
            return SoloLocalization.localized("敬畏")
        }
        if dimension == RelationshipEffect.RelationshipDimension.hostility.rawValue && value >= 70 {
            return SoloLocalization.localized("敌视")
        }
        if dimension == RelationshipEffect.RelationshipDimension.hostility.rawValue && value >= 40 {
            return SoloLocalization.localized("警惕")
        }
        if dimension == RelationshipEffect.RelationshipDimension.dependence.rawValue && value >= 60 {
            return SoloLocalization.localized("依赖")
        }
        if dimension == RelationshipEffect.RelationshipDimension.curiosity.rawValue && value >= 35 {
            return SoloLocalization.localized("好奇")
        }
        if dimension == RelationshipEffect.RelationshipDimension.vigilance.rawValue && value >= 35 {
            return SoloLocalization.localized("警惕")
        }
        if dimension == RelationshipEffect.RelationshipDimension.contempt.rawValue && value >= 35 {
            return SoloLocalization.localized("轻视")
        }
        if dimension == RelationshipEffect.RelationshipDimension.anger.rawValue && value >= 35 {
            return SoloLocalization.localized("愤怒")
        }

        if trust + affection > hostility + 20 { return SoloLocalization.localized("关注") }
        if value >= 35 { return SoloLocalization.localized(dimension) }
        return SoloLocalization.localized("冷淡")
    }

    private var dominantDimension: (RelationshipEffect.RelationshipDimension, Int) {
        prominentDimensions.first ?? (.trust, 0)
    }

    var prominentDimensions: [(RelationshipEffect.RelationshipDimension, Int)] {
        let core: [(RelationshipEffect.RelationshipDimension, Int)] = [
            (.trust, trust),
            (.affection, affection),
            (.hostility, hostility),
            (.awe, awe),
            (.dependence, dependence),
        ]
        let custom = customDimensions.map { key, value in
            (RelationshipEffect.RelationshipDimension(rawValue: key), value)
        }

        return (core + custom)
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.rawValue < rhs.0.rawValue
                }
                return lhs.1 > rhs.1
            }
    }

    func topDimensions(limit: Int = 3) -> [(RelationshipEffect.RelationshipDimension, Int)] {
        Array(prominentDimensions.prefix(limit))
    }

    /// Apply relationship effects immutably
    func applying(effects: [RelationshipEffect]) -> RelationshipState {
        var result = self
        for effect in effects where effect.characterId == characterId {
            switch effect.dimension.rawValue {
            case RelationshipEffect.RelationshipDimension.trust.rawValue:
                result.trust = clamp(result.trust + effect.delta)
            case RelationshipEffect.RelationshipDimension.affection.rawValue:
                result.affection = clamp(result.affection + effect.delta)
            case RelationshipEffect.RelationshipDimension.hostility.rawValue:
                result.hostility = clamp(result.hostility + effect.delta)
            case RelationshipEffect.RelationshipDimension.awe.rawValue:
                result.awe = clamp(result.awe + effect.delta)
            case RelationshipEffect.RelationshipDimension.dependence.rawValue:
                result.dependence = clamp(result.dependence + effect.delta)
            default:
                let current = result.customDimensions[effect.dimension.rawValue] ?? 0
                result.customDimensions[effect.dimension.rawValue] = clamp(current + effect.delta)
            }
            result.lastChangeReason = SoloLocalization.format(
                "第%@了%d点%@",
                effect.delta > 0 ? SoloLocalization.localized("增") : SoloLocalization.localized("减"),
                abs(effect.delta),
                effect.dimension.displayName
            )
        }
        return result
    }

    func value(for dimension: RelationshipEffect.RelationshipDimension) -> Int {
        switch dimension.rawValue {
        case RelationshipEffect.RelationshipDimension.trust.rawValue:
            return trust
        case RelationshipEffect.RelationshipDimension.affection.rawValue:
            return affection
        case RelationshipEffect.RelationshipDimension.hostility.rawValue:
            return hostility
        case RelationshipEffect.RelationshipDimension.awe.rawValue:
            return awe
        case RelationshipEffect.RelationshipDimension.dependence.rawValue:
            return dependence
        default:
            return customDimensions[dimension.rawValue] ?? 0
        }
    }
}

private func clamp(_ value: Int) -> Int {
    max(0, min(RelationshipState.maxValue, value))
}

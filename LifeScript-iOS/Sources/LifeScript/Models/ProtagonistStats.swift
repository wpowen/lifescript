import Foundation

/// The protagonist's current attribute values
struct ProtagonistStats: Codable, Sendable, Equatable {
    var combat: Int      // 战力
    var fame: Int        // 名望
    var strategy: Int    // 谋略
    var wealth: Int      // 财富
    var charm: Int       // 魅力
    var darkness: Int    // 黑化值
    var destiny: Int     // 天命值

    static let initial = ProtagonistStats(
        combat: 10, fame: 5, strategy: 15, wealth: 5,
        charm: 10, darkness: 0, destiny: 20
    )

    static let maxValue = 100

    /// Apply a list of stat effects immutably
    func applying(effects: [StatEffect]) -> ProtagonistStats {
        var result = self
        for effect in effects {
            switch effect.stat {
            case .combat:   result.combat = clamp(result.combat + effect.delta)
            case .fame:     result.fame = clamp(result.fame + effect.delta)
            case .strategy: result.strategy = clamp(result.strategy + effect.delta)
            case .wealth:   result.wealth = clamp(result.wealth + effect.delta)
            case .charm:    result.charm = clamp(result.charm + effect.delta)
            case .darkness: result.darkness = clamp(result.darkness + effect.delta)
            case .destiny:  result.destiny = clamp(result.destiny + effect.delta)
            }
        }
        return result
    }

    /// Compute diff between two stat snapshots
    func diff(from previous: ProtagonistStats) -> [StatEffect.StatType: Int] {
        var result: [StatEffect.StatType: Int] = [:]
        let pairs: [(StatEffect.StatType, Int, Int)] = [
            (.combat, combat, previous.combat),
            (.fame, fame, previous.fame),
            (.strategy, strategy, previous.strategy),
            (.wealth, wealth, previous.wealth),
            (.charm, charm, previous.charm),
            (.darkness, darkness, previous.darkness),
            (.destiny, destiny, previous.destiny),
        ]
        for (stat, current, prev) in pairs {
            let delta = current - prev
            if delta != 0 { result[stat] = delta }
        }
        return result
    }

    func value(for stat: StatEffect.StatType) -> Int {
        switch stat {
        case .combat: return combat
        case .fame: return fame
        case .strategy: return strategy
        case .wealth: return wealth
        case .charm: return charm
        case .darkness: return darkness
        case .destiny: return destiny
        }
    }
}

private func clamp(_ value: Int) -> Int {
    max(0, min(ProtagonistStats.maxValue, value))
}

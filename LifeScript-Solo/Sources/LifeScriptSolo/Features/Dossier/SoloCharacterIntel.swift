import Foundation

struct SoloCharacterIntel: Equatable {
    enum RecommendedTag: String, Equatable {
        case pullable = "可牵引"
        case highRisk = "高风险"
        case pivotal = "高局重"
        case latent = "待显形"
    }

    let characterID: String
    let resonance: Int
    let influence: Int
    let danger: Int
    let statusLine: String
    let recommendedTag: RecommendedTag
    let isInPlay: Bool
    let isUnlocked: Bool

    static func build(character: Character, relation: RelationshipState?) -> SoloCharacterIntel {
        let resonance = SoloCharacterCodex.resonanceScore(for: relation)
        let influence = SoloCharacterCodex.influenceScore(for: character, relation: relation)
        let danger = dangerScore(for: relation)
        let statusLine = battleStatusLine(character: character, relation: relation, danger: danger, resonance: resonance)
        let tag = recommendedTag(relation: relation, resonance: resonance, influence: influence, danger: danger)

        return SoloCharacterIntel(
            characterID: character.id,
            resonance: resonance,
            influence: influence,
            danger: danger,
            statusLine: statusLine,
            recommendedTag: tag,
            isInPlay: relation != nil,
            isUnlocked: relation != nil
        )
    }

    private static func dangerScore(for relation: RelationshipState?) -> Int {
        guard let relation else { return 15 }
        let vigilance = relation.value(for: .vigilance)
        let anger = relation.value(for: .anger)
        let contempt = relation.value(for: .contempt)
        let weighted = relation.hostility * 3 + vigilance * 2 + anger * 2 + contempt
        return min(100, max(0, weighted / 8))
    }

    private static func recommendedTag(
        relation: RelationshipState?,
        resonance: Int,
        influence: Int,
        danger: Int
    ) -> RecommendedTag {
        guard relation != nil else { return .latent }
        if danger >= 60 { return .highRisk }
        if influence >= 70 { return .pivotal }
        if resonance >= 55 { return .pullable }
        return .pivotal
    }

    private static func battleStatusLine(
        character: Character,
        relation: RelationshipState?,
        danger: Int,
        resonance: Int
    ) -> String {
        guard let relation else {
            return "\(character.name) 还未完全入局，继续推进章节后才能看清其真实立场。"
        }

        if let reason = relation.lastChangeReason, !reason.isEmpty {
            return reason
        }

        if danger >= 60 {
            return "\(character.name)当前外显态度为「\(relation.attitudeLabel)」，风险信号已偏高，适合先稳后动。"
        }
        if resonance >= 60 {
            return "\(character.name)当前态度为「\(relation.attitudeLabel)」，已进入可牵引区间，适合主动试探。"
        }
        return "\(character.name)当前态度为「\(relation.attitudeLabel)」，仍处于观察与博弈阶段。"
    }
}


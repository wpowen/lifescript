import Foundation

/// Parses effect declaration strings from the Lifescript DSL into typed model objects.
///
/// Stat effects format:    "战力+15, 名望-5, 黑化值+10"
/// Relation effects format: "林三长老(敬畏+25, 敌意+15), 林月(好感+10)"
struct EffectParser: Sendable {

    private let registry: CharacterRegistry

    init(registry: CharacterRegistry) {
        self.registry = registry
    }

    // MARK: - Stat Effects

    /// Parse "战力+15, 名望-5" → [StatEffect]
    func parseStatEffects(_ text: String) throws -> [StatEffect] {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var results: [StatEffect] = []
        let parts = text.components(separatedBy: ",")

        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if let effect = parseStatEffect(trimmed) {
                results.append(effect)
            } else {
                throw NovelParseError.invalidEffect(trimmed)
            }
        }
        return results
    }

    private func parseStatEffect(_ token: String) -> StatEffect? {
        // Match: <name><+/-><number>  e.g. "战力+15" or "黑化值-5"
        let pattern = #"^(.+?)([+-])(\d+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: token, range: NSRange(token.startIndex..., in: token)),
              match.numberOfRanges == 4 else { return nil }

        let statName = String(token[Range(match.range(at: 1), in: token)!])
        let sign = String(token[Range(match.range(at: 2), in: token)!])
        let valueStr = String(token[Range(match.range(at: 3), in: token)!])

        guard let value = Int(valueStr),
              let statType = statType(from: statName) else { return nil }

        let delta = sign == "+" ? value : -value
        return StatEffect(stat: statType, delta: delta)
    }

    private func statType(from name: String) -> StatEffect.StatType? {
        StatEffect.StatType.allCases.first { $0.rawValue == name }
    }

    // MARK: - Relationship Effects

    /// Parse "林三长老(敬畏+25, 敌意+15), 林月(好感+10)" → [RelationshipEffect]
    func parseRelationshipEffects(_ text: String) throws -> [RelationshipEffect] {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var results: [RelationshipEffect] = []
        // Split on top-level commas (between character blocks, not inside parens)
        let blocks = splitTopLevel(text)

        for block in blocks {
            let trimmed = block.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let effects = try parseRelationshipBlock(trimmed)
            results.append(contentsOf: effects)
        }
        return results
    }

    private func parseRelationshipBlock(_ block: String) throws -> [RelationshipEffect] {
        // Format: "角色名(维度+值, 维度-值)"
        guard let parenOpen = block.firstIndex(of: "("),
              let parenClose = block.lastIndex(of: ")") else {
            throw NovelParseError.invalidEffect(block)
        }

        let charName = String(block[block.startIndex..<parenOpen]).trimmingCharacters(in: .whitespaces)
        let charId = registry.resolve(charName)
        let effectsStr = String(block[block.index(after: parenOpen)..<parenClose])

        var results: [RelationshipEffect] = []
        let parts = effectsStr.components(separatedBy: ",")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if let effect = parseRelationshipEffect(trimmed, characterId: charId) {
                results.append(effect)
            } else {
                throw NovelParseError.invalidEffect(trimmed)
            }
        }
        return results
    }

    private func parseRelationshipEffect(_ token: String, characterId: String) -> RelationshipEffect? {
        let pattern = #"^(.+?)([+-])(\d+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: token, range: NSRange(token.startIndex..., in: token)),
              match.numberOfRanges == 4 else { return nil }

        let dimName = String(token[Range(match.range(at: 1), in: token)!])
        let sign = String(token[Range(match.range(at: 2), in: token)!])
        let valueStr = String(token[Range(match.range(at: 3), in: token)!])

        guard let value = Int(valueStr),
              let dimension = RelationshipEffect.RelationshipDimension(rawValue: dimName) else { return nil }

        let delta = sign == "+" ? value : -value
        return RelationshipEffect(characterId: characterId, dimension: dimension, delta: delta)
    }

    // MARK: - Helpers

    /// Splits a comma-separated string respecting nested parentheses.
    private func splitTopLevel(_ text: String) -> [String] {
        var results: [String] = []
        var current = ""
        var depth = 0

        for char in text {
            switch char {
            case "(": depth += 1; current.append(char)
            case ")": depth -= 1; current.append(char)
            case "," where depth == 0:
                results.append(current)
                current = ""
            default:
                current.append(char)
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            results.append(current)
        }
        return results
    }
}

// MARK: - StatEffect.StatType CaseIterable

extension StatEffect.StatType: CaseIterable {
    public static var allCases: [StatEffect.StatType] {
        [.combat, .fame, .strategy, .wealth, .charm, .darkness, .destiny]
    }
}

import Foundation

/// Maps character display names → character IDs from the Book model.
/// Enables DSL authors to write character names naturally ("林三长老")
/// instead of technical IDs ("char_elder_three").
struct CharacterRegistry: Sendable {
    // name → id mapping, e.g. "林三长老" → "char_elder_three"
    private let nameToId: [String: String]
    // Also support short names / aliases
    private let characters: [Character]

    init(characters: [Character]) {
        self.characters = characters
        var mapping: [String: String] = [:]
        for char in characters {
            mapping[char.name] = char.id
            // Also index by title if different from name
            if char.title != char.name {
                mapping[char.title] = char.id
            }
        }
        self.nameToId = mapping
    }

    /// Resolve a name to its character ID.
    /// Returns the name as-is if no match found (treated as unknown NPC).
    func resolve(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return nameToId[trimmed] ?? trimmed
    }

    /// Returns the Character object for a given name, if found.
    func character(named name: String) -> Character? {
        let id = resolve(name)
        return characters.first { $0.id == id }
    }

    /// Returns true if the name maps to a known character.
    func isKnown(_ name: String) -> Bool {
        nameToId[name.trimmingCharacters(in: .whitespaces)] != nil
    }
}

import XCTest
@testable import LifeScript

final class RelationshipStateTests: XCTestCase {

    func test_applying_effectsForMatchingCharacter() {
        let rel = RelationshipState(
            characterId: "char_1",
            trust: 30, affection: 20, hostility: 10, awe: 10, dependence: 0,
            lastChangeReason: nil, unlockedEvents: []
        )
        let effects = [
            RelationshipEffect(characterId: "char_1", dimension: .trust, delta: 15),
            RelationshipEffect(characterId: "char_1", dimension: .affection, delta: 10),
        ]

        let result = rel.applying(effects: effects)

        XCTAssertEqual(result.trust, 45)
        XCTAssertEqual(result.affection, 30)
        XCTAssertEqual(result.hostility, 10) // unchanged
    }

    func test_applying_ignoresEffectsForOtherCharacters() {
        let rel = RelationshipState(
            characterId: "char_1",
            trust: 30, affection: 20, hostility: 10, awe: 10, dependence: 0,
            lastChangeReason: nil, unlockedEvents: []
        )
        let effects = [
            RelationshipEffect(characterId: "char_2", dimension: .trust, delta: 50),
        ]

        let result = rel.applying(effects: effects)

        XCTAssertEqual(result.trust, 30) // unchanged
    }

    func test_attitudeLabel_affectionHigh() {
        let rel = RelationshipState(
            characterId: "char_1",
            trust: 30, affection: 85, hostility: 0, awe: 10, dependence: 0,
            lastChangeReason: nil, unlockedEvents: []
        )
        XCTAssertEqual(rel.attitudeLabel, "倾心")
    }

    func test_attitudeLabel_hostileHigh() {
        let rel = RelationshipState(
            characterId: "char_1",
            trust: 10, affection: 5, hostility: 75, awe: 10, dependence: 0,
            lastChangeReason: nil, unlockedEvents: []
        )
        XCTAssertEqual(rel.attitudeLabel, "敌视")
    }

    func test_clampsToMaxValue() {
        let rel = RelationshipState(
            characterId: "char_1",
            trust: 95, affection: 20, hostility: 10, awe: 10, dependence: 0,
            lastChangeReason: nil, unlockedEvents: []
        )
        let effects = [
            RelationshipEffect(characterId: "char_1", dimension: .trust, delta: 20),
        ]

        let result = rel.applying(effects: effects)

        XCTAssertEqual(result.trust, 100)
    }

    func test_immutability() {
        let original = RelationshipState(
            characterId: "char_1",
            trust: 30, affection: 20, hostility: 10, awe: 10, dependence: 0,
            lastChangeReason: nil, unlockedEvents: []
        )
        let effects = [
            RelationshipEffect(characterId: "char_1", dimension: .trust, delta: 40),
        ]

        let result = original.applying(effects: effects)

        XCTAssertEqual(original.trust, 30) // Original unchanged
        XCTAssertEqual(result.trust, 70)
    }
}

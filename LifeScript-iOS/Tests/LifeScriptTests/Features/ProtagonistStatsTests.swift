import XCTest
@testable import LifeScript

final class ProtagonistStatsTests: XCTestCase {

    func test_applying_positiveEffects() {
        let stats = ProtagonistStats.initial
        let effects = [
            StatEffect(stat: .combat, delta: 10),
            StatEffect(stat: .fame, delta: 5),
        ]

        let result = stats.applying(effects: effects)

        XCTAssertEqual(result.combat, stats.combat + 10)
        XCTAssertEqual(result.fame, stats.fame + 5)
        XCTAssertEqual(result.strategy, stats.strategy) // unchanged
    }

    func test_applying_negativeEffects() {
        let stats = ProtagonistStats.initial
        let effects = [StatEffect(stat: .combat, delta: -5)]

        let result = stats.applying(effects: effects)

        XCTAssertEqual(result.combat, stats.combat - 5)
    }

    func test_applying_clampsToZero() {
        let stats = ProtagonistStats(combat: 3, fame: 0, strategy: 0, wealth: 0, charm: 0, darkness: 0, destiny: 0)
        let effects = [StatEffect(stat: .combat, delta: -10)]

        let result = stats.applying(effects: effects)

        XCTAssertEqual(result.combat, 0) // Clamped, not -7
    }

    func test_applying_clampsToMax() {
        let stats = ProtagonistStats(combat: 95, fame: 0, strategy: 0, wealth: 0, charm: 0, darkness: 0, destiny: 0)
        let effects = [StatEffect(stat: .combat, delta: 20)]

        let result = stats.applying(effects: effects)

        XCTAssertEqual(result.combat, 100) // Clamped at max
    }

    func test_diff_returnsChangedStats() {
        let before = ProtagonistStats.initial
        let after = before.applying(effects: [
            StatEffect(stat: .combat, delta: 10),
            StatEffect(stat: .darkness, delta: 5),
        ])

        let diff = after.diff(from: before)

        XCTAssertEqual(diff[.combat], 10)
        XCTAssertEqual(diff[.darkness], 5)
        XCTAssertNil(diff[.fame]) // unchanged
        XCTAssertNil(diff[.strategy])
    }

    func test_diff_emptyWhenNoChange() {
        let stats = ProtagonistStats.initial
        let diff = stats.diff(from: stats)

        XCTAssertTrue(diff.isEmpty)
    }

    func test_immutability() {
        let original = ProtagonistStats.initial
        let effects = [StatEffect(stat: .combat, delta: 50)]

        let result = original.applying(effects: effects)

        XCTAssertEqual(original.combat, 10) // Original unchanged
        XCTAssertEqual(result.combat, 60)
    }
}

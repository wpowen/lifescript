import XCTest
@testable import LifeScriptSolo

final class SoloCharacterIntelTests: XCTestCase {
    func test_build_marksHighRiskWhenHostilityAndVigilanceAreHigh() {
        let character = Character(
            id: "char_enemy",
            name: "韩烈",
            title: "玄武宗天骄",
            avatarImageName: "avatar",
            description: "测试角色",
            role: .rival
        )
        let relation = RelationshipState(
            characterId: "char_enemy",
            trust: 15,
            affection: 5,
            hostility: 90,
            awe: 20,
            dependence: 0,
            customDimensions: [
                RelationshipEffect.RelationshipDimension.vigilance.rawValue: 80,
                RelationshipEffect.RelationshipDimension.anger.rawValue: 65,
            ],
            lastChangeReason: "他已经公开放话要你付出代价。",
            unlockedEvents: []
        )

        let intel = SoloCharacterIntel.build(character: character, relation: relation)

        XCTAssertEqual(intel.recommendedTag, .highRisk)
        XCTAssertTrue(intel.isInPlay)
        XCTAssertGreaterThanOrEqual(intel.danger, 60)
    }

    func test_build_marksLatentWhenRelationMissing() {
        let character = Character(
            id: "char_unknown",
            name: "未知人",
            title: "尚未显形",
            avatarImageName: "avatar",
            description: "测试角色",
            role: .neutral
        )

        let intel = SoloCharacterIntel.build(character: character, relation: nil)

        XCTAssertEqual(intel.recommendedTag, .latent)
        XCTAssertFalse(intel.isInPlay)
        XCTAssertFalse(intel.isUnlocked)
        XCTAssertTrue(intel.statusLine.contains("未完全入局"))
    }
}


import XCTest
@testable import LifeScriptSolo

final class TianjiluArtworkCatalogTests: XCTestCase {
    func test_homeHeroUsesDedicatedHomepageArtwork() {
        XCTAssertEqual(
            TianjiluArtworkCatalog.homeHeroMaster.resourceName,
            "tianjilu_home_hero_master"
        )
    }

    func test_volumeMappingUsesCurrentChapterRange() {
        XCTAssertEqual(
            TianjiluArtworkCatalog.volume(for: 1).cover.resourceName,
            "tianjilu_cover_vol1_awakening"
        )
        XCTAssertEqual(
            TianjiluArtworkCatalog.volume(for: 241).cover.resourceName,
            "tianjilu_cover_vol3_secret_realm"
        )
        XCTAssertEqual(
            TianjiluArtworkCatalog.volume(for: 1081).cover.resourceName,
            "tianjilu_cover_vol10_endgame"
        )
    }

    func test_portraitMappingReturnsDedicatedArtworkForKeyCharacters() {
        XCTAssertEqual(
            TianjiluArtworkCatalog.portrait(for: "char_chenji")?.resourceName,
            "tianjilu_chen_ji_portrait"
        )
        XCTAssertEqual(
            TianjiluArtworkCatalog.portrait(for: "char_tiandaozhiyan")?.resourceName,
            "tianjilu_tiandao_eye"
        )
    }
}

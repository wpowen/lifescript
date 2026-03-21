import XCTest
@testable import LifeScript

final class ContentCatalogTests: XCTestCase {
    func test_mergeBookCatalogs_prefersGeneratedBooksAndAppendsNewOnes() {
        let manifestUrban = TestFixtures.makeBook(id: "urban_001", title: "旧都市书")
        let manifestCultivation = TestFixtures.makeBook(id: "cultivation_001", title: "旧修仙书")

        let generatedCultivation = TestFixtures.makeBook(id: "cultivation_001", title: "新修仙书")
        let generatedSuspense = TestFixtures.makeBook(id: "suspense_002", title: "新悬疑书")

        let merged = mergeBookCatalogs(
            manifest: [manifestUrban, manifestCultivation],
            generated: [generatedCultivation, generatedSuspense]
        )

        XCTAssertEqual(merged.map(\.id), ["urban_001", "cultivation_001", "suspense_002"])
        XCTAssertEqual(merged.first(where: { $0.id == "cultivation_001" })?.title, "新修仙书")
    }
}

import XCTest
@testable import LifeScriptSolo

@MainActor
final class SoloVolumeStoreTests: XCTestCase {
    func test_tianjiluVolumeCatalog_hasTenVolumes_andFirstVolumeIsFree() {
        let plans = SoloVolumeCatalog.plans(for: "天机录")

        XCTAssertEqual(plans.count, 10)
        XCTAssertEqual(plans.first?.chapterRange, 1...120)
        XCTAssertEqual(plans.last?.chapterRange, 1081...1200)
        XCTAssertTrue(plans.first?.isFree == true)
        XCTAssertTrue(plans.dropFirst().allSatisfy { !$0.isFree })
    }

    func test_chapterAccessState_locksVolumeTwo_whenNoEntitlementExists() async {
        let client = MockPurchaseClient(
            products: [
                SoloStoreProduct(
                    id: "com.lifescript.solo.tianjilu.volume2",
                    displayName: "卷二",
                    displayPrice: "¥1.00",
                    detail: "卷二"
                )
            ],
            entitlements: Set<String>()
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()
        let state = sut.chapterAccessState(chapterId: "天机录_ch0121", chapterNumber: 121)

        XCTAssertTrue(state.isLocked)
        XCTAssertEqual(state.volume?.index, 2)
        XCTAssertEqual(state.primaryActionTitle, "解锁第2卷 · ¥1.00")
    }

    func test_chapterAccessState_allowsPurchasedVolume() async {
        let client = MockPurchaseClient(
            products: [],
            entitlements: ["com.lifescript.solo.tianjilu.volume2"]
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()
        let state = sut.chapterAccessState(chapterId: "天机录_ch0121", chapterNumber: 121)

        XCTAssertFalse(state.isLocked)
        XCTAssertEqual(state.volume?.index, 2)
    }

    func test_purchase_unlocksVolumeAndUpdatesStatusMessage() async throws {
        let client = MockPurchaseClient(
            products: [
                SoloStoreProduct(
                    id: "com.lifescript.solo.tianjilu.volume3",
                    displayName: "卷三",
                    displayPrice: "¥1.00",
                    detail: "卷三"
                )
            ],
            entitlements: Set<String>()
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()
        let volume = try XCTUnwrap(SoloVolumeCatalog.volume(for: "天机录", chapterNumber: 241))
        let unlocked = await sut.purchase(volume)

        XCTAssertTrue(unlocked)
        XCTAssertTrue(sut.isUnlocked(volume))
        XCTAssertEqual(sut.statusMessage, "已解锁卷三 · 秘境争锋，可以继续推进了。")
    }

    func test_chapterOpeningPreviewSnippet_prefersFirstNarrativeNode_andNormalizesWhitespace() {
        let chapter = Chapter(
            id: "sample",
            bookId: "天机录",
            number: 121,
            title: "宗门暗战",
            nodes: [
                .notification(NotificationNode(id: "n1", message: "灵气 +1", type: .statChange)),
                .text(TextNode(
                    id: "t1",
                    content: "  夜色  垂落，\n\n山门外的风声像刀一样刮过石阶。   你抬眼时，长老殿的灯还没有灭。  ",
                    emphasis: nil
                ))
            ],
            isPaid: true,
            nextChapterHook: nil
        )

        XCTAssertEqual(
            chapter.openingPreviewSnippet,
            "夜色 垂落， 山门外的风声像刀一样刮过石阶。 你抬眼时，长老殿的灯还没有灭。"
        )
    }

    func test_chapterOpeningPreviewSnippet_truncatesLongNarrative() {
        let chapter = Chapter(
            id: "long",
            bookId: "天机录",
            number: 122,
            title: "长夜",
            nodes: [
                .dialogue(DialogueNode(
                    id: "d1",
                    characterId: "hero",
                    content: String(repeating: "风", count: 120),
                    emotion: nil
                ))
            ],
            isPaid: true,
            nextChapterHook: nil
        )

        XCTAssertEqual(chapter.openingPreviewSnippet?.count, 87)
        XCTAssertTrue(chapter.openingPreviewSnippet?.hasSuffix("…") == true)
    }
}

private actor MockPurchaseClient: SoloPurchaseProviding {
    private let stubbedProducts: [String: SoloStoreProduct]
    private var entitlements: Set<String>

    init(products: [SoloStoreProduct], entitlements: Set<String>) {
        self.stubbedProducts = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        self.entitlements = entitlements
    }

    func loadProducts(for ids: [String]) async throws -> [SoloStoreProduct] {
        ids.compactMap { stubbedProducts[$0] }
    }

    func currentEntitlementProductIDs() async -> Set<String> {
        entitlements
    }

    func purchase(productID: String) async throws -> SoloPurchaseOutcome {
        entitlements.insert(productID)
        return .success
    }

    func syncPurchases() async throws {}
}

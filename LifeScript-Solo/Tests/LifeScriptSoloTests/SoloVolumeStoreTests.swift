import XCTest
@testable import LifeScriptSolo

@MainActor
final class SoloVolumeStoreTests: XCTestCase {

    // MARK: - Catalog

    func test_tianjiluVolumeCatalog_hasTenVolumes_andFirstVolumeIsFree() {
        let plans = SoloVolumeCatalog.plans(for: "天机录")

        XCTAssertEqual(plans.count, 10)
        XCTAssertEqual(plans.first?.chapterRange, 1...120)
        XCTAssertEqual(plans.last?.chapterRange, 1081...1200)
        XCTAssertTrue(plans.first?.isFree == true)
        XCTAssertTrue(plans.dropFirst().allSatisfy { !$0.isFree })
    }

    // MARK: - Chapter Access State

    func test_chapterAccessState_locksVolumeTwo_whenNoEntitlementExists() async {
        let client = MockPurchaseClient(
            products: [volumeTwoProduct],
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

    func test_chapterAccessState_freeVolumeIsAlwaysUnlocked() async {
        let client = MockPurchaseClient(products: [], entitlements: Set<String>())
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()
        let state = sut.chapterAccessState(chapterId: "天机录_ch0001", chapterNumber: 1)

        XCTAssertFalse(state.isLocked)
    }

    // MARK: - Purchase

    func test_purchase_unlocksVolumeAndUpdatesStatusMessage() async throws {
        let client = MockPurchaseClient(
            products: [volumeThreeProduct],
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

    func test_purchase_returnsFalse_andShowsPendingMessage_whenPending() async throws {
        let client = MockPurchaseClient(
            products: [volumeTwoProduct],
            entitlements: Set<String>(),
            purchaseOutcome: .pending
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()
        let volume = try XCTUnwrap(SoloVolumeCatalog.volume(for: "天机录", chapterNumber: 121))
        let unlocked = await sut.purchase(volume)

        XCTAssertFalse(unlocked)
        XCTAssertFalse(sut.isUnlocked(volume))
        XCTAssertTrue(sut.statusMessage?.contains("等待确认") == true)
    }

    func test_purchase_returnsFalse_andNoMessage_whenUserCancels() async throws {
        let client = MockPurchaseClient(
            products: [volumeTwoProduct],
            entitlements: Set<String>(),
            purchaseOutcome: .userCancelled
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()
        let volume = try XCTUnwrap(SoloVolumeCatalog.volume(for: "天机录", chapterNumber: 121))
        let unlocked = await sut.purchase(volume)

        XCTAssertFalse(unlocked)
        XCTAssertNil(sut.statusMessage)
    }

    func test_purchase_showsErrorMessage_whenPurchaseFails() async throws {
        let client = MockPurchaseClient(
            products: [volumeTwoProduct],
            entitlements: Set<String>(),
            shouldFailPurchase: true
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()
        let volume = try XCTUnwrap(SoloVolumeCatalog.volume(for: "天机录", chapterNumber: 121))
        let unlocked = await sut.purchase(volume)

        XCTAssertFalse(unlocked)
        XCTAssertNotNil(sut.statusMessage)
    }

    func test_purchase_blockedWhenOperationInProgress() async throws {
        let client = MockPurchaseClient(
            products: [volumeTwoProduct],
            entitlements: Set<String>()
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)
        await sut.reload()

        let volume = try XCTUnwrap(SoloVolumeCatalog.volume(for: "天机录", chapterNumber: 121))

        let task1 = Task { await sut.purchase(volume) }
        let task2 = Task { await sut.purchase(volume) }
        let r1 = await task1.value
        let r2 = await task2.value

        let successCount = [r1, r2].filter { $0 }.count
        XCTAssertLessThanOrEqual(successCount, 1)
    }

    // MARK: - Restore Purchases

    func test_restorePurchases_updatesEntitlementsAndShowsMessage() async {
        let client = MockPurchaseClient(
            products: [],
            entitlements: Set<String>()
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)
        await sut.reload()

        await client.setEntitlements(["com.lifescript.solo.tianjilu.volume2"])
        let success = await sut.restorePurchases()

        XCTAssertTrue(success)
        XCTAssertTrue(sut.unlockedProductIDs.contains("com.lifescript.solo.tianjilu.volume2"))
        XCTAssertEqual(sut.statusMessage, "购买记录已恢复，可以继续阅读。")
    }

    func test_restorePurchases_showsEmptyMessage_whenNoPurchasesExist() async {
        let client = MockPurchaseClient(products: [], entitlements: Set<String>())
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)
        await sut.reload()

        let success = await sut.restorePurchases()

        XCTAssertTrue(success)
        XCTAssertEqual(sut.statusMessage, "当前没有可恢复的卷购买记录。")
    }

    func test_restorePurchases_showsErrorMessage_whenSyncFails() async {
        let client = MockPurchaseClient(
            products: [],
            entitlements: Set<String>(),
            shouldFailSync: true
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)
        await sut.reload()

        let success = await sut.restorePurchases()

        XCTAssertFalse(success)
        XCTAssertEqual(sut.statusMessage, "恢复购买失败，请稍后再试。")
    }

    // MARK: - Product Loading Fallback

    func test_loadProductsFailure_showsFallbackPrices() async throws {
        let client = MockPurchaseClient(
            products: [],
            entitlements: Set<String>(),
            shouldFailLoad: true
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()

        XCTAssertTrue(sut.productsByID.isEmpty)
        XCTAssertTrue(sut.statusMessage?.contains("预设价格") == true)

        let volume2 = try XCTUnwrap(SoloVolumeCatalog.volume(for: "天机录", chapterNumber: 121))
        XCTAssertEqual(sut.displayPrice(for: volume2), "1元")
    }

    // MARK: - Clear Status Message

    func test_clearStatusMessage_resetsMessage() async {
        let client = MockPurchaseClient(products: [], entitlements: Set<String>())
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)
        await sut.reload()
        _ = await sut.restorePurchases()

        XCTAssertNotNil(sut.statusMessage)
        sut.clearStatusMessage()
        XCTAssertNil(sut.statusMessage)
    }

    // MARK: - isOperationInProgress

    func test_isOperationInProgress_defaultsFalse() async {
        let client = MockPurchaseClient(products: [], entitlements: Set<String>())
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)
        await sut.reload()

        XCTAssertFalse(sut.isOperationInProgress)
    }

    // MARK: - Transaction Listener

    func test_transactionListener_refreshesEntitlements_whenUpdateReceived() async {
        let transactionStream = MockTransactionStream()
        let client = MockPurchaseClient(
            products: [],
            entitlements: Set<String>(),
            transactionStream: transactionStream
        )
        let sut = SoloVolumeStore(storyId: "天机录", purchaseClient: client)

        await sut.reload()
        XCTAssertTrue(sut.unlockedProductIDs.isEmpty)

        // Simulate external purchase (e.g., Ask-to-Buy approval)
        let productID = "com.lifescript.solo.tianjilu.volume2"
        await client.setEntitlements([productID])
        transactionStream.yield(productID)

        // Wait for the listener to process
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(sut.unlockedProductIDs.contains(productID))
    }

    // MARK: - Opening Preview Snippet

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

    // MARK: - Fixtures

    private var volumeTwoProduct: SoloStoreProduct {
        SoloStoreProduct(
            id: "com.lifescript.solo.tianjilu.volume2",
            displayName: "卷二",
            displayPrice: "¥1.00",
            detail: "卷二"
        )
    }

    private var volumeThreeProduct: SoloStoreProduct {
        SoloStoreProduct(
            id: "com.lifescript.solo.tianjilu.volume3",
            displayName: "卷三",
            displayPrice: "¥1.00",
            detail: "卷三"
        )
    }
}

// MARK: - Mock

private final class MockTransactionStream: Sendable {
    private let continuation: AsyncStream<String>.Continuation
    let stream: AsyncStream<String>

    init() {
        var storedContinuation: AsyncStream<String>.Continuation!
        stream = AsyncStream { storedContinuation = $0 }
        continuation = storedContinuation
    }

    func yield(_ productID: String) {
        continuation.yield(productID)
    }

    func finish() {
        continuation.finish()
    }
}

private actor MockPurchaseClient: SoloPurchaseProviding {
    private let stubbedProducts: [String: SoloStoreProduct]
    private var entitlements: Set<String>
    private let purchaseOutcome: SoloPurchaseOutcome
    private let shouldFailLoad: Bool
    private let shouldFailPurchase: Bool
    private let shouldFailSync: Bool
    nonisolated let transactionStream: MockTransactionStream?

    init(
        products: [SoloStoreProduct],
        entitlements: Set<String>,
        purchaseOutcome: SoloPurchaseOutcome = .success,
        shouldFailLoad: Bool = false,
        shouldFailPurchase: Bool = false,
        shouldFailSync: Bool = false,
        transactionStream: MockTransactionStream? = nil
    ) {
        self.stubbedProducts = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        self.entitlements = entitlements
        self.purchaseOutcome = purchaseOutcome
        self.shouldFailLoad = shouldFailLoad
        self.shouldFailPurchase = shouldFailPurchase
        self.shouldFailSync = shouldFailSync
        self.transactionStream = transactionStream
    }

    func setEntitlements(_ newEntitlements: Set<String>) {
        entitlements = newEntitlements
    }

    func loadProducts(for ids: [String]) async throws -> [SoloStoreProduct] {
        if shouldFailLoad {
            throw MockStoreError.loadFailed
        }
        return ids.compactMap { stubbedProducts[$0] }
    }

    func currentEntitlementProductIDs() async -> Set<String> {
        entitlements
    }

    func purchase(productID: String) async throws -> SoloPurchaseOutcome {
        if shouldFailPurchase {
            throw MockStoreError.purchaseFailed
        }
        if purchaseOutcome == .success {
            entitlements.insert(productID)
        }
        return purchaseOutcome
    }

    func syncPurchases() async throws {
        if shouldFailSync {
            throw MockStoreError.syncFailed
        }
    }

    func processUnfinishedTransactions() async {}

    nonisolated func transactionUpdates() -> AsyncStream<String> {
        if let transactionStream {
            return transactionStream.stream
        }
        return AsyncStream { $0.finish() }
    }
}

private enum MockStoreError: LocalizedError {
    case loadFailed
    case purchaseFailed
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .loadFailed:   return "模拟商品加载失败"
        case .purchaseFailed: return "模拟购买失败"
        case .syncFailed:   return "模拟同步失败"
        }
    }
}

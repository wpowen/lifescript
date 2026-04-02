import Foundation
import Observation
import os
import StoreKit

struct SoloStoreProduct: Equatable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let detail: String
}

enum SoloPurchaseOutcome: Equatable, Sendable {
    case success
    case pending
    case userCancelled
}

protocol SoloPurchaseProviding: Sendable {
    func loadProducts(for ids: [String]) async throws -> [SoloStoreProduct]
    func currentEntitlementProductIDs() async -> Set<String>
    func purchase(productID: String) async throws -> SoloPurchaseOutcome
    func syncPurchases() async throws
    /// 完成之前未正常 finish 的交易（如购买途中 App 崩溃），应在启动时调用
    func processUnfinishedTransactions() async
    /// 实时交易更新流：Ask-to-Buy 审批、外部设备购买同步、退款等
    nonisolated func transactionUpdates() -> AsyncStream<String>
}

// MARK: - StoreKit 2 Implementation

actor StoreKitPurchaseClient: SoloPurchaseProviding {
    private var cachedProducts: [String: Product] = [:]

    func loadProducts(for ids: [String]) async throws -> [SoloStoreProduct] {
        let products = try await productsForIDs(ids)
        return ids.compactMap { id in
            guard let product = products[id] else { return nil }
            return SoloStoreProduct(
                id: product.id,
                displayName: product.displayName,
                displayPrice: product.displayPrice,
                detail: product.description
            )
        }
    }

    func currentEntitlementProductIDs() async -> Set<String> {
        var productIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            productIDs.insert(transaction.productID)
        }

        return productIDs
    }

    func purchase(productID: String) async throws -> SoloPurchaseOutcome {
        let products = try await productsForIDs([productID])
        guard let product = products[productID] else {
            throw SoloStoreKitError.productNotFound(productID)
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            await transaction.finish()
            return .success
        case .pending:
            return .pending
        case .userCancelled:
            return .userCancelled
        @unknown default:
            return .pending
        }
    }

    func syncPurchases() async throws {
        try await AppStore.sync()
    }

    func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
        }
    }

    nonisolated func transactionUpdates() -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    guard case .verified(let transaction) = result else { continue }
                    await transaction.finish()
                    continuation.yield(transaction.productID)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Private Helpers

    private func productsForIDs(_ ids: [String]) async throws -> [String: Product] {
        let missingIDs = ids.filter { cachedProducts[$0] == nil }
        if !missingIDs.isEmpty {
            let loadedProducts = try await Product.products(for: missingIDs)
            for product in loadedProducts {
                cachedProducts[product.id] = product
            }
        }

        return cachedProducts.filter { ids.contains($0.key) }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw SoloStoreKitError.unverifiedTransaction
        }
    }
}

// MARK: - Errors

enum SoloStoreKitError: LocalizedError {
    case productNotFound(String)
    case unverifiedTransaction

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return SoloLocalization.localized("当前卷商品还没有在 App Store Connect 配好，请先补齐内购商品。")
        case .unverifiedTransaction:
            return SoloLocalization.localized("交易校验失败，本次解锁没有生效。")
        }
    }
}

// MARK: - Volume Store

@MainActor
@Observable
final class SoloVolumeStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
    }

    let storyId: String

    private let purchaseClient: SoloPurchaseProviding

    private(set) var loadState: LoadState = .idle
    private(set) var productsByID: [String: SoloStoreProduct] = [:]
    private(set) var unlockedProductIDs: Set<String> = []
    private(set) var activePurchaseProductID: String?
    private(set) var isRestoring: Bool = false
    private(set) var statusMessage: String?

    var isOperationInProgress: Bool {
        activePurchaseProductID != nil || isRestoring
    }

    @ObservationIgnored
    private var transactionListenerTask: Task<Void, Never>?

    init(
        storyId: String = SoloStoryConfig.storyId,
        purchaseClient: SoloPurchaseProviding = StoreKitPurchaseClient()
    ) {
        self.storyId = storyId
        self.purchaseClient = purchaseClient
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    var plans: [SoloVolumePlan] {
        SoloVolumeCatalog.plans(for: storyId)
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await reload()
    }

    func reload() async {
        loadState = .loading
        statusMessage = nil

        await purchaseClient.processUnfinishedTransactions()

        let productIDs = plans.compactMap(\.productID)

        if !productIDs.isEmpty {
            do {
                let products = try await purchaseClient.loadProducts(for: productIDs)
                productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            } catch {
                productsByID = [:]
                statusMessage = SoloLocalization.localized("商品信息暂时没有同步成功，先按预设价格展示。")
            }
        }

        await refreshEntitlements()
        startTransactionListenerIfNeeded()
        loadState = .ready
    }

    // MARK: - Access State

    func chapterAccessState(chapterId: String, chapterNumber: Int) -> SoloChapterAccessState {
        guard let lockedVolume = lockedVolume(for: chapterNumber) else {
            return SoloChapterAccessState(
                chapterId: chapterId,
                isLocked: false,
                volume: SoloVolumeCatalog.volume(for: storyId, chapterNumber: chapterNumber),
                primaryActionTitle: "",
                supportingLine: nil
            )
        }

        return SoloChapterAccessState(
            chapterId: chapterId,
            isLocked: true,
            volume: lockedVolume,
            primaryActionTitle: SoloLocalization.format(
                "解锁%@ · %@",
                lockedVolume.shortTitle,
                displayPrice(for: lockedVolume)
            ),
            supportingLine: lockedVolume.localizedTeaser
        )
    }

    func lockedVolume(for chapterNumber: Int) -> SoloVolumePlan? {
        guard let volume = SoloVolumeCatalog.volume(for: storyId, chapterNumber: chapterNumber) else {
            return nil
        }

        return isUnlocked(volume) ? nil : volume
    }

    func isUnlocked(_ volume: SoloVolumePlan) -> Bool {
        guard let productID = volume.productID else { return true }
        return unlockedProductIDs.contains(productID)
    }

    func displayPrice(for volume: SoloVolumePlan) -> String {
        guard let productID = volume.productID else {
            return volume.fallbackPriceText
        }

        return productsByID[productID]?.displayPrice ?? volume.fallbackPriceText
    }

    // MARK: - Purchase & Restore

    func purchase(_ volume: SoloVolumePlan) async -> Bool {
        guard let productID = volume.productID else { return true }
        guard !isOperationInProgress else { return false }

        activePurchaseProductID = productID
        defer { activePurchaseProductID = nil }

        do {
            if productsByID[productID] == nil {
                let products = try await purchaseClient.loadProducts(for: [productID])
                for product in products {
                    productsByID[product.id] = product
                }
            }

            let outcome = try await purchaseClient.purchase(productID: productID)

            switch outcome {
            case .success:
                // 乐观更新：立即标记为已解锁，确保 UI 即时响应
                // 不再调用 refreshEntitlements()——它会进入 actor 查询
                // Transaction.currentEntitlements，在测试环境中可能 hang
                unlockedProductIDs.insert(productID)
                statusMessage = SoloLocalization.format("已解锁%@，可以继续推进了。", volume.localizedTitle)
                return true
            case .pending:
                statusMessage = SoloLocalization.localized("交易正在等待确认（如家长审批），确认通过后会自动解锁。")
                return false
            case .userCancelled:
                return false
            }
        } catch {
            statusMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async -> Bool {
        guard !isOperationInProgress else { return false }

        isRestoring = true
        defer { isRestoring = false }

        do {
            try await purchaseClient.syncPurchases()
            await refreshEntitlements()
            statusMessage = unlockedProductIDs.isEmpty
                ? SoloLocalization.localized("当前没有可恢复的卷购买记录。")
                : SoloLocalization.localized("购买记录已恢复，可以继续阅读。")
            return true
        } catch {
            statusMessage = SoloLocalization.localized("恢复购买失败，请稍后再试。")
            return false
        }
    }

    func clearStatusMessage() {
        statusMessage = nil
    }

    // MARK: - Private

    private static let logger = Logger(subsystem: "com.lifescript.solo", category: "VolumeStore")

    private func refreshEntitlements() async {
        let latestEntitlements = await withTaskGroup(of: Set<String>.self) { group in
            group.addTask {
                await self.purchaseClient.currentEntitlementProductIDs()
            }
            // 5 秒超时保护：防止 Transaction.currentEntitlements 在测试环境中 hang
            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return Set<String>()
            }
            let first = await group.next() ?? []
            group.cancelAll()
            return first
        }
        let previousCount = unlockedProductIDs.count
        // 使用 formUnion 合并，而非覆盖——防止超时时丢失乐观插入的 productID
        unlockedProductIDs.formUnion(latestEntitlements)
        Self.logger.info(
            "Entitlements refreshed: \(self.unlockedProductIDs.count) unlocked (was \(previousCount))"
        )
    }

    /// 监听 StoreKit 实时交易更新，收到变更后自动刷新权益
    private func startTransactionListenerIfNeeded() {
        guard transactionListenerTask == nil else { return }
        let stream = purchaseClient.transactionUpdates()
        transactionListenerTask = Task { [weak self] in
            for await _ in stream {
                guard !Task.isCancelled else { break }
                await self?.refreshEntitlements()
            }
        }
    }
}

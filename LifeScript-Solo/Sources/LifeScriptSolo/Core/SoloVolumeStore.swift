import Foundation
import Observation
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
}

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

enum SoloStoreKitError: LocalizedError {
    case productNotFound(String)
    case unverifiedTransaction

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "当前卷商品还没有在 App Store Connect 配好，请先补齐内购商品。"
        case .unverifiedTransaction:
            return "交易校验失败，本次解锁没有生效。"
        }
    }
}

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
    private(set) var statusMessage: String?

    init(
        storyId: String = SoloStoryConfig.storyId,
        purchaseClient: SoloPurchaseProviding = StoreKitPurchaseClient()
    ) {
        self.storyId = storyId
        self.purchaseClient = purchaseClient
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

        let productIDs = plans.compactMap(\.productID)

        if !productIDs.isEmpty {
            do {
                let products = try await purchaseClient.loadProducts(for: productIDs)
                productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            } catch {
                productsByID = [:]
                statusMessage = "商品信息暂时没有同步成功，先按预设价格展示。"
            }
        }

        await refreshEntitlements()
        loadState = .ready
    }

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
            primaryActionTitle: "解锁\(lockedVolume.shortTitle) · \(displayPrice(for: lockedVolume))",
            supportingLine: lockedVolume.teaser
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

    func purchase(_ volume: SoloVolumePlan) async -> Bool {
        guard let productID = volume.productID else { return true }

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
                await refreshEntitlements()
                statusMessage = "已解锁\(volume.title)，可以继续推进了。"
                return true
            case .pending:
                statusMessage = "交易正在等待确认，确认完成后会自动解锁。"
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
        do {
            try await purchaseClient.syncPurchases()
            await refreshEntitlements()
            statusMessage = unlockedProductIDs.isEmpty
                ? "当前没有可恢复的卷购买记录。"
                : "购买记录已恢复，可以继续阅读。"
            return true
        } catch {
            statusMessage = "恢复购买失败，请稍后再试。"
            return false
        }
    }

    func clearStatusMessage() {
        statusMessage = nil
    }

    private func refreshEntitlements() async {
        let latestEntitlements = await purchaseClient.currentEntitlementProductIDs()
        unlockedProductIDs = latestEntitlements
    }
}

import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class SubscriptionManager {
    enum Status: Equatable {
        case unknown
        case free
        case premium(expiresAt: Date?)
        case expired
        case error(String)
    }

    let productIDs: Set<String>
    private(set) var products: [Product] = []
    private(set) var status: Status = .unknown
    private nonisolated(unsafe) var transactionListener: Task<Void, Never>?

    init(productIDs: Set<String>) {
        self.productIDs = productIDs
        let listener = listenForTransactions()
        transactionListener = listener
        Task { await refreshStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            self.products = storeProducts.sorted { $0.price < $1.price }
            AppLogger.subscription.info("Loaded \(self.products.count) products")
        } catch {
            AppLogger.subscription.error("Failed to load products: \(error.localizedDescription)")
            self.status = .error("Не удалось загрузить тарифы")
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshStatus()
                await transaction.finish()
            case .userCancelled:
                AppLogger.subscription.notice("Purchase cancelled")
            case .pending:
                AppLogger.subscription.notice("Purchase pending")
            @unknown default:
                break
            }
        } catch {
            AppLogger.subscription.error("Purchase failed: \(error.localizedDescription)")
            self.status = .error(AppError.subscriptionFailed.localizedDescription)
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshStatus()
        } catch {
            AppLogger.subscription.error("Restore failed: \(error.localizedDescription)")
        }
    }

    func refreshStatus() async {
        var latestExpiration: Date?
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                hasEntitlement = true
                if let expires = transaction.expirationDate {
                    if latestExpiration == nil || expires > latestExpiration! {
                        latestExpiration = expires
                    }
                }
            }
        }
        if hasEntitlement {
            if let exp = latestExpiration, exp < Date() {
                status = .expired
            } else {
                status = .premium(expiresAt: latestExpiration)
            }
        } else {
            status = .free
        }
    }

    var isPremium: Bool {
        if case .premium = status { return true }
        return false
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshStatus()
                }
            }
        }
    }
}

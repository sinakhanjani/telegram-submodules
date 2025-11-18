import Foundation
import StoreKit

public enum StoreKitClientError: Error {
    case productNotFound(String)
    case purchaseCancelled
}

// Wrapper for purchase result
@available(iOS 15.0, *)
public struct StoreKitPurchaseResult {
    public let transaction: Transaction
    public let jwsRepresentation: String
}

@available(iOS 15.0, *)
/// Simple StoreKit 2 client for fetching products & performing purchases
public final class StoreKitClient {
    private var updatesListenerTask: Task<Void, Never>?
    
    public var onTransactionUpdate: ((Transaction) -> Void)?
    
    public init() {
        startListeningForTransactionUpdates()
    }
    
    // Fetch products by identifiers
    public func fetchProducts(identifiers: [String]) async throws -> [Product] {
        // Ask StoreKit for Product metadata (price, displayName, type, etc.)
        let storeProducts = try await Product.products(for: identifiers)
        return storeProducts
    }
    
    @available(iOS 15.0, *)
    public func hasActiveStoreKitSubscription(for appleProductId: String) async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {

                if transaction.productID == appleProductId {
                    let isExpired = transaction.expirationDate.map { $0 < Date() } ?? false
                    if !isExpired && transaction.revocationDate == nil {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    // Purchase a single product
    @MainActor
    public func purchase(_ product: Product, appAccountToken: UUID) async throws -> StoreKitPurchaseResult {
        let result = try await product.purchase(options: [.appAccountToken(appAccountToken)])

        switch result {
        case .success(let verification):
            // Take JWS from verification result
            let jws = verification.jwsRepresentation
            
            // Verify transaction signature (StoreKit-level)
            let transaction = try checkVerified(verification)
            
            // ⚠️ DO NOT finish here.
            // Caller should call transaction.finish() AFTER backend verification succeeds.
            return StoreKitPurchaseResult(transaction: transaction, jwsRepresentation: jws)
            
        case .userCancelled:
            throw StoreKitClientError.purchaseCancelled
            
        case .pending:
            // Pending until SCA/approval—handle if you want to show UI state
            throw StoreKitClientError.purchaseCancelled
            
        @unknown default:
            throw StoreKitClientError.purchaseCancelled
        }
    }
    
    // Restore purchases
    public func restorePurchases() async {
        try? await AppStore.sync()
    }
    
    // Verify using StoreKit 2 VerificationResult
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let signedType):
            return signedType
        }
    }
    
    // MARK: - Transaction Updates Listener
    private func startListeningForTransactionUpdates() {
        // Keep a single long-lived task to avoid missing purchases.
        updatesListenerTask?.cancel()
        updatesListenerTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self = self else { continue }
                do {
                    let transaction = try self.checkVerified(update)
                    // Notify observer if any (app can verify with backend here).
                    self.onTransactionUpdate?(transaction)
                    // Minimal default handling: finish to avoid duplicate deliveries.
                    await transaction.finish()
                } catch {
                    // Ignore unverified updates; nothing to finish.
                    #if DEBUG
                    print("[StoreKitClient] Unverified transaction update: \(error)")
                    #endif
                }
            }
        }
    }
}

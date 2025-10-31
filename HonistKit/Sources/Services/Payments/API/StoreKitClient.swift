import Foundation
import StoreKit

public enum StoreKitClientError: Error {
    case productNotFound(String)
    case purchaseCancelled
}

/// Simple StoreKit 2 client for fetching products & performing purchases
public final class StoreKitClient {
    public init() {}

    // Fetch products by identifiers
    @available(iOS 15.0, *)
    public func fetchProducts(identifiers: [String]) async throws -> [Product] {
        // Ask StoreKit for Product metadata (price, displayName, type, etc.)
        let storeProducts = try await Product.products(for: identifiers)
        return storeProducts
    }

    // Purchase a single product
    @available(iOS 15.0, *)
    @MainActor
    public func purchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            // Verify transaction signature
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction

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
        if #available(iOS 15.0, *) {
            try? await AppStore.sync()
        } else {
            // Fallback on earlier versions
        }
    }

    // Verify using StoreKit 2 VerificationResult
    @available(iOS 15.0, *)
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let signedType):
            return signedType
        }
    }
}

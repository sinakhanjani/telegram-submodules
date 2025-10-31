import Foundation
import StoreKit

public final class PurchasesLogic {
    private let sk = StoreKitClient()

    public init() {}

    /// Example: fetch all products we currently support
    @available(iOS 15.0, *)
    public func fetchAllProducts() async throws -> [Product] {
        let ids: [String] = [
            PaymentProductIDs.gems110,
            PaymentProductIDs.gems400,
            PaymentProductIDs.gems1300,
            PaymentProductIDs.subsGems50Monthly,
            PaymentProductIDs.subsGems100Monthly,
            PaymentProductIDs.unlimitedMonthly,
            PaymentProductIDs.unlimitedYearly
        ]
        return try await sk.fetchProducts(identifiers: ids)
    }
}

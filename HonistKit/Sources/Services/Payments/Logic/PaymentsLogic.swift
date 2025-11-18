import Foundation
import HonistFoundation
import HonistNetworking
import HonistModels

/// High-level payments logic for the app:
/// - Fetches and caches products
/// - Creates subscription orders
/// - Verifies Apple IAP transactions with backend
/// - Fetches and caches current user subscription
///
/// This layer is intentionally independent from StoreKit.
/// UI / StoreKit integration should use this logic as a pure networking + state facade.
public final class PaymentsLogic {

    // MARK: - Dependencies

    private let api: PaymentsAPI

    // MARK: - In-memory state

    /// Last fetched list of products (for the current filters).
    public private(set) var cachedProducts: [ProductDTO] = []

    /// Pagination info for the last product fetch (if any).
    public private(set) var productsPagination: Pagination?

    /// Last known user subscription (from `/app/subscriptions/me/latest`).
    public private(set) var currentSubscription: UserSubscriptionDTO?

    /// Last created order (e.g., for the last purchase attempt).
    public private(set) var lastCreatedOrder: SubscriptionOrderDTO?

    // MARK: - Init

    public init(api: PaymentsAPI = PaymentsAPI()) {
        self.api = api
    }

    // MARK: - Products

    /// Fetches products from backend and updates local cache.
    /// - Parameters:
    ///   - status: Optional status filter (e.g. "active").
    ///   - search: Optional search term.
    ///   - type: Optional product type filter.
    ///   - period: Optional period filter.
    ///   - page: Page index (1-based).
    ///   - limit: Page size.
    /// - Returns: `ListPayload<ProductDTO>` including items + pagination.
    @discardableResult
    public func fetchProducts(
        status: String? = "active",
        search: String? = nil,
        type: String? = nil,
        period: String? = nil,
        page: Int = 1,
        limit: Int = 100
    ) async throws -> ListPayload<ProductDTO> {
        let payload = try await api.fetchProducts(
            status: status,
            search: search,
            type: type,
            period: period,
            page: page,
            limit: limit
        )

        // Update in-memory cache
        cachedProducts = payload.items
        productsPagination = payload.pagination

        return payload
    }

    /// Convenience accessor to get a specific product by id from cache.
    /// Returns `nil` if not found or cache is empty.
    public func product(withId id: String) -> ProductDTO? {
        return cachedProducts.first(where: { $0.id == id })
    }

    // MARK: - Orders

    /// Creates a new subscription order for a given Apple product identifier.
    /// - Parameters:
    ///   - appleProductId: The Apple IAP product identifier (e.g. bundleId + ".subs.gems50.monthly").
    ///   - provider: Defaults to `"apple_iap"`.
    /// - Returns: Newly created `SubscriptionOrderDTO` (usually with status "pending").
    @discardableResult
    public func createOrder(
        appleProductId: String,
        provider: String = "apple_iap"
    ) async throws -> SubscriptionOrderDTO {
        let body = CreateOrderRequest(
            appleProductId: appleProductId,
            provider: provider
        )

        let order = try await api.createOrder(body)
        lastCreatedOrder = order
        return order
    }

    // MARK: - Apple verification

    /// Verifies an Apple IAP transaction against backend.
    ///
    /// This should be called *after* StoreKit has returned a successful purchase
    /// and you have the signed transaction JWS (and optionally renewal JWS / receipt).
    ///
    /// - Parameter request: `AppleVerifyRequest` containing order id + Apple transaction details.
    /// - Returns: `AppleVerifyResultDTO` with status such as "verified".
    @discardableResult
    public func verifyAppleOrder(
        _ request: AppleVerifyRequest
    ) async throws -> AppleVerifyResultDTO {
        let result = try await api.verifyAppleOrder(request)

        // If verification succeeds and backend associates it with a subscription,
        // the subscription state might have changed. We can optionally refresh
        // the current subscription here, but to keep this logic predictable,
        // we leave that decision to the caller.
        return result
    }

    // MARK: - Current subscription

    /// Fetches the user's latest subscription from backend and updates local cache.
    /// - Returns: `UserSubscriptionDTO` if backend responds with a subscription.
    @discardableResult
    public func refreshCurrentSubscription() async throws -> UserSubscriptionDTO {
        let sub = try await api.fetchCurrentSubscription()
        currentSubscription = sub
        return sub
    }

    /// Returns `true` if we have a cached subscription and it looks active
    /// based on the `status` field and the current period end date.
    public func hasActiveSubscription(now: Date = Date()) -> Bool {
        guard let sub = currentSubscription else {
            return false
        }

        // Basic heuristic:
        // - status is "active"
        // - currentPeriodEnd is in the future
        let isStatusActive = sub.status.lowercased() == "active"
        let isWithinPeriod = sub.currentPeriodEnd > now
        return isStatusActive && isWithinPeriod
    }

    /// Human-friendly remaining days in the current period, if any.
    /// Returns `nil` if there is no cached subscription.
    public func remainingDaysInCurrentPeriod(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        guard let sub = currentSubscription else {
            return nil
        }

        let comps = calendar.dateComponents([.day], from: now, to: sub.currentPeriodEnd)
        return comps.day
    }

    // MARK: - Reset helpers

    /// Clears only cached products and pagination.
    public func clearProductsCache() {
        cachedProducts = []
        productsPagination = nil
    }

    /// Clears subscription-related cached state.
    public func clearSubscriptionCache() {
        currentSubscription = nil
    }

    /// Clears all in-memory caches (products, subscription, last order).
    public func clearAllCaches() {
        cachedProducts = []
        productsPagination = nil
        currentSubscription = nil
        lastCreatedOrder = nil
    }
}

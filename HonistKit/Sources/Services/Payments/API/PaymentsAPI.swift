import Foundation
import HonistCore
import HonistNetworking
import HonistModels
import HonistFoundation

/// Payments API wrapper for subscription products, orders and Apple IAP verification.
public struct PaymentsAPI {

    // MARK: - Config

    public struct Config {
        public let hmacSecret: String

        public init(hmacSecret: String) {
            self.hmacSecret = hmacSecret
        }
    }

    // MARK: - Dependencies

    private let client: HonistApiClient
    private let config: Config

    /// Dedicated encoder to ensure we sign the same JSON bytes that are sent over the wire.
    private static func makeEncoder() -> JSONEncoder {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        if #available(iOS 11.0, *) {
            enc.dateEncodingStrategy = .iso8601
        }
        return enc
    }

    private let encoder: JSONEncoder = PaymentsAPI.makeEncoder()

    // MARK: - Init

    public init(
        client: HonistApiClient = HonistRegistry.shared.apiClient,
        config: Config = .init(hmacSecret: AppEnvironment.hmacSecret)
    ) {
        self.client = client
        self.config = config
    }

    // MARK: - HMAC header helper

    /// Computes `x-hmac-signature` over the raw JSON body (or empty data for GETs).
    private func hmacHeader<T: Encodable>(for body: T?) throws -> [String: String] {
        let data: Data
        if let b = body {
            data = try encoder.encode(b)
        } else {
            data = Data()
        }

        // Uses shared HMAC utility (should live in a low-level module like HonistFoundation / HonistCore).
        let signature = HMAC.sha256Hex(data: data, secret: config.hmacSecret)
        return ["x-hmac-signature": signature]
    }

    // MARK: - Endpoints

    // 1) POST /app/subscriptions/orders  (create order)

    /// Creates an order for an Apple IAP product.
    /// - Parameter body: Contains `appleProductId` and `provider` (usually `"apple_iap"`).
    /// - Returns: Newly created `SubscriptionOrderDTO` with status such as `pending`.
    public func createOrder(_ body: CreateOrderRequest) async throws -> SubscriptionOrderDTO {
        let headers = try hmacHeader(for: body)
        return try await client.post("/api/v1/app/subscriptions/orders", body: body, headers: headers)
    }

    // 2) POST /app/iap/apple/verify  (verify order)

    /// Verifies an Apple IAP transaction with backend.
    /// - Important: `originalTxnId` and `expiresDate` may be `nil`.
    /// - `environment` must be `"Sandbox"` or `"Production"`.
    public func verifyAppleOrder(_ body: AppleVerifyRequest) async throws -> AppleVerifyResultDTO {
        let headers = try hmacHeader(for: body)
        return try await client.post("/api/v1/app/iap/apple/verify", body: body, headers: headers)
    }

    // 3) GET /app/subscriptions/me/latest  (current subscription)

    /// Fetches the user's latest subscription (if any).
    /// - Returns: `UserSubscriptionDTO` if active/recent subscription exists.
    /// - Throws: `HonistError` if network/server issues occur or user has no subscription
    ///           and backend responds with non-success status.
    public func fetchCurrentSubscription() async throws -> UserSubscriptionDTO {
        let headers = try hmacHeader(for: Optional<String>.none) // empty body for signing
        return try await client.get("/api/v1/app/subscriptions/me/latest", headers: headers)
    }

    // 4) GET /app/products  (list products with optional filters and pagination)

    /// Fetches available products with optional filters and pagination support.
    /// - Parameters:
    ///   - status: Optional status filter, e.g. `"active"` or `"deactive"`.
    ///   - search: Optional search term for title/subject.
    ///   - type: Optional type filter, e.g. `"subscription_quota"`, `"subscription_unlimited"`, `"one_time_pack"`.
    ///   - period: Optional period filter, e.g. `"none"`, `"weekly"`, `"annually"`.
    ///   - page: Page index (1-based).
    ///   - limit: Page size.
    /// - Returns: `ListPayload<ProductDTO>` including `items` and optional `pagination`.
    public func fetchProducts(
        status: String? = nil,
        search: String? = nil,
        type: String? = nil,
        period: String? = nil,
        page: Int = 1,
        limit: Int = 100
    ) async throws -> ListPayload<ProductDTO> {
        var query: [String: CustomStringConvertible] = [
            "page": page,
            "limit": limit
        ]

        if let status {
            query["status"] = status
        }
        if let search {
            query["search"] = search
        }
        if let type {
            query["type"] = type
        }
        if let period {
            query["period"] = period
        }

        let headers = try hmacHeader(for: Optional<String>.none) // GET with empty body
        return try await client.getList(
            "/api/v1/app/products",
            query: query,
            headers: headers
        )
    }
}

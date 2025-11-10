import Foundation
import HonistCore
import HonistNetworking
import HonistModels
import HonistFoundation

public struct AuthenticationAPI {
    public struct Config {
        public let hmacSecret: String
        public init(hmacSecret: String) { self.hmacSecret = hmacSecret }
    }

    private let client: HonistApiClient
    private let config: Config

    // We need a compatible JSONEncoder to ensure body bytes match the client's encoding for signing.
    private static func makeEncoder() -> JSONEncoder {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        if #available(iOS 11.0, *) { enc.dateEncodingStrategy = .iso8601 }
        return enc
    }

    private let encoder: JSONEncoder = AuthenticationAPI.makeEncoder()

    public init(client: HonistApiClient = HonistRegistry.shared.apiClient, config: Config) {
        self.client = client
        self.config = config
    }

    /// Computes x-hmac-signature over the raw JSON body (or empty body for GET/empty POST)
    private func hmacHeader<T: Encodable>(for body: T?) throws -> [String: String] {
        let data: Data
        if let b = body {
            data = try encoder.encode(b)
        } else {
            data = Data()
        }
        let signature = HMAC.sha256Hex(data: data, secret: config.hmacSecret)
        return ["x-hmac-signature": signature]
    }

    // MARK: - Endpoints

    /// POST /app/auth/login
    public func login(_ body: LoginRequest) async throws -> AuthResultDTO {
        let headers = try hmacHeader(for: body)
        return try await client.post("/api/v1/app/auth/login", body: body, headers: headers)
    }

    /// POST /app/auth/refresh
    public func refresh(_ refreshToken: String) async throws -> TokenPairDTO {
        let body = RefreshRequest(refreshToken: refreshToken)
        let headers = try hmacHeader(for: body)
        return try await client.post("/api/v1/app/auth/refresh", body: body, headers: headers)
    }

    /// POST /app/auth/logout (current session)
    public func logoutCurrent(refreshToken: String) async throws -> EmptyDTO {
        let body = LogoutRequest(refreshToken: refreshToken)
        let headers = try hmacHeader(for: body)
        return try await client.post("/api/v1/app/auth/logout", body: body, headers: headers)
    }

    /// POST /app/auth/logout-all (Bearer required, empty body)
    public func logoutAll() async throws -> EmptyDTO {
        let headers = try hmacHeader(for: Optional<String>.none) // empty body
        // Empty body → send EmptyDTO() so Content-Type remains JSON, or switch to DELETE if server supports
        struct EmptyBody: Encodable {}
        return try await client.post("/api/v1/app/auth/logout-all", body: EmptyBody(), headers: headers)
    }

    /// GET /app/auth/me (Bearer required)
    public func me() async throws -> UserDTO {
        let headers = try hmacHeader(for: Optional<String>.none) // empty body
        return try await client.get("/api/v1/app/auth/me", headers: headers)
    }
}

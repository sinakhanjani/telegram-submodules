import Foundation
import HonistFoundation
import HonistStorage
import HonistNetworking

/// Central logic for authentication flows:
/// - Stores tokens (Keychain-backed)
/// - Performs login/refresh/logout flows
/// - Caches current user (from /me or login response)
/// - Implements `TokenRefresher` so the HTTP client can:
///    a) eagerly refresh before protected requests,
///    b) attempt a one-time refresh + retry on 401.
public final class AuthLogic {
    private let store: TokenStoreType
    private let api: AuthenticationAPI
    private let coordinator = RefreshCoordinator() // serializes refresh attempts
    private var _currentUser: UserDTO?

    public init(store: TokenStoreType = TokenStore(),
                api: AuthenticationAPI) {
        self.store = store
        self.api = api
    }

    // MARK: - Expose provider for clients (optional helper)

    /// Returns a provider that reads tokens from the same store.
    /// Pass it to `HonistApiClient(tokenProvider:)` when building clients.
    public func makeTokenProvider() -> AuthTokenProvider {
        return AuthTokenProviderAdapter(store: store)
    }

    // MARK: - Token state

    /// Latest access token (if any) – read-only
    public var accessToken: String? { store.accessToken }

    /// Latest refresh token (if any) – read-only
    public var refreshToken: String? { store.refreshToken }

    /// Last fetched user object (cached in memory)
    public var currentUser: UserDTO? { _currentUser }

    /// Checks if the access token is expired (or near expiry) using `exp` claim.
    /// - Parameter skew: Seconds of clock skew to consider (default 30s).
    public func isAccessTokenExpired(skew: TimeInterval = 30) -> Bool {
        guard let at = store.accessToken else { return true }
        return JWT.isExpired(at, skew: skew)
    }

    // MARK: - Flows

    /// Login/Register → stores tokens + returns user.
    /// - After success, `_currentUser` is updated.
    public func login(request: LoginRequest) async throws -> UserDTO {
        let result = try await api.login(request)
        store.accessToken = result.accessToken
        store.refreshToken = result.refreshToken
        _currentUser = result.user
        return result.user
    }

    /// Refresh tokens only if needed (based on `exp`).
    /// - Returns `true` if a refresh actually happened.
    @discardableResult
    public func refreshIfNeeded() async throws -> Bool {
        if isAccessTokenExpired() {
            return try await refreshNow()
        }
        return false
    }

    /// Force-refresh tokens using the current refresh token.
    /// - Returns `true` if tokens were updated.
    @discardableResult
    public func refreshNow() async throws -> Bool {
        guard let rt = store.refreshToken, !rt.isEmpty else {
            throw HonistError.unauthorized
        }
        let pair = try await api.refresh(rt)
        store.accessToken = pair.accessToken
        store.refreshToken = pair.refreshToken
        return true
    }

    /// Logout only current session.
    /// - Clears tokens and in-memory user cache.
    public func logoutCurrentSession() async throws {
        guard let rt = store.refreshToken else { return }
        _ = try await api.logoutCurrent(refreshToken: rt)
        store.clearAll()
        _currentUser = nil
    }

    /// Logout all sessions (Bearer required).
    /// - Clears tokens and in-memory user cache.
    public func logoutAllSessions() async throws {
        _ = try await api.logoutAll()
        store.clearAll()
        _currentUser = nil
    }

    /// Convenience: fetch `/me` with auto refresh if access token is expired.
    /// - Updates `_currentUser` on success.
    public func meWithAutoRefresh() async throws -> UserDTO {
        if isAccessTokenExpired() {
            _ = try await refreshIfNeeded()
        }
        let user = try await api.me()
        _currentUser = user
        return user
    }
}

// MARK: - TokenRefresher conformance
extension AuthLogic: TokenRefresher {

    /// Called by the HTTP client *before* protected requests.
    /// If the access token is expired (or about to), perform a single serialized refresh.
    public func ensureValidAccessTokenIfNeeded() async throws {
        if isAccessTokenExpired() {
            _ = try await coordinator.run { [weak self] in
                guard let self = self else { return false }
                return try await self.refreshIfNeeded()
            }
        }
    }

    /// Called by the HTTP client after receiving a 401.
    /// Attempts a single serialized refresh and returns whether the request should be retried.
    public func refreshAfterUnauthorized() async throws -> Bool {
        return try await coordinator.run { [weak self] in
            guard let self = self else { return false }
            return try await self.refreshNow()
        }
    }
}

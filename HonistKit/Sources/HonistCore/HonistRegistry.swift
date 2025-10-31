import Foundation
import HonistFoundation
import HonistNetworking
import HonistStorage

/// Global registry providing shared API client, token store, and provider.
/// This lives in HonistCore (above Foundation) to avoid circular dependencies.
/// Other services (Auth, Profile, Payments, etc.) can all use this shared registry.
public final class HonistRegistry {
    
    // MARK: - Singleton
    public static let shared = HonistRegistry()
    private init() {}
    
    // MARK: - Shared primitives
    
    /// Shared Keychain-backed token store (accessible to all services)
    public let tokenStore = TokenStore()
    
    /// Shared token provider adapter that reads from the same store
    public lazy var tokenProvider: AuthTokenProvider = {
        AuthTokenProviderAdapter(store: tokenStore)
    }()
    
    /// Shared HTTP client — initially without refresher; Auth will register it later.
    public private(set) lazy var apiClient: HonistApiClient = {
        HonistApiClient(
            tokenProvider: tokenProvider,
            options: .init(debugLogging: true),
            tokenRefresher: nil
        )
    }()
    
    // MARK: - TokenRefresher registration (used by AuthLogic)
    
    /// Injects a global TokenRefresher (AuthLogic) to handle:
    /// - Eager refresh before protected requests
    /// - One-time refresh + retry on 401
    public func registerTokenRefresher(_ refresher: TokenRefresher) {
        // rebuild client but reuse same tokenProvider
        self.apiClient = HonistApiClient(
            tokenProvider: tokenProvider,
            options: .init(debugLogging: true),
            tokenRefresher: refresher
        )
    }
}

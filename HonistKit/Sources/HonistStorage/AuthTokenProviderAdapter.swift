import Foundation
import HonistFoundation   // For AuthTokenProvider
// This file lives in HonistStorage module, so it can see TokenStoreType directly.

public final class AuthTokenProviderAdapter: AuthTokenProvider {
    private let store: TokenStoreType
    public init(store: TokenStoreType) { self.store = store }
    
    public var accessToken: String? { store.accessToken }
    public var refreshToken: String? { store.refreshToken }
}

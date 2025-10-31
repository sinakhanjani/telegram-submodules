import Foundation

/// A lightweight contract that lets the HTTP client ensure valid access tokens
/// before requests, and try a one-time refresh on 401.
public protocol TokenRefresher: AnyObject {
    /// Called before each protected request to eagerly refresh if needed.
    func ensureValidAccessTokenIfNeeded() async throws

    /// Called after receiving a 401 to attempt a refresh and indicate whether a retry should happen.
    func refreshAfterUnauthorized() async throws -> Bool
}

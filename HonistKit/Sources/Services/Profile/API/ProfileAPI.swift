import Foundation
import HonistNetworking
import HonistModels

public struct ProfileAPI {
    // Keep a reference to the shared API client
    public let client: HonistApiClient

    // Allow dependency injection for testing or custom configuration
    public init(client: HonistApiClient = .init()) {
        self.client = client
    }

    /// Fetch the current user's profile.
    /// The client already unwraps the server envelope (success/data/message),
    /// so we decode `UserProfileDTO` directly.
    public func fetchMe() async throws -> UserProfileDTO {
        // Prefer a leading slash to build a proper URL relative to baseURL
        try await client.get("/v1/profile/me")
    }
}

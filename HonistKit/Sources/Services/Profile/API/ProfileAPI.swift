import Foundation
import HonistCore
import HonistNetworking
import HonistModels
import HonistFoundation
import HonistService_Auth

public struct ProfileAPI {
    private let client: HonistApiClient
    
    public init(client: HonistApiClient = HonistRegistry.shared.apiClient) {
        self.client = client
    }
    
    private let encoder: JSONEncoder = ProfileAPI.makeEncoder()
    
    // We need a compatible JSONEncoder to ensure body bytes match the client's encoding for signing.
    private static func makeEncoder() -> JSONEncoder {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        if #available(iOS 11.0, *) { enc.dateEncodingStrategy = .iso8601 }
        return enc
    }
    
    /// Computes x-hmac-signature over the raw JSON body (or empty body for GET/empty POST)
    private func hmacHeader<T: Encodable>(for body: T?) throws -> [String: String] {
        let data: Data
        if let b = body {
            data = try encoder.encode(b)
        } else {
            data = Data()
        }
        let signature = HMAC.sha256Hex(data: data, secret: AppEnvironment.hmacSecret)
        return ["x-hmac-signature": signature]
    }
    
    // MARK: - Referral
    
    /// POST /app/profile/referral
    /// Sends user's referral code to bind referrer.
    public func addReferral(code: String) async throws -> ReferralBindResultDTO {
        let body = AddReferralBody(referralCode: code)
        let headers = try hmacHeader(for: body)
        
        return try await client.post("/api/v1/app/profile/referral", body: body, headers: headers)
    }
    
    // MARK: - Referrals

    /// GET /app/profile/referrals?page=&limit=
    /// Returns paginated list of invitees (referrals).
    public func referrals(
        page: Int = 1,
        limit: Int = 1000
    ) async throws -> ListPayload<ReferralDTO> {
        let query: [String: CustomStringConvertible] = [
            "page": page,
            "limit": limit
        ]
        return try await client.getList("/api/v1/app/profile/referrals", query: query)
    }

    
    
    // MARK: - Upload photo
    
    /// POST /app/profile/photo
    /// Multipart upload for profile photo.
    /// - Parameters:
    ///   - imageData: JPEG or PNG image data.
    ///   - fileName: File name to send (e.g. "avatar.jpg").
    ///   - mimeType: MIME type (e.g. "image/jpeg").
    /// - Returns: Updated `UserDTO` from server.
    public func uploadPhoto(
        imageData: Data,
        fileName: String = "photo.jpg",
        mimeType: String = "image/jpeg"
    ) async throws -> UserDTO {
        let parts: [MultipartPart] = [
            .init(
                name: "photo",
                value: .data(imageData, filename: fileName, mimeType: mimeType)
            )
        ]
        
        return try await client.uploadMultipart(
            "/api/v1/app/profile/photo",
            method: .POST,
            parts: parts
        )
    }
    
    // MARK: - Update name
    
    /// PATCH /app/profile/name
    /// Updates first and last name of the current user.
    /// - Returns: Updated `UserDTO`.
    public func updateName(
        firstName: String,
        lastName: String
    ) async throws -> UserDTO {
        let body = UpdateNameRequest(firstName: firstName, lastName: lastName)
        return try await client.patch(
            "/api/v1/app/profile/name",
            body: body
        )
    }
    
    // MARK: - Update app status
    
    /// PATCH /app/profile/app-status
    /// Updates app-related status for analytics/usage tracking.
    /// You can call this for example on app launch.
    public func updateAppStatus(
        _ body: UpdateAppStatusRequest
    ) async throws -> UserDTO {
        return try await client.patch(
            "/api/v1/app/profile/app-status",
            body: body
        )
    }
    
    // MARK: - Delete account
    
    /// DELETE /app/profile/delete
    /// Permanently deletes the current account.
    /// - Returns: `DeleteAccountResultDTO` which contains `deleted: Bool`.
    public func deleteAccount() async throws -> DeleteAccountResultDTO {
        return try await client.delete("/api/v1/app/profile/delete")
    }
}

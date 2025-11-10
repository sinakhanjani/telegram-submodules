import Foundation
import HonistFoundation
import HonistModels
import HonistService_Auth

public final class ProfileLogic {
    private let api: ProfileAPI
    
    private var _userAppStatus: UserAppStatusDTO?

    public init(api: ProfileAPI = ProfileAPI()) {
        self.api = api
    }
    
    public var userAppStatus: UserAppStatusDTO? { _userAppStatus }
    
    /// Validate and submit referral code
    /// - Throws: HonistError.* in case of network/server/decoding issues
    @discardableResult
    public func submitReferral(code: String) async throws -> ReferralBindResultDTO {
        // Basic local validation: only lowercase a-z + digits, 4...32 length (adjust if needed)
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        if trimmed.isEmpty || trimmed.count < 4 || trimmed.count > 64 || trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            throw HonistError.server(message: "Invalid referral code.")
        }
        return try await api.addReferral(code: trimmed)
    }
    
    /// Fetch referrals (invitees) for current user.
    /// - Parameters:
    ///   - page: page index (1-based)
    ///   - limit: items per page
    /// - Returns: ListPayload<ReferralDTO> with pagination info.
    public func fetchReferrals(
        page: Int = 1,
        limit: Int = 1000
    ) async throws -> ListPayload<ReferralDTO> {
        return try await api.referrals(page: page, limit: limit)
    }
    
    // MARK: - Update name
    
    /// Updates user's first and last name and refreshes cached profile.
    @discardableResult
    public func updateName(
        firstName: String,
        lastName: String
    ) async throws -> UserDTO {
        let updated = try await api.updateName(firstName: firstName, lastName: lastName)
        
        _ = try await AuthAppServices.shared.authLogic.meWithAutoRefresh()
        
        return updated
    }
    
    // MARK: - Upload photo
    
    /// Uploads a new profile photo and refreshes cached profile.
    @discardableResult
    public func uploadPhoto(
        imageData: Data,
        fileName: String = "photo.jpg",
        mimeType: String = "image/jpeg"
    ) async throws -> UserDTO {
        let updated = try await api.uploadPhoto(
            imageData: imageData,
            fileName: fileName,
            mimeType: mimeType
        )
        
        _ = try await AuthAppServices.shared.authLogic.meWithAutoRefresh()
        
        return updated
    }
    
    // MARK: - App status
    
    /// Updates app status (launch count, last version, country, etc.)
    @discardableResult
    public func updateAppStatus(
        incrementLaunch: Bool? = nil,
        touchLaunch: Bool? = nil,
        lastAppVersion: String? = nil,
        countryIso: String? = nil
    ) async throws -> UserAppStatusDTO {
        let body = UpdateAppStatusRequest(
            incrementLaunch: incrementLaunch,
            touchLaunch: touchLaunch,
            lastAppVersion: lastAppVersion,
            countryIso: countryIso
        )
        let user = try await api.updateAppStatus(body)
        
        _userAppStatus = user.appStatus!
        
        return user.appStatus!
    }
    
    // MARK: - Delete account
    
    /// Deletes the current account. Returns `true` if the server confirmed deletion.
    @discardableResult
    public func deleteAccount() async throws -> Bool {
        let result = try await api.deleteAccount()
        if result.deleted {
            // Clear local cache when account is deleted.
            _ = try await AuthAppServices.shared.authLogic.deleteAccount()
        }
        return result.deleted
    }
}

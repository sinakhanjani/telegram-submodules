import Foundation

/// PATCH /app/profile/name
/// Encodable body for updating user's first and last name.
public struct UpdateNameRequest: Encodable {
    public let firstName: String
    public let lastName: String
    
    public init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}

/// PATCH /app/profile/app-status
/// Encodable body for updating app status.
/// All fields are optional so caller can send only what is needed.
public struct UpdateAppStatusRequest: Encodable {
    public let incrementLaunch: Bool?
    public let touchLaunch: Bool?
    public let lastAppVersion: String?
    public let countryIso: String?
    
    public init(
        incrementLaunch: Bool? = nil,
        touchLaunch: Bool? = nil,
        lastAppVersion: String? = nil,
        countryIso: String? = nil
    ) {
        self.incrementLaunch = incrementLaunch
        self.touchLaunch = touchLaunch
        self.lastAppVersion = lastAppVersion
        self.countryIso = countryIso
    }
}

/// Response `data` from DELETE /app/profile/delete
public struct DeleteAccountResultDTO: Decodable {
    public let deleted: Bool
    
    public init(deleted: Bool) {
        self.deleted = deleted
    }
}

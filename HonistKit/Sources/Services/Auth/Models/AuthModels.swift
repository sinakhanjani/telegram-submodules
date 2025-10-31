import Foundation

public struct LoginRequest: Encodable {
    public let telegramId: String
    public let verificationCode: String?
    public let accessHash: String?
    public let phoneNumber: String?
    public let firstName: String?
    public let lastName: String?
    public let username: String?
    public let languageCode: String?
    public let isPremium: Bool?
    public let isBot: Bool?
    public let status: Status?
    public let verified: Bool?
    public let restricted: Bool?
    public let restrictionReason: String?
    public let twoStepEnabled: Bool?
    public let deviceLabel: String?

    public struct Status: Encodable {
        public let lastSeen: Date?
        public let online: Bool?
        public init(lastSeen: Date?, online: Bool?) { self.lastSeen = lastSeen; self.online = online }
    }

    public init(
        telegramId: String,
        verificationCode: String? = nil,
        accessHash: String? = nil,
        phoneNumber: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        username: String? = nil,
        languageCode: String? = nil,
        isPremium: Bool? = nil,
        isBot: Bool? = nil,
        status: Status? = nil,
        verified: Bool? = nil,
        restricted: Bool? = nil,
        restrictionReason: String? = nil,
        twoStepEnabled: Bool? = nil,
        deviceLabel: String? = nil
    ) {
        self.telegramId = telegramId
        self.verificationCode = verificationCode
        self.accessHash = accessHash
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.languageCode = languageCode
        self.isPremium = isPremium
        self.isBot = isBot
        self.status = status
        self.verified = verified
        self.restricted = restricted
        self.restrictionReason = restrictionReason
        self.twoStepEnabled = twoStepEnabled
        self.deviceLabel = deviceLabel
    }
}

public struct TokenPairDTO: Codable {
    public let accessToken: String
    public let refreshToken: String
}

public struct UserAppStatusDTO: Codable {
    public let id: String
    public let userId: String
    public let appLaunchCount: Int
    public let lastLaunchAt: Date?
    public let lastAppVersion: String?
    public let countryIso: String?
}

public struct UserDTO: Codable {
    public let id: String
    public let telegramId: String
    public let phoneNumber: String?
    public let firstName: String?
    public let lastName: String?
    public let username: String?
    public let photoSmall: String?
    public let photoBig: String?
    public let referralCode: String?
    public let currentGemBalance: Int
    public let subscriptionPeriodEnd: Date?
    public let subscriptionStatus: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let appStatus: UserAppStatusDTO?
}

public struct AuthResultDTO: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let user: UserDTO
}

public struct RefreshRequest: Encodable {
    public let refreshToken: String
}

public struct LogoutRequest: Encodable {
    public let refreshToken: String
}

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
    public let authType: String?
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

/*
 public struct LoginRequest: Encodable {
     public let telegramId: String?
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
     public let restrictionReason: String?     // if nil -> encode null
     public let twoStepEnabled: Bool?
     public let deviceLabel: String?

     public struct Status: Encodable {
         public let lastSeen: String?
         public let online: Bool?

         public init(lastSeen: String? = nil, online: Bool? = nil) {
             self.lastSeen = lastSeen
             self.online = online
         }

         private enum CodingKeys: String, CodingKey {
             case lastSeen = "last_seen"
             case online
         }
     }

     private enum CodingKeys: String, CodingKey {
         case telegramId = "telegram_id"
         case verificationCode = "verification_code"
         case accessHash = "access_hash"
         case phoneNumber = "phone_number"
         case firstName = "first_name"
         case lastName = "last_name"
         case username
         case languageCode = "language_code"
         case isPremium = "is_premium"
         case isBot = "is_bot"
         case status
         case verified
         case restricted
         case restrictionReason = "restriction_reason"
         case twoStepEnabled = "two_step_enabled"
         case deviceLabel = "device_label"
     }

     public func encode(to encoder: Encoder) throws {
         var c = encoder.container(keyedBy: CodingKeys.self)

         // Encode only non-nil values
         if let v = telegramId { try c.encode(v, forKey: .telegramId) }
         if let v = verificationCode { try c.encode(v, forKey: .verificationCode) }
         if let v = accessHash { try c.encode(v, forKey: .accessHash) }
         if let v = phoneNumber { try c.encode(v, forKey: .phoneNumber) }
         if let v = firstName { try c.encode(v, forKey: .firstName) }
         if let v = lastName { try c.encode(v, forKey: .lastName) }
         if let v = username { try c.encode(v, forKey: .username) }
         if let v = languageCode { try c.encode(v, forKey: .languageCode) }
         if let v = isPremium { try c.encode(v, forKey: .isPremium) }
         if let v = isBot { try c.encode(v, forKey: .isBot) }
         if let v = status { try c.encode(v, forKey: .status) }
         if let v = verified { try c.encode(v, forKey: .verified) }
         if let v = restricted { try c.encode(v, forKey: .restricted) }

         // Always encode restriction_reason — either actual value or null
         if let reason = restrictionReason {
             try c.encode(reason, forKey: .restrictionReason)
         } else {
             try c.encodeNil(forKey: .restrictionReason)
         }

         if let v = twoStepEnabled { try c.encode(v, forKey: .twoStepEnabled) }
         if let v = deviceLabel { try c.encode(v, forKey: .deviceLabel) }
     }

     public init(
         telegramId: String? = nil,
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
 */

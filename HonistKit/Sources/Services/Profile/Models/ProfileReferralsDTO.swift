import Foundation

/// Invitee user info inside a referral record
public struct ReferralInviteeDTO: Codable {
    public let id: String
    public let firstName: String?
    public let lastName: String?
    public let username: String?
    public let photoSmall: String?
    
    public init(
        id: String,
        firstName: String?,
        lastName: String?,
        username: String?,
        photoSmall: String?
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.photoSmall = photoSmall
    }
}

/// Referral record returned from /app/profile/referrals
public struct ReferralDTO: Codable {
    public let id: String
    public let inviteeUserId: String
    public let inviteCode: String
    public let status: String
    public let acceptedAt: Date?
    public let referralMethod: String
    public let rewardGem: Int
    public let createdAt: Date
    public let invitee: ReferralInviteeDTO?
    
    public init(
        id: String,
        inviteeUserId: String,
        inviteCode: String,
        status: String,
        acceptedAt: Date?,
        referralMethod: String,
        rewardGem: Int,
        createdAt: Date,
        invitee: ReferralInviteeDTO?
    ) {
        self.id = id
        self.inviteeUserId = inviteeUserId
        self.inviteCode = inviteCode
        self.status = status
        self.acceptedAt = acceptedAt
        self.referralMethod = referralMethod
        self.rewardGem = rewardGem
        self.createdAt = createdAt
        self.invitee = invitee
    }
}

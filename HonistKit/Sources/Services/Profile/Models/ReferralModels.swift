import Foundation

/// Server response -> data for referral binding
public struct ReferralBindResultDTO: Decodable {
    public let id: String
    public let referrerUserId: String
    public let inviteeUserId: String
    public let firstName: String?
    public let lastName: String?
    public let username: String?
    public let inviteCode: String
    public let status: String
    public let acceptedAt: Date?
    public let referralMethod: String?
    public let rewardGem: Int?
    public let updatedAt: Date
    public let createdAt: Date
}

public struct AddReferralBody: Encodable {
    let referralCode: String
}

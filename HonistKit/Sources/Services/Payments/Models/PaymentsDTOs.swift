import Foundation

// MARK: - Product & Offer

public struct ProductOfferDTO: Decodable, Equatable {
    public let id: String
    public let title: String
    public let shortDescription: String?
    public let discountType: String
    public let discountValue: Int
    public let startsAt: Date?
    public let endsAt: Date?
    public let isActive: Bool
    public let createdAt: Date

    // Memberwise init for flexibility if needed later
    public init(
        id: String,
        title: String,
        shortDescription: String?,
        discountType: String,
        discountValue: Int,
        startsAt: Date?,
        endsAt: Date?,
        isActive: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.shortDescription = shortDescription
        self.discountType = discountType
        self.discountValue = discountValue
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

/// Represents a purchasable product (subscription or one-time pack)
public struct ProductDTO: Decodable, Equatable {
    public let id: String
    public let type: String                    // 'subscription_quota' | 'subscription_unlimited' | 'one_time_pack'
    public let period: String?                 // 'weekly' | 'annually' | 'none' | etc.
    public let title: String
    public let subject: String?
    public let shortDescription: String?
    public let appleProductId: String
    public let isPopular: Bool
    public let tags: [String]
    public let isUnlimited: Bool
    public let gemsPerPeriod: Int?
    public let basePriceCents: Int
    public let currency: String
    public let status: String                  // 'active' | 'deactive' | ...
    public let createdAt: Date?
    public let updatedAt: Date?
    public let offer: ProductOfferDTO?         // Optional nested active offer if any

    public init(
        id: String,
        type: String,
        period: String?,
        title: String,
        subject: String?,
        shortDescription: String?,
        appleProductId: String,
        isPopular: Bool,
        tags: [String],
        isUnlimited: Bool,
        gemsPerPeriod: Int?,
        basePriceCents: Int,
        currency: String,
        status: String,
        createdAt: Date?,
        updatedAt: Date?,
        offer: ProductOfferDTO?
    ) {
        self.id = id
        self.type = type
        self.period = period
        self.title = title
        self.subject = subject
        self.shortDescription = shortDescription
        self.appleProductId = appleProductId
        self.isPopular = isPopular
        self.tags = tags
        self.isUnlimited = isUnlimited
        self.gemsPerPeriod = gemsPerPeriod
        self.basePriceCents = basePriceCents
        self.currency = currency
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.offer = offer
    }
}

// MARK: - Subscription Order (create order)

/// Response of POST /app/subscriptions/orders
public struct SubscriptionOrderDTO: Decodable, Equatable {
    public let id: String
    public let userId: String
    public let productId: String
    public let subscriptionId: String?
    public let quantity: Int
    public let subtotalCents: Int
    public let discountCents: Int
    public let totalCents: Int
    public let currency: String
    public let provider: String               // e.g. 'apple_iap'
    public let status: String                 // e.g. 'pending'
    public let paidAt: Date?
    public let updatedAt: Date
    public let createdAt: Date
    public let providerTxnId: String?
    public let providerReceipt: String?

    public init(
        id: String,
        userId: String,
        productId: String,
        subscriptionId: String?,
        quantity: Int,
        subtotalCents: Int,
        discountCents: Int,
        totalCents: Int,
        currency: String,
        provider: String,
        status: String,
        paidAt: Date?,
        updatedAt: Date,
        createdAt: Date,
        providerTxnId: String?,
        providerReceipt: String?
    ) {
        self.id = id
        self.userId = userId
        self.productId = productId
        self.subscriptionId = subscriptionId
        self.quantity = quantity
        self.subtotalCents = subtotalCents
        self.discountCents = discountCents
        self.totalCents = totalCents
        self.currency = currency
        self.provider = provider
        self.status = status
        self.paidAt = paidAt
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.providerTxnId = providerTxnId
        self.providerReceipt = providerReceipt
    }
}

// MARK: - Current subscription (GET /app/subscriptions/me/latest)

public struct UserSubscriptionDTO: Decodable, Equatable {
    public let id: String
    public let userId: String
    public let productId: String
    public let gemOrderId: String?
    public let status: String                 // e.g. 'active', 'canceled'
    public let autoRenew: Bool
    public let currentPeriodStart: Date
    public let currentPeriodEnd: Date
    public let nextBillingAt: Date?
    public let remainingGemsInPeriod: Int
    public let canceledAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    public let product: ProductDTO            // Embedded product details

    public init(
        id: String,
        userId: String,
        productId: String,
        gemOrderId: String?,
        status: String,
        autoRenew: Bool,
        currentPeriodStart: Date,
        currentPeriodEnd: Date,
        nextBillingAt: Date?,
        remainingGemsInPeriod: Int,
        canceledAt: Date?,
        createdAt: Date,
        updatedAt: Date,
        product: ProductDTO
    ) {
        self.id = id
        self.userId = userId
        self.productId = productId
        self.gemOrderId = gemOrderId
        self.status = status
        self.autoRenew = autoRenew
        self.currentPeriodStart = currentPeriodStart
        self.currentPeriodEnd = currentPeriodEnd
        self.nextBillingAt = nextBillingAt
        self.remainingGemsInPeriod = remainingGemsInPeriod
        self.canceledAt = canceledAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.product = product
    }
}

// MARK: - Apple Verify response

/// Response of POST /app/iap/apple/verify
public struct AppleVerifyResultDTO: Decodable, Equatable {
    public let orderId: String
    public let transactionId: String
    public let status: String                 // e.g. 'verified', 'failed'

    public init(orderId: String, transactionId: String, status: String) {
        self.orderId = orderId
        self.transactionId = transactionId
        self.status = status
    }
}

// MARK: - Request bodies

/// Body of POST /app/subscriptions/orders
public struct CreateOrderRequest: Encodable {
    public let appleProductId: String
    public let provider: String               // e.g. 'apple_iap'

    public init(appleProductId: String, provider: String = "apple_iap") {
        self.appleProductId = appleProductId
        self.provider = provider
    }
}

/// Body of POST /app/iap/apple/verify
/// `originalTxnId`, `expiresDate`, `signedRenewalJws`, `receiptData` can be nil.
public struct AppleVerifyRequest: Encodable {
    public let orderId: String
    public let productId: String
    public let transactionId: String
    public let originalTxnId: String?
    public let purchaseDate: Date
    public let expiresDate: Date?
    public let signedTransactionJws: String
    public let signedRenewalJws: String?
    public let receiptData: String?
    public let environment: String           // "Sandbox" or "Production"

    public init(
        orderId: String,
        productId: String,
        transactionId: String,
        originalTxnId: String?,
        purchaseDate: Date,
        expiresDate: Date?,
        signedTransactionJws: String,
        signedRenewalJws: String?,
        receiptData: String?,
        environment: String
    ) {
        self.orderId = orderId
        self.productId = productId
        self.transactionId = transactionId
        self.originalTxnId = originalTxnId
        self.purchaseDate = purchaseDate
        self.expiresDate = expiresDate
        self.signedTransactionJws = signedTransactionJws
        self.signedRenewalJws = signedRenewalJws
        self.receiptData = receiptData
        self.environment = environment
    }
}

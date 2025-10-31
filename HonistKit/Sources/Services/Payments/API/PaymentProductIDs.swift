// MARK: - PaymentProductIDs
// Keep product identifiers centralized

public enum PaymentProductIDs {
    // Consumables
    public static let gems110  = "org.b41aaccfc4f9948d.gems.110"
    public static let gems400  = "org.b41aaccfc4f9948d.gems.400"
    public static let gems1300 = "org.b41aaccfc4f9948d.gems.1300"

    // Subscriptions (Auto-Renewable)
    public static let subsGems50Monthly   = "org.b41aaccfc4f9948d.subs.gems50.monthly"
    public static let subsGems100Monthly  = "org.b41aaccfc4f9948d.subs.group.gems100.monthly" // your exact ID
    public static let unlimitedMonthly    = "org.b41aaccfc4f9948d.subs.unlimited.monthly"
    public static let unlimitedYearly     = "org.b41aaccfc4f9948d.subs.unlimited.yearly"

    /// Group for subscriptions (optional: for your own logic)
    public static let subscriptionGroupIds: [String] = [
        // NOTE: This is for your app's own grouping logic if needed.
        // StoreKit's "group" is managed in App Store Connect; here we may mirror meta if useful.
        "21812415", // Gems 100/monthly
        "21812402", // Gems 50/monthly
        "21812375" // Unlimited Gems
    ]
}

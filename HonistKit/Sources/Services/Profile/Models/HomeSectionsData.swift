import Foundation

public struct HomeSectionsData {
    public let assistants: [AssistantItem]
    public let metrics: (gems: String, friends: String)
    public let featured: [FeaturedItem]
    
    public init(
        assistants: [AssistantItem],
        metrics: (gems: String, friends: String),
        featured: [FeaturedItem]
    ) {
        self.assistants = assistants
        self.metrics = metrics
        self.featured = featured
    }
}

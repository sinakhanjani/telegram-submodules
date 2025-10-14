import Foundation

public struct EmptyDTO: Codable {
    public init() {}
}
public struct ApiResponse<T: Codable>: Codable { public let data: T }



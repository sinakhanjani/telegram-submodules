import Foundation

public protocol AuthTokenProvider: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }
}

public struct HonistApiClientOptions {
    public var debugLogging: Bool
    public var requestTimeout: TimeInterval

    public init(debugLogging: Bool = false, requestTimeout: TimeInterval = 30) {
        self.debugLogging = debugLogging
        self.requestTimeout = requestTimeout
    }
}

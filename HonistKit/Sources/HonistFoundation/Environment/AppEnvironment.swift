import Foundation
public enum AppEnvironment {
    /// Base URL of backend (set per build scheme)
    public static var baseURLString: String = "https://demo.honistai.space"
    
    /// HMAC secret used for signed API requests.
    /// ⚠️ Never commit real secrets to public repositories.
    /// Prefer reading from an environment variable or Config.xcconfig.
    public static var hmacSecret: String {
        // Option 1: read from environment variable at build-time
//        if let env = ProcessInfo.processInfo.environment["HONIST_HMAC_SECRET"], !env.isEmpty {
//            return env
//        }

        // Option 2: fallback hardcoded (for local/demo)
        return "sk-9f7a2xBtL8wZp3Qy"
    }

    /// Optional: build type flags
    public static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

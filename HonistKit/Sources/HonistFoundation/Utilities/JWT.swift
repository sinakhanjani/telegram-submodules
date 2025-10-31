import Foundation

public enum JWT {
    /// Decodes a JWT payload into a dictionary (unsafe; no signature verification).
    public static func decodePayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let base64url = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Apply standard Base64 padding if needed
        let remainder = base64url.count % 4
        let padded: String
        if remainder == 0 {
            padded = base64url
        } else {
            padded = base64url.padding(toLength: base64url.count + (4 - remainder), withPad: "=", startingAt: 0)
        }

        guard let data = Data(base64Encoded: padded) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    /// Returns the `exp` (seconds since epoch) if present.
    public static func expiration(_ jwt: String) -> TimeInterval? {
        guard let payload = decodePayload(jwt),
              let exp = payload["exp"] as? TimeInterval else { return nil }
        return exp
    }

    /// Checks whether the token is expired at current time (with optional skew seconds).
    public static func isExpired(_ jwt: String, skew: TimeInterval = 30) -> Bool {
        guard let exp = expiration(jwt) else { return false }
        let now = Date().timeIntervalSince1970
        return now + skew >= exp
    }
}

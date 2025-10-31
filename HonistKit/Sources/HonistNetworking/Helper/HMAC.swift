import Foundation
import CommonCrypto

public enum HMAC {
    /// Computes HMAC-SHA256 over raw data with the given secret (UTF-8), returns lowercase hex.
    public static func sha256Hex(data: Data, secret: String) -> String {
        let keyData = Data(secret.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { dataRaw in
            keyData.withUnsafeBytes { keyRaw in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                       keyRaw.baseAddress, keyData.count,
                       dataRaw.baseAddress, data.count,
                       &digest)
            }
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

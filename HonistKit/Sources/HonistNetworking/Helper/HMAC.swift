import Foundation
import CommonCrypto

public enum HMAC {    
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

/*
 // Compute HMAC signature for bodyDict (optional)
//        do {
//            let body = LoginRequest(
//                telegramId: "5666681068",
//                accessHash: "-5967423124630446231",
//                username: "osxsupport",
//                isBot: false
//            )
//
//            let encoder = JSONEncoder()
//            encoder.keyEncodingStrategy = .convertToSnakeCase
//            if #available(iOS 11.0, *) { encoder.dateEncodingStrategy = .iso8601 }
//            // ❌ Don't use keyEncodingStrategy = .convertToSnakeCase because you already set CodingKeys manually
//            let bodyData = try encoder.encode(body) // encode model to JSON
//            let signature = HMAC.sha256Hex(data: bodyData, secret: "sk-9f7a2xBtL8wZp3Qy")
//
//            print("bodyString:", String(data: bodyData, encoding: .utf8) ?? "<invalid UTF-8>")
//            print("x-hmac-signature:", signature)
//
//        } catch {
//            print("❌ Encoding or signing failed:", error.localizedDescription)
//        }
 */

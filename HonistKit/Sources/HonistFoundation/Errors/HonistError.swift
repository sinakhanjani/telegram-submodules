import Foundation

public enum HonistError: Error, LocalizedError, Equatable {
    case invalidURL(String)
    case unauthorized                         // 401
    case network(status: Int, message: String?)
    case decoding(String)
    case server(message: String?)             // success=false
    case upload(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let s): return "Invalid URL: \(s)"
        case .unauthorized: return "Unauthorized"
        case .network(let status, let msg): return "Network error (\(status)): \(msg ?? "—")"
        case .decoding(let msg): return "Decoding error: \(msg)"
        case .server(let msg): return "Server error: \(msg ?? "—")"
        case .upload(let msg): return "Upload error: \(msg)"
        case .cancelled: return "Cancelled"
        }
    }
}

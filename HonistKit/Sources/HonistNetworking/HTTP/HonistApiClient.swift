import Foundation
import HonistFoundation   // For AppEnvironment, HonistError, TokenRefresher, AuthTokenProvider
import HonistModels       // For ApiEnvelope, ListPayload, EmptyDTO

// MARK: - HTTP Method

public enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

// MARK: - Marker protocol
// Types that decode from the *root* response on their own (e.g., ListPayload)
// and do not rely on the client to unwrap ApiEnvelope<T>
public protocol RootDecodesItself {}
extension ListPayload: RootDecodesItself {}

public final class HonistApiClient {
    // MARK: - Core dependencies
    public let baseURL: URL
    private let session: URLSession
    private let tokenProvider: AuthTokenProvider?
    private let options: HonistApiClientOptions
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    // MARK: - Token lifecycle helper (optional)
    // If provided, will be used to:
    // 1) eagerly refresh tokens before protected requests,
    // 2) attempt a one-time refresh and retry the request on 401.
    private let tokenRefresher: TokenRefresher?

    // MARK: - Init

    public init(
        baseURL: URL = URL(string: AppEnvironment.baseURLString)!,
        tokenProvider: AuthTokenProvider? = nil,
        options: HonistApiClientOptions = .init(),
        session: URLSession? = nil,
        tokenRefresher: TokenRefresher? = nil
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.options = options
        self.tokenRefresher = tokenRefresher

        // Build URLSession
        let config = (session?.configuration ?? URLSessionConfiguration.default)
        config.timeoutIntervalForRequest = options.requestTimeout
        self.session = session ?? URLSession(configuration: config)

        // JSONDecoder with ISO-8601 date support and fractional seconds:
        // e.g. "2025-09-20T00:00:00.000Z"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            // NOTE: We decode ISO-8601 both with and without fractional seconds
            let container = try decoder.singleValueContainer()
            let s = try container.decode(String.self)

            let ffs = ISO8601DateFormatter()
            ffs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = ffs.date(from: s) { return d }

            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            if let d = f.date(from: s) { return d }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(s)")
        }
        self.jsonDecoder = decoder

        // JSONEncoder with snake_case keys and ISO-8601 dates
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        if #available(iOS 11.0, *) {
            encoder.dateEncodingStrategy = .iso8601
        }
        self.jsonEncoder = encoder
    }

    // MARK: - Public convenience

    /// Generic GET that decodes `T`
    public func get<T: Decodable>(
        _ path: String,
        query: [String: CustomStringConvertible]? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .GET, query: query, headers: headers)
    }

    /// GET helper for list endpoints that may return mixed shapes
    /// (e.g., data: [Item] with or without pagination at root, or data: { pagination, items })
    /// Uses `ListPayload<Item>` which knows how to decode itself.
    public func getList<Item: Decodable>(
        _ path: String,
        query: [String: CustomStringConvertible]? = nil,
        headers: [String: String] = [:]
    ) async throws -> ListPayload<Item> {
        try await request(path, method: .GET, query: query, headers: headers)
    }

    /// POST with JSON body
    public func post<Body: Encodable, T: Decodable>(
        _ path: String,
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .POST, body: .json(body), headers: headers)
    }

    /// PUT with JSON body
    public func put<Body: Encodable, T: Decodable>(
        _ path: String,
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .PUT, body: .json(body), headers: headers)
    }

    /// PATCH with JSON body
    public func patch<Body: Encodable, T: Decodable>(
        _ path: String,
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .PATCH, body: .json(body), headers: headers)
    }

    /// DELETE that expects a payload `T` in the envelope
    public func delete<T: Decodable>(
        _ path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        try await request(path, method: .DELETE, headers: headers)
    }

    /// DELETE that returns no payload (maps to `EmptyDTO`)
    public func deleteEmpty(_ path: String, headers: [String: String] = [:]) async throws {
        let _: EmptyDTO = try await request(path, method: .DELETE, headers: headers)
    }

    /// Multipart POST/PATCH (e.g., media uploads)
    public func uploadMultipart<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .POST,
        parts: [MultipartPart],
        headers: [String: String] = [:]
    ) async throws -> T {
        let multipart = try MultipartBuilder.build(parts: parts)
        return try await request(
            path,
            method: method,
            body: .raw(multipart.data, contentType: multipart.contentType),
            headers: headers
        )
    }

    // MARK: - Core request

    private enum BodyPayload {
        case none
        case json(Encodable)
        case raw(Data, contentType: String)
    }

    /// Core request runner:
    /// - Eagerly refreshes token (if needed) via `TokenRefresher`
    /// - Builds URL + query
    /// - Adds headers (including Authorization)
    /// - Encodes body (JSON/raw)
    /// - Executes request
    /// - On 401, tries a one-time refresh + retry (if `TokenRefresher` provided)
    /// - Decodes response either as:
    ///   a) RootDecodesItself (e.g., ListPayload), or
    ///   b) ApiEnvelope<T> (success/data/message), with fallback to direct T
    private func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod,
        query: [String: CustomStringConvertible]? = nil,
        body: BodyPayload = .none,
        headers: [String: String] = [:]
    ) async throws -> T {

        // --- Eager refresh before protected requests (if refresher exists) ---
        if let refresher = tokenRefresher {
            // If this throws (e.g., no refresh token), we propagate the error.
            try await refresher.ensureValidAccessTokenIfNeeded()
        }

        // Resolve URL + query
        guard var url = URL(string: path, relativeTo: baseURL) else {
            throw HonistError.invalidURL(path)
        }
        if let query {
            guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                throw HonistError.invalidURL(url.absoluteString)
            }
            comps.queryItems = (comps.queryItems ?? []) + query.map {
                URLQueryItem(name: $0.key, value: String(describing: $0.value))
            }
            if let u = comps.url { url = u }
        }

        // Build URLRequest
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        // Authorization (Bearer token)
        if let token = tokenProvider?.accessToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Body
        switch body {
        case .none:
            break
        case .json(let enc):
            req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            do {
                req.httpBody = try encodeAny(enc)
            } catch {
                throw HonistError.decoding("Failed to encode body: \(error.localizedDescription)")
            }
        case .raw(let data, let contentType):
            req.setValue(contentType, forHTTPHeaderField: "Content-Type")
            req.httpBody = data
        }

        // Extra headers (override if needed)
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }

        if options.debugLogging { logRequest(req) }

        // Execute request with at most one retry on 401 if we have a refresher
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw HonistError.network(status: -1, message: "No HTTPURLResponse")
            }

            // If 401 and refresher exists → try refresh + retry once
            if http.statusCode == 401, let refresher = tokenRefresher {
                // Try a refresh now (may throw). If returns true, we retry the same request once.
                let shouldRetry = try await refresher.refreshAfterUnauthorized()
                if shouldRetry {
                    // Rebuild Authorization header with updated access token:
                    var retryReq = req
                    if let newToken = tokenProvider?.accessToken, !newToken.isEmpty {
                        retryReq.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    }
                    if options.debugLogging { print("🔁 Retrying after refresh: \(retryReq.url?.absoluteString ?? "")") }
                    let (retryData, retryResp) = try await session.data(for: retryReq)
                    guard let retryHttp = retryResp as? HTTPURLResponse else {
                        throw HonistError.network(status: -1, message: "No HTTPURLResponse (retry)")
                    }
                    return try decodeResponse(retryHttp, data: retryData)
                }
                // If refresh not possible, fall through to normal 401 handling
            }

            return try decodeResponse(http, data: data)

        } catch is CancellationError {
            throw HonistError.cancelled
        } catch {
            throw error
        }
    }

    // MARK: - Decode helper for initial or retried responses

    /// Decodes the response using the client decoder rules.
    /// - Throws proper `HonistError` for non-2xx codes.
    private func decodeResponse<T: Decodable>(_ http: HTTPURLResponse, data: Data) throws -> T {
        if options.debugLogging { logResponse(http, data: data) }

        // 401 → unauthorized (the refresh path is handled in request(); here we just bubble up)
        if http.statusCode == 401 {
            // Try to surface server message if envelope-like:
            if let env: ApiEnvelope<EmptyDTO> = try? jsonDecoder.decode(ApiEnvelope<EmptyDTO>.self, from: data),
               let msg = env.message {
                throw HonistError.network(status: http.statusCode, message: msg)
            }
            throw HonistError.unauthorized
        }

        // Non-2xx → try to surface server envelope message
        guard (200..<300).contains(http.statusCode) else {
            if let env = try? jsonDecoder.decode(ApiEnvelope<EmptyDTO>.self, from: data) {
                throw HonistError.network(status: http.statusCode, message: env.message)
            }
            throw HonistError.network(status: http.statusCode, message: String(data: data, encoding: .utf8))
        }

        // Decoding strategy:
        // 1) If T conforms to RootDecodesItself (e.g., ListPayload), decode T directly from the root.
        // 2) Otherwise try ApiEnvelope<T>, then fallback to decoding T directly.
        if T.self is RootDecodesItself.Type {
            return try jsonDecoder.decode(T.self, from: data)
        }

        do {
            let env = try jsonDecoder.decode(ApiEnvelope<T>.self, from: data)

            // success must be true
            guard env.success else {
                throw HonistError.server(message: env.message)
            }

            // T == EmptyDTO and no data → fabricate an empty payload
            if T.self == EmptyDTO.self, env.data == nil {
                return EmptyDTO() as! T
            }

            // Ensure we have data
            guard let payload = env.data else {
                if T.self == EmptyDTO.self { return EmptyDTO() as! T }
                throw HonistError.decoding("Missing `data` in envelope")
            }

            return payload
        } catch {
            // Fallback: some endpoints might return raw `T` without envelope
            if let direct = try? jsonDecoder.decode(T.self, from: data) {
                return direct
            }
            throw HonistError.decoding(error.localizedDescription)
        }
    }

    // MARK: - Encodable erasure

    /// Encodable-erasure to allow passing `Encodable` as body payload
    private func encodeAny(_ value: Encodable) throws -> Data {
        let box = AnyEncodable(value)
        return try jsonEncoder.encode(box)
    }

    // MARK: - Logging

    private func logRequest(_ req: URLRequest) {
        var lines: [String] = []
        lines.append("➡️ \(req.httpMethod ?? "") \(req.url?.absoluteString ?? "")")
        if let headers = req.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("Headers: \(headers)")
        }
        if let body = req.httpBody, let s = String(data: body, encoding: .utf8) {
            lines.append("Body: \(s)")
        }
        print(lines.joined(separator: "\n"))
    }

    private func logResponse(_ res: HTTPURLResponse, data: Data) {
        var lines: [String] = []
        lines.append("⬅️ [\(res.statusCode)] \(res.url?.absoluteString ?? "")")
        if !res.allHeaderFields.isEmpty {
            lines.append("Headers: \(res.allHeaderFields)")
        }
        if let s = String(data: data, encoding: .utf8) {
            lines.append("Body: \(s)")
        }
        print(lines.joined(separator: "\n"))
    }
}

// MARK: - AnyEncodable helper

fileprivate struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ encodable: Encodable) {
        self._encode = encodable.encode
    }
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

/*
 Example
 // MARK: - 1) Simple GET (profile)

struct ProfileDTO: Decodable {
    let id: String
    let username: String
    let bio: String?
}

let api = HonistApiClient(tokenProvider: myTokenProvider, options: .init(debugLogging: true))

let profile: ProfileDTO = try await api.get("/api/v1/me")
print("Profile:", profile.username)


// MARK: - 2) GET list (mixed shapes) using ListPayload
// Make sure you have: `extension ListPayload: RootDecodesItself {}` somewhere in your project.

struct PlacementDTO: Decodable {
    let id: String
    let platform: String
    let adType: String
    // ...
}

let placements: ListPayload<PlacementDTO> = try await api.getList(
    "/api/v1/placements",
    query: ["page": 1, "limit": 50]
)

print("Total items:", placements.items.count)
print("Page:", placements.pagination?.page ?? 1)


// MARK: - 3) POST JSON

struct UpdateBioBody: Encodable { let bio: String }
struct UpdateBioResult: Decodable { let updated: Bool }

let postResult: UpdateBioResult = try await api.post(
    "/api/v1/me/bio",
    body: UpdateBioBody(bio: "Hello!")
)
print("Bio updated:", postResult.updated)


// MARK: - 4) PATCH JSON

struct UpdateUsernameBody: Encodable { let username: String }

let _: EmptyDTO = try await api.patch(
    "/api/v1/me/username",
    body: UpdateUsernameBody(username: "sina")
)
print("Username updated.")


// MARK: - 5) DELETE

let _: EmptyDTO = try await api.delete("/api/v1/sessions/current")
print("Session deleted.")


// MARK: - 6) Multipart upload (image + text fields)

let imageData: Data = /* PNG or JPEG data */
let parts: [MultipartPart] = [
    .init(name: "avatar", value: .data(imageData, filename: "avatar.jpg", mimeType: "image/jpeg")),
    .init(name: "bio",    value: .text("New bio here"))
]

struct UploadAvatarResult: Decodable { let url: String }

let upload: UploadAvatarResult = try await api.uploadMultipart(
    "/api/v1/me/avatar",
    method: .PATCH,
    parts: parts
)
print("Avatar URL:", upload.url)
 */

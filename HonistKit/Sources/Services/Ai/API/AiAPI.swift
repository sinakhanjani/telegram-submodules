import Foundation
import HonistNetworking
import HonistModels
import HonistFoundation
import HonistCore

/// API layer for AI assistants, conversations, and prompts.
/// All requests include `x-hmac-signature` computed over the JSON body (or empty for GET/DELETE).
public struct AiAPI {
    public struct Config {
        public let hmacSecret: String
        public init(hmacSecret: String) {
            self.hmacSecret = hmacSecret
        }
    }

    private let client: HonistApiClient
    private let config: Config

    // Dedicated encoder so the bytes we sign match exactly the body encoding.
    private static func makeEncoder() -> JSONEncoder {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        if #available(iOS 11.0, *) {
            enc.dateEncodingStrategy = .iso8601
        }
        return enc
    }

    private let encoder: JSONEncoder = AiAPI.makeEncoder()

    public init(
        client: HonistApiClient = HonistRegistry.shared.apiClient,
        config: Config = .init(hmacSecret: AppEnvironment.hmacSecret)
    ) {
        self.client = client
        self.config = config
    }

    // MARK: - HMAC helper

    /// Computes `x-hmac-signature` header for a given JSON body (or empty body).
    private func hmacHeader<T: Encodable>(for body: T?) throws -> [String: String] {
        let data: Data
        if let body = body {
            data = try encoder.encode(body)
        } else {
            data = Data()
        }

        let signature = HMAC.sha256Hex(data: data, secret: config.hmacSecret)
        return ["x-hmac-signature": signature]
    }

    /// Convenience for requests without JSON body (GET/DELETE).
    private func emptyBodyHeader() throws -> [String: String] {
        try hmacHeader(for: Optional<String>.none)
    }

    // MARK: - Assistants

    /// GET /app/ai/assistants
    public func listAssistants() async throws -> [AiAssistantDTO] {
        let headers = try emptyBodyHeader()
        let result: [AiAssistantDTO] = try await client.get(
            "/api/v1/app/ai/assistants",
            headers: headers
        )
        return result
    }

    // MARK: - Conversations

    /// GET /app/ai/conversations
    /// Uses ListPayload to support pagination.
    public func listConversations(
        page: Int,
        limit: Int
    ) async throws -> ListPayload<AiConversationDTO> {
        let headers = try emptyBodyHeader()
        let result: ListPayload<AiConversationDTO> = try await client.getList(
            "/api/v1/app/ai/conversations",
            query: ["page": page, "limit": limit],
            headers: headers
        )
        return result
    }

    /// GET /app/ai/conversations/:conversationId/messages
    public func listConversationMessages(
        conversationId: String,
        page: Int,
        limit: Int
    ) async throws -> ListPayload<AiMessageDTO> {
        let headers = try emptyBodyHeader()
        let path = "/api/v1/app/ai/conversations/\(conversationId)/messages"
        let result: ListPayload<AiMessageDTO> = try await client.getList(
            path,
            query: ["page": page, "limit": limit],
            headers: headers
        )
        return result
    }

    /// DELETE /app/ai/conversations/:conversationId
    public func deleteConversation(conversationId: String) async throws {
        let headers = try emptyBodyHeader()
        let path = "/api/v1/app/ai/conversations/\(conversationId)"
        let _: EmptyDTO = try await client.delete(path, headers: headers)
    }

    // MARK: - Messages with Assistants

    /// POST /app/ai/assistants/:assistantId/messages
    public func sendMessageToAssistant(
        assistantId: String,
        body: AiSendMessageRequest
    ) async throws -> AiSendMessageResultDTO {
        let headers = try hmacHeader(for: body)
        let path = "/api/v1/app/ai/assistants/\(assistantId)/messages"
        let result: AiSendMessageResultDTO = try await client.post(
            path,
            body: body,
            headers: headers
        )
        return result
    }

    /// PATCH /app/ai/assistants/messages/:messageId
    public func updateAssistantMessage(
        messageId: String,
        body: AiUpdateMessageRequest
    ) async throws -> AiUpdateMessageResultDTO {
        let headers = try hmacHeader(for: body)
        let path = "/api/v1/app/ai/assistants/messages/\(messageId)"
        let result: AiUpdateMessageResultDTO = try await client.patch(
            path,
            body: body,
            headers: headers
        )
        return result
    }

    // MARK: - Prompts

    /// GET /app/ai/prompts
    public func listPrompts() async throws -> [AiPromptDTO] {
        let headers = try emptyBodyHeader()
        let result: [AiPromptDTO] = try await client.get(
            "/api/v1/app/ai/prompts",
            headers: headers
        )
        return result
    }

    /// POST /app/ai/prompts/:promptId/messages
    public func sendMessageToPrompt(
        promptId: String,
        body: AiSendMessageRequest
    ) async throws -> AiSendMessageResultDTO {
        let headers = try hmacHeader(for: body)
        let path = "/api/v1/app/ai/prompts/\(promptId)/messages"
        let result: AiSendMessageResultDTO = try await client.post(
            path,
            body: body,
            headers: headers
        )
        return result
    }

    /// PATCH /app/ai/prompts/messages/:messageId
    public func updatePromptMessage(
        messageId: String,
        body: AiUpdateMessageRequest
    ) async throws -> AiUpdateMessageResultDTO {
        let headers = try hmacHeader(for: body)
        let path = "/api/v1/app/ai/prompts/messages/\(messageId)"
        let result: AiUpdateMessageResultDTO = try await client.patch(
            path,
            body: body,
            headers: headers
        )
        return result
    }
}

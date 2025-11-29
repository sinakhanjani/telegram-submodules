import Foundation
import HonistModels
import HonistFoundation

/// High-level logic for AI assistants, conversations, and prompts.
/// This layer is UI-agnostic and can be used from any controller or view model.
public final class AiLogic {

    private let api: AiAPI

    // In-memory state (optional, can be extended later)
    private var _assistantsCache: [AiAssistantDTO] = []
    private var _promptsCache: [AiPromptDTO] = []

    public init(api: AiAPI = AiAPI()) {
        self.api = api
    }

    // MARK: - Assistants

    /// Loads all AI assistants from the server and caches them in memory.
    @discardableResult
    public func loadAssistants() async throws -> [AiAssistantDTO] {
        let list = try await api.listAssistants()
        _assistantsCache = list
        return list
    }

    /// Last loaded assistants list (may be empty if not loaded yet).
    public var assistantsCache: [AiAssistantDTO] {
        _assistantsCache
    }

    // MARK: - Conversations

    /// Lists AI conversations for the current user (paginated).
    public func listConversations(
        page: Int,
        limit: Int
    ) async throws -> ListPayload<AiConversationDTO> {
        try await api.listConversations(page: page, limit: limit)
    }

    /// Loads messages for a specific conversation (paginated).
    public func listConversationMessages(
        conversationId: String,
        page: Int,
        limit: Int
    ) async throws -> ListPayload<AiMessageDTO> {
        try await api.listConversationMessages(
            conversationId: conversationId,
            page: page,
            limit: limit
        )
    }

    /// Deletes a conversation for the current user.
    public func deleteConversation(conversationId: String) async throws {
        try await api.deleteConversation(conversationId: conversationId)
    }

    // MARK: - Send / Update messages (Assistants)

    /// Sends a message to an AI assistant.
    /// - Parameters:
    ///   - assistantId: Target assistant id.
    ///   - conversationId: Optional existing conversation id (nil for new).
    ///   - content: User text.
    public func sendMessageToAssistant(
        assistantId: String,
        conversationId: String?,
        content: String
    ) async throws -> AiSendMessageResultDTO {
        let body = AiSendMessageRequest(conversationId: conversationId, content: content)
        return try await api.sendMessageToAssistant(assistantId: assistantId, body: body)
    }

    /// Re-generates or edits an existing assistant message.
    public func updateAssistantMessage(
        messageId: String,
        newContent: String
    ) async throws -> AiUpdateMessageResultDTO {
        let body = AiUpdateMessageRequest(newContent: newContent)
        return try await api.updateAssistantMessage(messageId: messageId, body: body)
    }

    // MARK: - Prompts

    /// Loads all AI prompts and caches them in memory.
    @discardableResult
    public func loadPrompts() async throws -> [AiPromptDTO] {
        let list = try await api.listPrompts()
        _promptsCache = list
        return list
    }

    /// Last loaded prompts list (may be empty if not loaded yet).
    public var promptsCache: [AiPromptDTO] {
        _promptsCache
    }

    /// Sends a message using a specific prompt preset.
    public func sendMessageWithPrompt(
        promptId: String,
        conversationId: String?,
        content: String
    ) async throws -> AiSendMessageResultDTO {
        let body = AiSendMessageRequest(conversationId: conversationId, content: content)
        return try await api.sendMessageToPrompt(promptId: promptId, body: body)
    }

    /// Updates a message generated from prompt-based conversation.
    public func updatePromptMessage(
        messageId: String,
        newContent: String
    ) async throws -> AiUpdateMessageResultDTO {
        let body = AiUpdateMessageRequest(newContent: newContent)
        return try await api.updatePromptMessage(messageId: messageId, body: body)
    }
}

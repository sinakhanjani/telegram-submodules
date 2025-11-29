import Foundation

// MARK: - Assistants

public struct AiAssistantDTO: Decodable {
    public let id: String
    public let name: String
    public let slug: String
    public let avatarUrl: String?
    public let shortDescription: String?
    public let aiModels: String?
    public let temperature: String?
    public let maxTokens: Int
    public let isActive: Bool
}

// MARK: - Conversations (list)

public struct AiConversationAssistantSummaryDTO: Decodable {
    public let id: String
    public let name: String
    public let slug: String
    public let avatarUrl: String?
}

/// Represents a single conversation in `/app/ai/conversations`
public struct AiConversationDTO: Decodable {
    public let id: String
    public let assistantId: String
    public let title: String?
    public let lastMessage: String?
    public let totalMessages: Int
    public let status: String
    public let isUnlimited: Bool
    public let lastMessageAt: Date?
    public let createdAt: Date
    public let assistant: AiConversationAssistantSummaryDTO
}

// MARK: - Messages (one conversation)

/// Represents an AI message within a conversation.
public struct AiMessageDTO: Decodable {
    public let id: String
    public let conversationId: String
    public let userId: String
    public let role: String            // e.g. "user" or "assistant"
    public let messageType: String     // e.g. "text"
    public let content: String
    public let stickerId: String?

    public let inputTokens: Int?
    public let outputTokens: Int?
    public let totalTokens: Int?

    public let isUnlimitedApplied: Bool
    public let gemCost: Int?
    public let chargeApplied: Bool

    public let openaiResponseId: String?
    public let errorCode: String?
    public let latencyMs: Int?
    public let openaiCostUsd: Double?

    public let createdAt: Date
    public let updatedAt: Date
}

// MARK: - Send message (request/response)

/// Common request body for sending a message to an assistant or prompt.
public struct AiSendMessageRequest: Encodable {
    /// Optional: existing conversation id if user continues an existing thread.
    public let conversationId: String?
    /// Text content entered by the user.
    public let content: String

    public init(conversationId: String? = nil, content: String) {
        self.conversationId = conversationId
        self.content = content
    }
}

/// Result when sending a message:
/// Contains created user message + AI assistant reply.
public struct AiSendMessageResultDTO: Decodable {
    public let conversationId: String
    public let userMessage: AiMessageDTO
    public let assistantMessage: AiMessageDTO
}

// MARK: - Update message (request/response)

/// Request body for updating (editing) a message.
public struct AiUpdateMessageRequest: Encodable {
    public let newContent: String

    public init(newContent: String) {
        self.newContent = newContent
    }
}

/// Result after re-generating / updating an AI message.
public struct AiUpdateMessageResultDTO: Decodable {
    public let content: String
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let totalTokens: Int?
    public let gemCost: Int?
    public let chargeApplied: Bool
    public let isUnlimitedApplied: Bool
    public let openaiResponseId: String?
    public let latencyMs: Int?
    public let openaiCostUsd: Double?
}

// MARK: - Prompts

/// Prompt assistant definition nested inside prompt DTOs.
public struct AiPromptAssistantDTO: Decodable {
    public let id: String
    public let name: String
    public let slug: String
    public let aiModels: String?
    public let temperature: String?
    public let maxTokens: Int?
    public let systemPrompt: String?
    public let developerPrompt: String?
    public let toolsJson: String?
}

/// High-level prompt preset used for quick AI actions.
public struct AiPromptDTO: Decodable {
    public let id: String
    public let assistantId: String
    public let title: String
    public let adminId: String
    public let shortDescription: String?
    public let promptText: String
    public let model: String?
    public let gemCost: Int?
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let assistant: AiPromptAssistantDTO
}

//
//  AIConversation.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/8/26
//

import Foundation

/// Parent-owned conversation state. Pass it to `AIChatView` as a binding.
public struct AIConversation: Identifiable {
    public enum Message: Identifiable {
        case user(AIChatInput)
        case assistant(AIChatResponse)

        public var id: UUID {
            switch self {
            case .user(let input): input.id
            case .assistant(let response): response.id
            }
        }

        public var createdAt: Date {
            switch self {
            case .user(let input): input.createdAt
            case .assistant(let response): response.createdAt
            }
        }
    }

    public var id: UUID
    /// `nil` lets `AIChatView` display its default title.
    public var title: String?
    public var messages: [Message]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String? = nil,
        messages: [Message] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public mutating func removeMessage(id: UUID) {
        messages.removeAll { $0.id == id }
        updatedAt = .now
    }

    public mutating func removeAllMessages() {
        messages.removeAll()
        updatedAt = .now
    }
}

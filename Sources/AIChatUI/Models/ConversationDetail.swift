//
//  ConversationDetail.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Conversation detail containing the message list.
public struct ConversationDetail: Sendable {
    public let id: UUID
    public let title: String
    public let messages: [ChatMessage]

    public init(id: UUID, title: String, messages: [ChatMessage]) {
        self.id = id
        self.title = title
        self.messages = messages
    }
}

//
//  ConversationSummary.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import Foundation

/// A conversation summary used for displaying the history list.
public struct ConversationSummary: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let updatedAt: Date

    public init(id: UUID, title: String, updatedAt: Date) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
    }
}

//
//  AIChatResponse.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/8/26
//

import Foundation
import SwiftUI

/// One server update. Send the same `id` again to update the existing response in place.
public struct AIChatResponse: Identifiable {
    public enum Content {
        /// Rendered by MarkdownView's `MarkdownText`.
        case markdown(String)
        /// A type-erased SwiftUI view. It may observe its own state and update independently.
        case view(AnyView)

        @MainActor
        public static func view<ContentView: View>(_ view: ContentView) -> Self {
            .view(AnyView(view))
        }
    }

    public var id: UUID
    public var role: AIChatRole
    public var content: Content
    /// When provided by a callback update, replaces the bound conversation title.
    public var conversationTitle: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        role: AIChatRole,
        content: Content,
        conversationTitle: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.conversationTitle = conversationTitle
        self.createdAt = createdAt
    }
}

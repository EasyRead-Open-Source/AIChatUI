//
//  ChatMessage.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// A message model for AI chat conversations.
public struct ChatMessage: Identifiable, Sendable {
    public enum Role: String, Codable, Sendable {
        case user
        case assistant
    }

    public let id: UUID
    public let role: Role
    public var text: String?
    public var imageData: Data?
    public var body: String?
    public var isProgressing: Bool
    public var isError: Bool

    public init(
        id: UUID,
        role: Role,
        text: String? = nil,
        imageData: Data? = nil,
        body: String? = nil,
        isProgressing: Bool = false,
        isError: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.imageData = imageData
        self.body = body
        self.isProgressing = isProgressing
        self.isError = isError
    }

    public static func user(text: String?, imageData: Data?) -> ChatMessage {
        ChatMessage(
            id: UUID(),
            role: .user,
            text: text,
            imageData: imageData
        )
    }

    public static func assistant(
        id: UUID,
        body: String,
        isProgressing: Bool,
        isError: Bool
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            role: .assistant,
            body: body,
            isProgressing: isProgressing,
            isError: isError
        )
    }
}

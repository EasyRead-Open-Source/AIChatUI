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

/// A message model, corresponding to the original ChatMessage.
public struct ChatMessage: Identifiable, Sendable {
    public enum Role: String, Codable, Sendable {
        case user
        case assistant
    }

    public let id: UUID
    public let role: Role
    public var text: String?
    public var imageData: Data?
    public var title: String?
    public var body: String?
    public var progress: Double?
    public var isProgressing: Bool
    public var isError: Bool

    public init(
        id: UUID,
        role: Role,
        text: String? = nil,
        imageData: Data? = nil,
        title: String? = nil,
        body: String? = nil,
        progress: Double? = nil,
        isProgressing: Bool = false,
        isError: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.imageData = imageData
        self.title = title
        self.body = body
        self.progress = progress
        self.isProgressing = isProgressing
        self.isError = isError
    }

    public static func user(text: String?, imageData: Data?) -> ChatMessage {
        ChatMessage(
            id: UUID(),
            role: .user,
            text: text,
            imageData: imageData,
            isProgressing: false,
            isError: false
        )
    }

    public static func assistant(
        id: UUID,
        title: String,
        body: String,
        progress: Double,
        isProgressing: Bool,
        isError: Bool
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            role: .assistant,
            title: title,
            body: body,
            progress: progress,
            isProgressing: isProgressing,
            isError: isError
        )
    }
}

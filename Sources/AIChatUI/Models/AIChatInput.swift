//
//  AIChatInput.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/8/26
//

import Foundation

/// Everything the user submitted in a single turn.
public struct AIChatInput: Identifiable, Hashable, Sendable {
    public struct Attachment: Identifiable, Hashable, Sendable {
        public enum Kind: String, Hashable, Sendable {
            case image
            case video
            case file
        }

        public var id: UUID
        public var kind: Kind
        public var data: Data
        public var fileName: String
        public var mimeType: String?

        public init(
            id: UUID = UUID(),
            kind: Kind,
            data: Data,
            fileName: String,
            mimeType: String? = nil
        ) {
            self.id = id
            self.kind = kind
            self.data = data
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }

    public var id: UUID
    public var text: String?
    public var attachments: [Attachment]
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        text: String? = nil,
        attachments: [Attachment] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.attachments = attachments
        self.createdAt = createdAt
    }
}

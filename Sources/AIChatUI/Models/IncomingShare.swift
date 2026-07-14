//
//  IncomingShare.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import Foundation

/// Pending share data awaiting import.
public struct IncomingShare: Identifiable, Sendable {
    public let id: UUID
    public let text: String?
    public let hasImage: Bool

    public init(id: UUID, text: String?, hasImage: Bool) {
        self.id = id
        self.text = text
        self.hasImage = hasImage
    }
}

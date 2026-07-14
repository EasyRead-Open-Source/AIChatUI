//
//  MessageInput.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import Foundation

/// Input for sending a message.
public struct MessageInput: Sendable {
    public let text: String?
    public let imageData: Data?

    public init(text: String?, imageData: Data? = nil) {
        self.text = text
        self.imageData = imageData
    }
}

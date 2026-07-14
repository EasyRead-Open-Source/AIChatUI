//
//  MessageRow.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI

struct MessageRow: View {
    let message: ChatMessage
    let aiName: String
    let avatarImage: UIImage?
    let avatarFallbackText: String

    var body: some View {
        switch message.role {
        case .user:
            UserMessageRow(message: message)
        case .assistant:
            AssistantMessageRow(
                message: message,
                aiName: aiName,
                avatarImage: avatarImage,
                avatarFallbackText: avatarFallbackText
            )
        }
    }
}

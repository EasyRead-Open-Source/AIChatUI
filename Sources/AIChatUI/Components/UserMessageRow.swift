//
//  UserMessageRow.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI

struct UserMessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 48)

            VStack(alignment: .trailing, spacing: 8) {
                if let text = message.text, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .accessibilityIdentifier("aiChat.userMessage")
    }
}

//
//  AssistantMessageRow.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI

struct AssistantMessageRow: View {
    let message: ChatMessage
    let aiName: String
    let avatarImage: UIImage?
    let avatarFallbackText: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AssistantAvatarView(avatarImage: avatarImage, fallbackText: avatarFallbackText)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(aiName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(message.title ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if message.isProgressing {
                        ProgressView(value: message.progress ?? 0)
                            .tint(.accentColor)
                    }

                    Text(message.body ?? "")
                        .font(.body)
                        .foregroundStyle(message.isError ? Color.red : Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Spacer(minLength: 48)
        }
        .accessibilityIdentifier("aiChat.responseStatus")
    }
}

private struct AssistantAvatarView: View {
    let avatarImage: UIImage?
    let fallbackText: String

    var body: some View {
        Group {
            if let avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.accentColor.opacity(0.18))
                    .overlay(
                        Text(String(fallbackText.prefix(1)))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    )
            }
        }
        .frame(width: 20, height: 20)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.secondary.opacity(0.16), lineWidth: 0.5))
    }
}

//
//  AssistantMessageRow.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import MarkdownView

struct AssistantMessageRow: View {
    let message: ChatMessage
    let aiName: String
    let avatarImage: UIImage?
    let avatarFallbackText: String

    @State private var markdownSource = StreamingMarkdownSource()

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AssistantAvatarView(avatarImage: avatarImage, fallbackText: avatarFallbackText)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(aiName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    messageBodyView
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Spacer(minLength: 48)
        }
        .accessibilityIdentifier("aiChat.responseStatus")
        .onAppear {
            markdownSource.text = message.body ?? ""
            if !message.isProgressing {
                markdownSource.finishStreaming()
            }
        }
        .onChange(of: message.body ?? "") { _, newBody in
            markdownSource.text = newBody
        }
        .onChange(of: message.isProgressing) { _, isProgressing in
            if !isProgressing {
                markdownSource.finishStreaming()
            }
        }
    }

    @ViewBuilder
    private var messageBodyView: some View {
        if message.isError {
            Text(message.body ?? "")
                .font(.body)
                .foregroundStyle(Color.red)
                .fixedSize(horizontal: false, vertical: true)
        } else if message.isProgressing {
            StreamingMarkdownReader(markdownSource) { parseResult in
                MarkdownView(parseResult)
            }
        } else {
            MarkdownView(message.body ?? "")
        }
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

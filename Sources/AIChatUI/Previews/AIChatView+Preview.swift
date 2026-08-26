//
//  AIChatView+Preview.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/8/26
//

#if DEBUG
import SwiftUI

@MainActor
private struct AIChatPreviewContainer: View {
    private static let analyst = AIChatRole(
        id: "analyst",
        name: "Analyst",
        subtitle: "Data & Reasoning"
    )

    private static let designer = AIChatRole(
        id: "designer",
        name: "Designer",
        subtitle: "Interaction Design"
    )

    @State private var conversation = AIConversation(
        title: "Product Discussion",
        messages: [
            .user(AIChatInput(text: "Please review the design of this AI chat interface.")),
            .assistant(
                AIChatResponse(
                    role: analyst,
                    content: .markdown(
                        """
                        ### Initial Review

                        - The hierarchy is clear
                        - The dark background supports an immersive conversation
                        - The composer remains anchored at the bottom
                        """
                    )
                )
            ),
            .assistant(
                AIChatResponse(
                    role: designer,
                    content: .view(
                        PreviewRecommendationCard(
                            title: "Interaction Recommendation",
                            detail: "Keep a distinct avatar and name for every AI role."
                        )
                    )
                )
            )
        ]
    )

    var body: some View {
        AIChatView(
            conversation: $conversation,
            roles: [Self.analyst, Self.designer],
            reminderArea: {
                Text("Reminder")
            }, onDismiss: {}
        ) { _, update in
            let responseID = UUID()
            let chunks = [
                "### Streaming Response\n\n",
                "Content is arriving in chunks. ",
                "Every update reuses the same `response.id`, ",
                "so the interface updates only the current message."
            ]
            var accumulatedText = ""

            for chunk in chunks {
                try Task.checkCancellation()
                accumulatedText += chunk
                update(
                    AIChatResponse(
                        id: responseID,
                        role: Self.analyst,
                        content: .markdown(accumulatedText),
                        conversationTitle: accumulatedText == chunks[0] ? "Streaming Demo" : nil
                    )
                )
                try await Task.sleep(for: .milliseconds(450))
            }
        }
    }
}

private struct PreviewRecommendationCard: View {
    let title: String
    let detail: String
    @State private var isExpanded = false

    var body: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: "sparkles")
                    .font(.headline)
                if isExpanded {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    AIChatPreviewContainer()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    AIChatPreviewContainer()
        .preferredColorScheme(.dark)
}

#Preview("Empty Conversation") {
    @Previewable @State var conversation = AIConversation()

    AIChatView(
        conversation: $conversation,
        role: AIChatRole(name: "AI")
    ) { _ in
        AIChatResponse(
            role: AIChatRole(name: "AI"),
            content: .markdown("Hello! How can I help?")
        )
    }
}
#endif

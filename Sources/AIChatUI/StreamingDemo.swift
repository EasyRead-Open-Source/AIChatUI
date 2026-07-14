//
//  StreamingDemo.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/15
//

import SwiftUI

/// A #Preview demo using AIChatView to simulate AI streaming with markdown rendering.
///
/// The `submitMessage` closure streams markdown word-by-word through the `onText` callback,
/// which drives `StreamingMarkdownReader` inside `AssistantMessageRow` for incremental rendering.
#Preview {
    AIChatView(configuration: AIChatConfiguration(
        aiName: "AI Assistant",
        aiDisclaimer: "AI-generated content",
        inputPlaceholder: "Type any message to start the demo...",
        suggestions: [
            ChatSuggestion(title: "Markdown", subtitle: "Show streaming markdown rendering"),
            ChatSuggestion(title: "Code Block", subtitle: "Show syntax highlighting"),
        ],
        submitMessage: { input, onText in
            let response = #"""
            # 👋 Hello, I'm your AI Assistant

            This is a **streaming Markdown** rendering demo.

            ## Features

            - Supports **bold** and *italic*
            - Supports `inline code` display
            - Supports syntax-highlighted code blocks

            ```swift
            struct ContentView: View {
                var body: some View {
                    Text("Hello, World!")
                }
            }
            ```

            > Streaming output makes the experience feel smooth and natural.

            ### Table Support

            | Feature | Status |
            |---------|--------|
            | Streaming | ✅ |
            | Code Highlighting | ✅ |
            | Math Rendering | ✅ |

            ---

            Hope this demo helps! 🎉
            """#

            let words = response.split(separator: " ")
            var accumulated = ""
            for word in words {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 60...120)))
                accumulated += (accumulated.isEmpty ? "" : " ") + word
                onText(accumulated)
            }
        }
    ))
}

//
//  StreamingDemo.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/15
//

import SwiftUI
import MarkdownView


struct StreamingDemo: View {
    @State private var markdownSource = StreamingMarkdownSource()
    @State private var isStreaming = false
    @State private var showReset = false

    private let fullResponse = """
    #  👋  Hello, I am an AI assistant

    This is a streaming Markov rendering demonstration.

    ## Functional Features

    - Support **bold** and *italic*
    - Support `inline code` display
    - Support code block syntax highlighting

    ```swift
    struct ContentView: View {
        var body: some View {
            Text("Hello, World!")
        }
    }
    ```

    > Streaming output makes the user experience smoother and more natural.

    ### Table support

    | Characteristics | Status |
    | ------ | ------ |
    | Streaming rendering | ✅ |
    | Code Highlighting | ✅ |
    | Mathematical formulas | ✅ |

    ---

    I hope this demonstration is helpful to you! 🎉
    """

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                StreamingMarkdownReader(markdownSource) { parseResult in
                    MarkdownView(parseResult)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color(.systemGroupedBackground))
            .defaultScrollAnchor(.bottom)

            Divider()

            HStack(spacing: 12) {
                Button(action: startStreaming) {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isStreaming)

                if showReset {
                    Button(action: resetStreaming) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    private func startStreaming() {
        isStreaming = true
        showReset = false
        markdownSource = StreamingMarkdownSource()

        Task {
            let words = fullResponse.split(separator: " ")
            var accumulated = ""
            for (index, word) in words.enumerated() {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 60...140)))
                accumulated += (accumulated.isEmpty ? "" : " ") + word
                markdownSource.text = accumulated
            }
            markdownSource.finishStreaming()
            isStreaming = false
            showReset = true
        }
    }

    private func resetStreaming() {
        markdownSource = StreamingMarkdownSource()
        showReset = false
    }
}

#Preview {
    StreamingDemo()
}

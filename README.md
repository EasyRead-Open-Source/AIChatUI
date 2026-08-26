# AIChatUI

AIChatUI is a reusable SwiftUI package for building single-role and multi-role AI conversations. The host app owns the conversation state and provides an asynchronous send closure, while AIChatUI handles message presentation, streaming updates, Markdown, custom SwiftUI content, attachments, speech input, localization, and platform-adaptive layout.

## Features

- Single-role and multi-role conversations
- Parent-owned conversation state through `Binding<AIConversation>`
- Streaming responses that update one message in place
- Markdown responses rendered with `MarkdownView.MarkdownText`
- Stateful custom SwiftUI views inside assistant responses
- Text, image, video, and file attachment models
- Camera capture on iOS and photo/video selection on supported platforms
- Press-and-hold speech-to-text input on iOS, macOS, and visionOS
- Dynamic conversation titles supplied by callback updates
- Light mode, dark mode, Material surfaces, and Liquid Glass where available
- English base localization with Simplified Chinese translations
- Platform-adaptive layouts for iOS, macOS, tvOS, watchOS, and visionOS

AIChatUI does not display a separate “waiting for response” message after the user sends a message. A response appears when the send handler provides its first update.

## Requirements

| Platform | Minimum version |
|---|---:|
| iOS / iPadOS | 18.0 |
| macOS | 15.0 |
| tvOS | 18.0 |
| watchOS | 11.0 |
| visionOS | 2.0 |

- Swift 6.0+
- Xcode with support for the selected platform SDK

## Installation

Add the repository in Xcode through **File → Add Package Dependencies**, using:

```text
https://github.com/EasyRead-Open-Source/AIChatUI.git
```

Alternatively, add it to `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/EasyRead-Open-Source/AIChatUI.git",
        branch: "main"
    )
]
```

Then add `AIChatUI` to the target dependencies and import it:

```swift
import AIChatUI
```

## Single-role conversation

Use the convenience initializer when every response comes from one AI role:

```swift
import AIChatUI
import SwiftUI

struct ChatScreen: View {
    private let assistant = AIChatRole(
        id: "assistant",
        name: "Assistant",
        subtitle: "General"
    )

    @State private var conversation = AIConversation()

    var body: some View {
        AIChatView(
            conversation: $conversation,
            role: assistant
        ) { input in
            let result = try await chatService.send(input)

            return AIChatResponse(
                role: assistant,
                content: .markdown(result.text),
                conversationTitle: result.suggestedTitle
            )
        }
    }
}
```

If `conversation.title` is `nil`, the chat header uses the localized default, “Conversation”. A custom `title` passed to `AIChatView` changes that fallback.

## Multi-role streaming conversation

Each `AIChatResponse` identifies the role that produced it. Call `update` repeatedly with the same response ID to replace that response in place:

```swift
struct MultiRoleChatScreen: View {
    private let analyst = AIChatRole(
        id: "analyst",
        name: "Analyst",
        subtitle: "Data & Reasoning"
    )

    private let designer = AIChatRole(
        id: "designer",
        name: "Designer",
        subtitle: "Interaction Design"
    )

    @State private var conversation = AIConversation()

    var body: some View {
        AIChatView(
            conversation: $conversation,
            roles: [analyst, designer]
        ) { input, update in
            let responseID = UUID()
            var accumulatedText = ""

            for try await chunk in chatService.stream(input) {
                accumulatedText += chunk.text

                update(
                    AIChatResponse(
                        id: responseID,
                        role: chunk.roleID == designer.id ? designer : analyst,
                        content: .markdown(accumulatedText),
                        conversationTitle: chunk.isFirst ? chunk.suggestedTitle : nil
                    )
                )
            }
        }
    }
}
```

Use a stable response ID for one streaming message. A new ID appends another assistant message. `conversationTitle` can be supplied on any update; it is normally set only on the first response.

## Custom response views

Responses can contain a type-erased SwiftUI view instead of Markdown:

```swift
AIChatResponse(
    role: assistant,
    content: .view(
        ProgressCard(progress: progressStore)
    )
)
```

The embedded view can use `@State`, Observation, bindings, animations, or any other SwiftUI data flow. It continues updating inside the same conversation message.

## Input and attachments

The send handler receives an `AIChatInput` containing optional text, attachments, and a creation date. Each attachment includes its kind, raw data, file name, and optional MIME type:

```swift
AIChatInput.Attachment(
    kind: .image,
    data: imageData,
    fileName: "photo.jpg",
    mimeType: "image/jpeg"
)
```

Supported attachment kinds are `.image`, `.video`, and `.file`. The host app is responsible for uploading or otherwise processing the received data.

## Parent-owned conversation state

`AIConversation` is passed as a binding, so the parent view can inspect, save, replace, edit, or delete conversation content:

```swift
@State private var conversation = AIConversation(title: "Project Review")

AIChatView(
    conversation: $conversation,
    role: assistant,
    onSend: sendMessage
)
```

For example:

```swift
conversation.title = "New title"
conversation.removeMessage(id: messageID)
conversation.removeAllMessages()
save(conversation)
```

Messages are represented by `AIConversation.Message.user` and `.assistant`.

## Permissions

Apps using speech input must provide these usage descriptions in the host app:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Use the microphone to transcribe speech.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Convert speech into message text.</string>
```

iOS apps using camera capture must also provide:

```xml
<key>NSCameraUsageDescription</key>
<string>Capture images to attach to a conversation.</string>
```

A sandboxed macOS app must enable audio input in its App Sandbox capabilities when speech input is used.

## Platform behavior

| Capability | iOS / iPadOS | macOS | tvOS | watchOS | visionOS |
|---|:---:|:---:|:---:|:---:|:---:|
| Text chat and streaming | ✓ | ✓ | ✓ | ✓ | ✓ |
| Markdown and custom views | ✓ | ✓ | ✓ | ✓ | ✓ |
| Photo/video picker | ✓ | ✓ | — | — | ✓ |
| Camera capture | ✓ | — | — | — | — |
| Press-and-hold speech input | ✓ | ✓ | — | — | ✓ |
| Liquid Glass on version 26+ | ✓ | ✓ | ✓ | ✓ | — |

visionOS uses a native Material surface because SwiftUI currently marks `glassEffect` unavailable there. Mac Catalyst follows the iOS layout and capability paths, except camera capture is not shown.

## Localization

Package-owned strings use English as the source language and include Simplified Chinese translations in [`Localizable.xcstrings`](Sources/AIChatUI/Resources/Localizable.xcstrings). Strings are loaded from `Bundle.module`, so the host app does not need to duplicate the package’s localization keys.

Caller-provided values such as role names, conversation titles, response content, and a custom `title` or `placeholder` remain the host app’s responsibility to localize.

## Appearance

AIChatUI uses semantic SwiftUI colors and Material surfaces, supports light and dark appearance automatically, and adopts Liquid Glass on supported version 26+ platforms. Layout measurements are tuned independently for compact watch interfaces, touch interfaces, macOS windows, television focus navigation, and spatial windows.

## License

AIChatUI is available under the MIT License. See `LICENSE` for details.

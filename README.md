# AIChatUI

> [!IMPORTANT]
>
> This project is currently **not completed** and there may be changes to the API. The current status is only for experimental projects.
>
> **Waiting for refactoring.**

A reusable SwiftUI chat interface for AI-powered conversations, distributed as a Swift Package.

## Overview

AIChatUI provides a complete chat UI with no hardcoded branding. All text, icons, and business logic are injected by the host app through `AIChatConfiguration` closures, making it suitable for any AI chat use case.

## Features

- Full chat interface with message bubbles for user and assistant
- Image attachment support (camera and photo library)
- Conversation history with rename and delete
- Streaming generation progress display
- Quick suggestion strip
- Share extension import handling
- Pure SwiftUI with UIKit wrappers where needed

## Requirements

- iOS 18.0+
- Swift 6.0+

## Installation

Add the package as a local dependency in your Xcode project or `Package.swift`:

```swift
.package(path: "AIChatUI")
```

## Quick Start

```swift
import AIChatUI

AIChatView(configuration: AIChatConfiguration(
    aiName: "My Assistant",
    submitMessage: { input, onUpdate in
        // Call your AI generation API here
        let result = try await myAIService.process(input)
        onUpdate(result.statusUpdate)
    }
))
```

## Configuration

`AIChatConfiguration` uses a closure-based pattern where the host app injects all behavior:

| Closure | Purpose |
|---|---|
| `validateSession` | Check if the user session is valid |
| `loadConversations` | Return the list of conversation summaries |
| `loadConversationDetail` | Load full conversation details by ID |
| `saveConversation` | Persist a conversation |
| `deleteConversation` | Delete a conversation |
| `renameConversation` | Rename a conversation |
| `submitMessage` | Send a message to the AI and receive streaming updates |
| `requestCamera` / `requestPhotoLibrary` | Handle image capture (optional) |
| `pendingShare` / `shareImageData` / `resolveShare` | Handle share extension imports (optional) |

All closures have sensible defaults so you only need to configure what you use.

## Localization

All user-facing strings are configured through `AIChatConfiguration` properties. There are no hardcoded strings in the package, making it easy to localize for any language.

## License

MIT

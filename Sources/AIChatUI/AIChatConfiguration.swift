//
//  AIChatConfiguration.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Suggestion

/// A quick suggestion item displayed in the suggestion strip above the input area.
public struct ChatSuggestion: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - Configuration

/// Closure-based configuration — all text, icons, and business logic are injected by the host.
/// The package contains no hardcoded branding.
///
/// Minimal usage:
/// ```swift
/// AIChatView(configuration: AIChatConfiguration(
///     aiName: "My Assistant",
///     submitMessage: { input, onText in ... }
/// ))
/// ```
public struct AIChatConfiguration: @unchecked Sendable {

    // MARK: - AI Branding

    public var aiName: String
    public var aiDisclaimer: String
    public var avatarImage: (@MainActor @Sendable () -> UIImage?)?
    public var avatarFallbackText: String

    // MARK: - Header

    public var newConversationTitle: String
    public var headerSubtitle: String

    // MARK: - Input Area

    public var inputPlaceholder: String
    public var imageOnlyConversationTitle: String
    public var sendAccessibilityLabel: String
    public var attachAccessibilityLabel: String

    // MARK: - Suggestions

    public var suggestions: [ChatSuggestion]

    // MARK: - Common Buttons

    public var cancelButtonTitle: String
    public var doneButtonTitle: String
    public var deleteButtonTitle: String
    public var okButtonTitle: String
    public var cameraButtonTitle: String
    public var photoLibraryButtonTitle: String
    public var unknownErrorMessage: String

    // MARK: - History Panel

    public var historyTitle: String
    public var historyEmptyTitle: String
    public var historyRenameAction: String
    public var historyRenamePlaceholder: String
    public var historyRenameAlertTitle: String

    // MARK: - Alerts

    public var generationFailedTitle: String

    // MARK: - Closures: Business Logic

    public var validateSession: @MainActor @Sendable () -> Bool
    public var loadConversations: @MainActor @Sendable () -> [ConversationSummary]
    public var loadConversationDetail: @MainActor @Sendable (UUID) -> ConversationDetail?
    public var saveConversation: @MainActor @Sendable (ConversationDetail) throws -> Void
    public var deleteConversation: @MainActor @Sendable (UUID) throws -> Void
    public var renameConversation: @MainActor @Sendable (UUID, String) throws -> Void
    /// Submits a message for AI generation. The `onText` callback receives the accumulated text as it streams.
    public var submitMessage: @MainActor @Sendable (MessageInput, @escaping @Sendable (String) -> Void) async throws -> Void
    public var requestCamera: @MainActor @Sendable (@escaping @Sendable (Data?) -> Void) -> Void
    public var requestPhotoLibrary: @MainActor @Sendable (@escaping @Sendable (Data?) -> Void) -> Void

    // MARK: - Init

    public init(
        aiName: String = "AI",
        aiDisclaimer: String = "",
        avatarImage: (@MainActor @Sendable () -> UIImage?)? = nil,
        avatarFallbackText: String = "AI",
        newConversationTitle: String = "New Conversation",
        headerSubtitle: String = "Auto",
        inputPlaceholder: String = "Type a message...",
        imageOnlyConversationTitle: String = "Image",
        sendAccessibilityLabel: String = "Send",
        attachAccessibilityLabel: String = "Attach",
        suggestions: [ChatSuggestion] = [],
        cancelButtonTitle: String = "Cancel",
        doneButtonTitle: String = "Done",
        deleteButtonTitle: String = "Delete",
        okButtonTitle: String = "OK",
        cameraButtonTitle: String = "Camera",
        photoLibraryButtonTitle: String = "Photos",
        unknownErrorMessage: String = "An unknown error occurred",
        historyTitle: String = "History",
        historyEmptyTitle: String = "No conversations yet",
        historyRenameAction: String = "Rename",
        historyRenamePlaceholder: String = "Conversation name",
        historyRenameAlertTitle: String = "Rename Conversation",
        generationFailedTitle: String = "Generation Failed",
        validateSession: @escaping @MainActor @Sendable () -> Bool = { true },
        loadConversations: @escaping @MainActor @Sendable () -> [ConversationSummary] = { [] },
        loadConversationDetail: @escaping @MainActor @Sendable (UUID) -> ConversationDetail? = { _ in nil },
        saveConversation: @escaping @MainActor @Sendable (ConversationDetail) throws -> Void = { _ in },
        deleteConversation: @escaping @MainActor @Sendable (UUID) throws -> Void = { _ in },
        renameConversation: @escaping @MainActor @Sendable (UUID, String) throws -> Void = { _, _ in },
        submitMessage: @escaping @MainActor @Sendable (MessageInput, @escaping @Sendable (String) -> Void) async throws -> Void = { _, _ in },
        requestCamera: @escaping @MainActor @Sendable (@escaping @Sendable (Data?) -> Void) -> Void = { $0(nil) },
        requestPhotoLibrary: @escaping @MainActor @Sendable (@escaping @Sendable (Data?) -> Void) -> Void = { $0(nil) }
    ) {
        self.aiName = aiName
        self.aiDisclaimer = aiDisclaimer
        self.avatarImage = avatarImage
        self.avatarFallbackText = avatarFallbackText
        self.newConversationTitle = newConversationTitle
        self.headerSubtitle = headerSubtitle
        self.inputPlaceholder = inputPlaceholder
        self.imageOnlyConversationTitle = imageOnlyConversationTitle
        self.sendAccessibilityLabel = sendAccessibilityLabel
        self.attachAccessibilityLabel = attachAccessibilityLabel
        self.suggestions = suggestions
        self.cancelButtonTitle = cancelButtonTitle
        self.doneButtonTitle = doneButtonTitle
        self.deleteButtonTitle = deleteButtonTitle
        self.okButtonTitle = okButtonTitle
        self.cameraButtonTitle = cameraButtonTitle
        self.photoLibraryButtonTitle = photoLibraryButtonTitle
        self.unknownErrorMessage = unknownErrorMessage
        self.historyTitle = historyTitle
        self.historyEmptyTitle = historyEmptyTitle
        self.historyRenameAction = historyRenameAction
        self.historyRenamePlaceholder = historyRenamePlaceholder
        self.historyRenameAlertTitle = historyRenameAlertTitle
        self.generationFailedTitle = generationFailedTitle
        self.validateSession = validateSession
        self.loadConversations = loadConversations
        self.loadConversationDetail = loadConversationDetail
        self.saveConversation = saveConversation
        self.deleteConversation = deleteConversation
        self.renameConversation = renameConversation
        self.submitMessage = submitMessage
        self.requestCamera = requestCamera
        self.requestPhotoLibrary = requestPhotoLibrary
    }
}

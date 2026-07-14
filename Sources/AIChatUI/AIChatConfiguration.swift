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
/// Minimal usage (configure only the AI name and message submission):
/// ```swift
/// AIChatView(configuration: AIChatConfiguration(
///     aiName: "My Assistant",
///     submitMessage: { input, onUpdate in ... }
/// ))
/// ```
///
/// Full usage:
/// ```swift
/// AIChatView(configuration: AIChatConfiguration(
///     aiName: "EasyRead",
///     inputPlaceholder: "Describe the picture book you want to create...",
///     suggestions: [
///         ChatSuggestion(title: "Bedtime Story", subtitle: "Tell a short story about courage"),
///     ],
///     submitMessage: { input, onUpdate in ... },
///     saveConversation: { detail in ... }
/// ))
/// ```
public struct AIChatConfiguration: @unchecked Sendable {

    // MARK: - AI Branding

    /// The AI name displayed in message bubbles and the header title.
    public var aiName: String

    /// A disclaimer suffix appended after the AI name (e.g. "AI-generated content may be inaccurate").
    public var aiDisclaimer: String

    /// Default avatar image; falls back to the first letter of `avatarFallbackText` when `nil`.
    public var avatarImage: (@MainActor @Sendable () -> UIImage?)?

    /// Fallback text for the avatar (displays the first character).
    public var avatarFallbackText: String

    // MARK: - Header

    /// Title shown when there are no conversations.
    public var newConversationTitle: String

    /// Header subtitle (e.g. "Auto").
    public var headerSubtitle: String

    // MARK: - Input Area

    /// Placeholder text for the input field.
    public var inputPlaceholder: String

    /// Accessibility label for the send button.
    public var sendAccessibilityLabel: String

    /// Accessibility label for the attach button.
    public var attachAccessibilityLabel: String

    // MARK: - Suggestions

    /// The list of suggestions displayed above the input area; hidden when empty.
    public var suggestions: [ChatSuggestion]

    // MARK: - Response Status Text

    /// Title displayed while processing.
    public var processingTitle: String

    /// Title displayed when completed.
    public var completedTitle: String

    /// Title displayed on error.
    public var errorTitle: String

    /// Body text shown when generation starts.
    public var startingBody: String

    /// Body format string when completed (use `%@` as placeholder for the result title).
    public var completedBodyFormat: String

    /// Title for an image-only conversation.
    public var imageOnlyConversationTitle: String

    // MARK: - History Panel

    /// Title for the history panel.
    public var historyTitle: String

    /// Placeholder shown when history is empty.
    public var historyEmptyTitle: String

    /// Label for the rename action.
    public var historyRenameAction: String

    /// Placeholder for the rename text field.
    public var historyRenamePlaceholder: String

    /// Title for the rename alert.
    public var historyRenameAlertTitle: String

    // MARK: - Common Buttons

    public var cancelButtonTitle: String
    public var doneButtonTitle: String
    public var deleteButtonTitle: String
    public var okButtonTitle: String
    public var cameraButtonTitle: String
    public var photoLibraryButtonTitle: String
    public var unknownErrorMessage: String

    // MARK: - Share Import Dialog

    public var shareImportReplaceTitle: String
    public var shareImportReplaceMessage: String
    public var shareImportReplaceAction: String
    public var shareImportLaterAction: String
    public var shareImportErrorTitle: String
    public var shareImportErrorMessage: String
    public var shareImportErrorOK: String

    // MARK: - Generation Failure Dialog

    public var generationFailedTitle: String

    // MARK: - Closures: Business Logic

    public var validateSession: @MainActor @Sendable () -> Bool
    public var loadConversations: @MainActor @Sendable () -> [ConversationSummary]
    public var loadConversationDetail: @MainActor @Sendable (UUID) -> ConversationDetail?
    public var saveConversation: @MainActor @Sendable (ConversationDetail) throws -> Void
    public var deleteConversation: @MainActor @Sendable (UUID) throws -> Void
    public var renameConversation: @MainActor @Sendable (UUID, String) throws -> Void
    public var submitMessage: @MainActor @Sendable (MessageInput, @escaping @Sendable (GenerationStatusUpdate) -> Void) async -> Void
    public var requestCamera: @MainActor @Sendable (@escaping @Sendable (Data?) -> Void) -> Void
    public var requestPhotoLibrary: @MainActor @Sendable (@escaping @Sendable (Data?) -> Void) -> Void
    public var pendingShare: @MainActor @Sendable () -> IncomingShare?
    public var shareImageData: @MainActor @Sendable (IncomingShare) throws -> Data?
    public var resolveShare: @MainActor @Sendable (IncomingShare) throws -> Void

    // MARK: - Init

    public init(
        aiName: String = "AI",
        aiDisclaimer: String = "",
        avatarImage: (@MainActor @Sendable () -> UIImage?)? = nil,
        avatarFallbackText: String = "AI",
        newConversationTitle: String = "New Conversation",
        headerSubtitle: String = "Auto",
        inputPlaceholder: String = "Type a message...",
        sendAccessibilityLabel: String = "Send",
        attachAccessibilityLabel: String = "Attach",
        suggestions: [ChatSuggestion] = [],
        processingTitle: String = "Processing",
        completedTitle: String = "Completed",
        errorTitle: String = "Error",
        startingBody: String = "Starting...",
        completedBodyFormat: String = "Completed: %@",
        imageOnlyConversationTitle: String = "Image",
        historyTitle: String = "History",
        historyEmptyTitle: String = "No conversations yet",
        historyRenameAction: String = "Rename",
        historyRenamePlaceholder: String = "Conversation name",
        historyRenameAlertTitle: String = "Rename Conversation",
        cancelButtonTitle: String = "Cancel",
        doneButtonTitle: String = "Done",
        deleteButtonTitle: String = "Delete",
        okButtonTitle: String = "OK",
        cameraButtonTitle: String = "Camera",
        photoLibraryButtonTitle: String = "Photos",
        unknownErrorMessage: String = "An unknown error occurred",
        shareImportReplaceTitle: String = "Replace Content",
        shareImportReplaceMessage: String = "This will replace the current input.",
        shareImportReplaceAction: String = "Use Shared Content",
        shareImportLaterAction: String = "Later",
        shareImportErrorTitle: String = "Unable to Import",
        shareImportErrorMessage: String = "The shared content could not be imported.",
        shareImportErrorOK: String = "OK",
        generationFailedTitle: String = "Generation Failed",
        validateSession: @escaping @MainActor @Sendable () -> Bool = { true },
        loadConversations: @escaping @MainActor @Sendable () -> [ConversationSummary] = { [] },
        loadConversationDetail: @escaping @MainActor @Sendable (UUID) -> ConversationDetail? = { _ in nil },
        saveConversation: @escaping @MainActor @Sendable (ConversationDetail) throws -> Void = { _ in },
        deleteConversation: @escaping @MainActor @Sendable (UUID) throws -> Void = { _ in },
        renameConversation: @escaping @MainActor @Sendable (UUID, String) throws -> Void = { _, _ in },
        submitMessage: @escaping @MainActor @Sendable (MessageInput, @escaping @Sendable (GenerationStatusUpdate) -> Void) async -> Void = { _, _ in },
        requestCamera: @escaping @MainActor @Sendable (@escaping @Sendable (Data?) -> Void) -> Void = { $0(nil) },
        requestPhotoLibrary: @escaping @MainActor @Sendable (@escaping @Sendable (Data?) -> Void) -> Void = { $0(nil) },
        pendingShare: @escaping @MainActor @Sendable () -> IncomingShare? = { nil },
        shareImageData: @escaping @MainActor @Sendable (IncomingShare) throws -> Data? = { _ in nil },
        resolveShare: @escaping @MainActor @Sendable (IncomingShare) throws -> Void = { _ in }
    ) {
        self.aiName = aiName
        self.aiDisclaimer = aiDisclaimer
        self.avatarImage = avatarImage
        self.avatarFallbackText = avatarFallbackText
        self.newConversationTitle = newConversationTitle
        self.headerSubtitle = headerSubtitle
        self.inputPlaceholder = inputPlaceholder
        self.sendAccessibilityLabel = sendAccessibilityLabel
        self.attachAccessibilityLabel = attachAccessibilityLabel
        self.suggestions = suggestions
        self.processingTitle = processingTitle
        self.completedTitle = completedTitle
        self.errorTitle = errorTitle
        self.startingBody = startingBody
        self.completedBodyFormat = completedBodyFormat
        self.imageOnlyConversationTitle = imageOnlyConversationTitle
        self.historyTitle = historyTitle
        self.historyEmptyTitle = historyEmptyTitle
        self.historyRenameAction = historyRenameAction
        self.historyRenamePlaceholder = historyRenamePlaceholder
        self.historyRenameAlertTitle = historyRenameAlertTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.doneButtonTitle = doneButtonTitle
        self.deleteButtonTitle = deleteButtonTitle
        self.okButtonTitle = okButtonTitle
        self.cameraButtonTitle = cameraButtonTitle
        self.photoLibraryButtonTitle = photoLibraryButtonTitle
        self.unknownErrorMessage = unknownErrorMessage
        self.shareImportReplaceTitle = shareImportReplaceTitle
        self.shareImportReplaceMessage = shareImportReplaceMessage
        self.shareImportReplaceAction = shareImportReplaceAction
        self.shareImportLaterAction = shareImportLaterAction
        self.shareImportErrorTitle = shareImportErrorTitle
        self.shareImportErrorMessage = shareImportErrorMessage
        self.shareImportErrorOK = shareImportErrorOK
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
        self.pendingShare = pendingShare
        self.shareImageData = shareImageData
        self.resolveShare = resolveShare
    }
}

//
//  AIChatView.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A reusable chat interface for AI-powered conversations.
///
/// Interacts with the host app through `AIChatConfiguration` closures,
/// decoupling conversation persistence, generation APIs, photo picking,
/// and external share handling.
///
/// Example usage:
/// ```swift
/// AIChatView(configuration: AIChatConfiguration(
///     validateSession: { UserHelper.shared.token.isEmpty == false },
///     loadConversations: { /* [ConversationSummary] */ },
///     saveConversation: { detail in try modelContext.save() },
///     submitMessage: { input, onUpdate in
///         try await generateService.process(input: input, onUpdate: onUpdate)
///     }
/// ))
/// ```
public struct AIChatView: View {
    private let configuration: AIChatConfiguration

    @StateObject private var statusManager = AIChatStatusManager()
    @State private var inputText = ""
    @State private var selectedImageData: Data?
    @State private var messages: [ChatMessage] = []
    @State private var activeConversationID: UUID?
    @State private var activeConversationTitle: String?
    @State private var showHistory = false
    @State private var showRenameAlert = false
    @State private var renameTitle = ""
    @State private var renameTargetID: UUID?
    @State private var activeResponseMessageID: UUID?
    @State private var generationTask: Task<Void, Never>?
    @State private var importedShare: IncomingShare?
    @State private var shareAwaitingReplacement: IncomingShare?
    @State private var importErrorMessage: String?
    @State private var persistenceErrorMessage: String?
    @State private var conversations: [ConversationSummary] = []
    @State private var isCameraPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var isShareCheckScheduled = false
    @FocusState private var isInputFocused: Bool

    private var suggestions: [ChatSuggestion] { configuration.suggestions }

    public init(configuration: AIChatConfiguration) {
        self.configuration = configuration
    }

    private var hasSubmittableInput: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImageData != nil
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                HStack(spacing: 0) {
                    Text(configuration.aiName)
                        .foregroundStyle(.blue)
                        .underline()
                    Text(configuration.aiDisclaimer)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.top)

                conversationArea

                bottomContent

                inputBarView
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .accessibilityIdentifier("aiChat.root")
        .onAppear {
            refreshConversations()
            checkPendingShare()
            if !ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                focusInput(afterDelay: false)
            }
        }
        .onChange(of: configuration.validateSession()) { _, _ in
            cancelGenerationIfSessionChanged()
        }
        .onChange(of: statusManager.isProcessing) { _, isProcessing in
            if !isProcessing {
                checkPendingShare()
            }
        }
        .onDisappear {
            cancelGenerationIfSessionChanged()
        }
        .sheet(isPresented: $showHistory) {
            historySheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            cameraPicker
        }
        .sheet(isPresented: $isPhotoPickerPresented, onDismiss: { focusInput() }) {
            photoPicker
        }
        .alert(configuration.historyRenameAlertTitle, isPresented: $showRenameAlert) {
            TextField(configuration.historyRenamePlaceholder, text: $renameTitle)
            Button(configuration.cancelButtonTitle, role: .cancel) {
                renameTargetID = nil
            }
            Button(configuration.doneButtonTitle) {
                performRename()
            }
        }
        .confirmationDialog(
            configuration.shareImportReplaceTitle,
            isPresented: Binding(
                get: { shareAwaitingReplacement != nil },
                set: { if !$0 { shareAwaitingReplacement = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(configuration.shareImportReplaceAction) {
                if let share = shareAwaitingReplacement {
                    importShare(share)
                }
            }
            Button(configuration.shareImportLaterAction, role: .cancel) {}
        } message: {
            Text(configuration.shareImportReplaceMessage)
        }
        .alert(
            configuration.shareImportErrorTitle,
            isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { if !$0 { importErrorMessage = nil } }
            )
        ) {
            Button(configuration.shareImportErrorOK, role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "")
        }
        .alert(
            configuration.generationFailedTitle,
            isPresented: Binding(
                get: { persistenceErrorMessage != nil },
                set: { if !$0 { persistenceErrorMessage = nil } }
            )
        ) {
            Button(configuration.okButtonTitle, role: .cancel) {}
        } message: {
            Text(persistenceErrorMessage ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text(activeConversationTitle ?? configuration.newConversationTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Button {
                        refreshConversations()
                        showHistory = true
                    } label: {
                        Image(systemName: "chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(configuration.historyTitle))
                    .accessibilityIdentifier("aiChat.historyButton")
                }

                Text(configuration.headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - History Sheet

    private var historySheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(configuration.historyTitle)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal)
                .padding(.top, 20)

            if conversations.isEmpty {
                ContentUnavailableView(configuration.historyEmptyTitle, systemImage: "clock", description: Text(""))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(conversations) { conversation in
                        Button {
                            loadConversation(id: conversation.id)
                            showHistory = false
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(conversation.title)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer(minLength: 12)

                                Text(conversation.updatedAt, format: .dateTime.month().day().hour().minute())
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                renameTargetID = conversation.id
                                renameTitle = conversation.title
                                showRenameAlert = true
                            } label: {
                                Label(configuration.historyRenameAction, systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                deleteConversation(id: conversation.id)
                            } label: {
                                Label(configuration.deleteButtonTitle, systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteConversation(id: conversation.id)
                            } label: {
                                Label(configuration.deleteButtonTitle, systemImage: "trash")
                            }
                        }
                        .accessibilityIdentifier("aiChat.history.conversation.\(conversation.id.uuidString)")
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Conversation Area

    private var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageRow(
                            message: message,
                            aiName: configuration.aiName,
                            avatarImage: configuration.avatarImage?(),
                            avatarFallbackText: configuration.avatarFallbackText
                        )
                            .id(message.id)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 28)
                .padding(.bottom, 20)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: statusManager.progress) { _, _ in
                syncActiveResponseMessage(persist: false)
            }
            .onChange(of: statusManager.currentStep) { _, _ in
                syncActiveResponseMessage()
                scrollToBottom(proxy)
            }
            .onChange(of: statusManager.errorMessage) { _, _ in
                syncActiveResponseMessage()
                scrollToBottom(proxy)
            }
            .onChange(of: statusManager.completedBookTitle) { _, _ in
                syncActiveResponseMessage()
                scrollToBottom(proxy)
            }
        }
    }

    // MARK: - Bottom Content

    @ViewBuilder
    private var bottomContent: some View {
        if let imageData = selectedImageData {
            ImagePreview(
                imageData: imageData,
                removeAccessibilityLabel: configuration.deleteButtonTitle,
                onRemove: {
                    selectedImageData = nil
                    focusInput()
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        } else if messages.isEmpty {
            SuggestionStrip(suggestions: suggestions) { suggestion in
                inputText = suggestion.subtitle
                focusInput()
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Input Bar

    private var inputBarView: some View {
        InputBar(
            text: $inputText,
            placeholder: configuration.inputPlaceholder,
            isProcessing: statusManager.isProcessing,
            hasSubmittableInput: hasSubmittableInput,
            sendAccessibilityLabel: configuration.sendAccessibilityLabel,
            attachAccessibilityLabel: configuration.attachAccessibilityLabel,
            cameraTitle: configuration.cameraButtonTitle,
            photoLibraryTitle: configuration.photoLibraryButtonTitle,
            onSubmit: submitMessage,
            onAttachCamera: { openAttachmentPicker(source: .camera) },
            onAttachPhotoLibrary: { openAttachmentPicker(source: .photoLibrary) }
        )
    }

    // MARK: - Camera / Photo Picker

    private var cameraPicker: some View {
        CameraCaptureView(isPresented: $isCameraPresented) { data in
            selectedImageData = data
            focusInput()
        }
    }

    private var photoPicker: some View {
        PhotoPickerView(isPresented: $isPhotoPickerPresented) { data in
            selectedImageData = data
            focusInput()
        }
    }

    private enum AttachmentSource {
        case camera
        case photoLibrary
    }

    private func openAttachmentPicker(source: AttachmentSource) {
        isInputFocused = false
        switch source {
        case .camera:
            isCameraPresented = true
        case .photoLibrary:
            isPhotoPickerPresented = true
        }
    }

    // MARK: - Submit Message

    private func submitMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard hasSubmittableInput,
              !statusManager.isProcessing,
              generationTask == nil,
              configuration.validateSession()
        else { return }

        let formImageData: Data? = selectedImageData.flatMap { data in
            guard !data.isEmpty, data.count <= 10_000_000 else { return nil }
            return data
        }

        let previousMessages = messages
        let previousResponseMessageID = activeResponseMessageID
        let previousConversationID = activeConversationID
        let previousConversationTitle = activeConversationTitle

        messages.append(
            ChatMessage.user(
                text: text.isEmpty ? nil : text,
                imageData: formImageData
            )
        )

        let responseID = UUID()
        activeResponseMessageID = responseID
        messages.append(
            ChatMessage.assistant(
                id: responseID,
                title: configuration.processingTitle,
                body: configuration.startingBody,
                progress: 0,
                isProgressing: true,
                isError: false
            )
        )

        statusManager.apply(.starting)

        let shareToConsume = importedShare

        inputText = ""
        selectedImageData = nil
        isInputFocused = false

        generationTask = Task { @MainActor in
            defer {
                generationTask = nil
                checkPendingShare()
            }

            let input = MessageInput(text: text.isEmpty ? nil : text, imageData: formImageData)

            do {
                let titleSeed = text.isEmpty ? nil : text
                let title = makeConversationTitle(from: titleSeed)
                let conversationID = activeConversationID ?? UUID()
                activeConversationID = conversationID
                activeConversationTitle = title

                let detail = ConversationDetail(
                    id: conversationID,
                    title: title,
                    messages: messages
                )

                do {
                    try configuration.saveConversation(detail)
                    if let share = shareToConsume {
                        try configuration.resolveShare(share)
                        importedShare = nil
                    }
                } catch {
                    messages = previousMessages
                    activeResponseMessageID = previousResponseMessageID
                    activeConversationID = previousConversationID
                    activeConversationTitle = previousConversationTitle
                    presentPersistenceError()
                    return
                }

                try await configuration.submitMessage(input) { [weak statusManager] update in
                    Task { @MainActor in
                        statusManager?.apply(update)
                    }
                }

                guard !Task.isCancelled, configuration.validateSession() else { return }
                syncActiveResponseMessage()
                refreshConversations()
                focusInput()
            } catch is CancellationError {
                statusManager.reset()
            } catch {
                syncActiveResponseMessage()
                refreshConversations()
            }
        }
    }

    private func cancelGenerationIfSessionChanged() {
        guard generationTask != nil, !configuration.validateSession() else { return }
        generationTask?.cancel()
    }

    // MARK: - Share Handling

    private func checkPendingShare() {
        guard !statusManager.isProcessing,
              generationTask == nil,
              shareAwaitingReplacement == nil,
              let share = configuration.pendingShare()
        else { return }

        guard importedShare?.id != share.id else { return }

        if hasSubmittableInput {
            shareAwaitingReplacement = share
        } else {
            importShare(share)
        }
    }

    private func importShare(_ share: IncomingShare) {
        guard !statusManager.isProcessing,
              generationTask == nil,
              importedShare?.id != share.id
        else { return }

        do {
            let imageData = try configuration.shareImageData(share)
            if let imageData {
                guard imageData.count <= 10_000_000 else {
                    throw NSError(domain: "AIChatUI", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: configuration.shareImportErrorMessage
                    ])
                }
            }

            startNewConversation()
            inputText = share.text ?? ""
            selectedImageData = imageData
            importedShare = share
            shareAwaitingReplacement = nil
            focusInput(afterDelay: false)
        } catch {
            importErrorMessage = configuration.shareImportErrorMessage
        }
    }

    // MARK: - Active Response Sync

    private func syncActiveResponseMessage(persist: Bool = true) {
        guard let activeResponseMessageID,
              let index = messages.firstIndex(where: { $0.id == activeResponseMessageID }) else {
            return
        }

        let previousMessage = messages[index]

        if let errorMessage = statusManager.errorMessage, !errorMessage.isEmpty {
            messages[index].title = configuration.errorTitle
            messages[index].body = errorMessage
            messages[index].progress = statusManager.progress
            messages[index].isProgressing = false
            messages[index].isError = true
        } else if let completedTitle = statusManager.completedBookTitle {
            messages[index].title = configuration.completedTitle
            messages[index].body = String(format: configuration.completedBodyFormat, completedTitle)
            messages[index].progress = 1
            messages[index].isProgressing = false
            messages[index].isError = false
        } else if statusManager.isProcessing {
            messages[index].title = configuration.processingTitle
            messages[index].body = statusManager.currentStep.isEmpty
                ? configuration.startingBody
                : statusManager.currentStep
            messages[index].progress = statusManager.progress
            messages[index].isProgressing = true
            messages[index].isError = false
        } else {
            messages[index].title = configuration.completedTitle
            messages[index].body = statusManager.currentStep.isEmpty
                ? configuration.completedTitle
                : statusManager.currentStep
            messages[index].progress = 0
            messages[index].isProgressing = false
            messages[index].isError = false
        }

        let isStillProgressing = messages[index].isProgressing

        if persist || !isStillProgressing {
            do {
                try persistActiveConversation()
            } catch {
                messages[index] = previousMessage
                presentPersistenceError()
                return
            }
        }

        if !isStillProgressing {
            self.activeResponseMessageID = nil
        }
    }

    private func persistActiveConversation() throws {
        guard let conversationID = activeConversationID else { return }
        let title = activeConversationTitle
            ?? configuration.newConversationTitle
        let detail = ConversationDetail(
            id: conversationID,
            title: title,
            messages: messages
        )
        try configuration.saveConversation(detail)
    }

    private func presentPersistenceError() {
        persistenceErrorMessage = configuration.unknownErrorMessage
    }

    // MARK: - Conversation Management

    private func refreshConversations() {
        conversations = configuration.loadConversations()
    }

    private func loadConversation(id: UUID) {
        guard let detail = configuration.loadConversationDetail(id) else { return }
        activeConversationID = detail.id
        activeConversationTitle = detail.title
        messages = detail.messages
        activeResponseMessageID = nil
        selectedImageData = nil
        importedShare = nil
        statusManager.reset()
        focusInput()
    }

    private func startNewConversation() {
        activeConversationID = nil
        activeConversationTitle = nil
        messages = []
        activeResponseMessageID = nil
        selectedImageData = nil
        inputText = ""
        importedShare = nil
        statusManager.reset()
        focusInput()
    }

    private func performRename() {
        guard let id = renameTargetID else { return }
        let title = renameTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            try configuration.renameConversation(id, title)
            renameTargetID = nil
            refreshConversations()
            if activeConversationID == id {
                activeConversationTitle = title
            }
        } catch {
            presentPersistenceError()
        }
    }

    private func deleteConversation(id: UUID) {
        do {
            try configuration.deleteConversation(id)
            if activeConversationID == id {
                startNewConversation()
            }
            refreshConversations()
        } catch {
            presentPersistenceError()
        }
    }

    private func makeConversationTitle(from seed: String?) -> String {
        let title = seed?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if title.isEmpty {
            return configuration.imageOnlyConversationTitle
        }
        return String(title.prefix(24))
    }

    // MARK: - Helpers

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                if let lastID = messages.last?.id {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }

    private func focusInput(afterDelay: Bool = true) {
        Task { @MainActor in
            if afterDelay {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            isInputFocused = true
        }
    }
}

// MARK: - Preview

#Preview {
    AIChatView(configuration: AIChatConfiguration())
}

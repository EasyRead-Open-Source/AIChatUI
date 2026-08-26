//
//  AIChatView.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import MarkdownView
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(macOS) || os(visionOS)
import PhotosUI
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// A full-screen AI conversation surface with parent-owned conversation state.
///
/// Hosts that enable speech input must provide `NSMicrophoneUsageDescription` and
/// `NSSpeechRecognitionUsageDescription`. iOS hosts must also provide
/// `NSCameraUsageDescription` when camera capture is available.
@MainActor
public struct AIChatView: View {
    public typealias SendHandler = @MainActor (
        _ input: AIChatInput,
        _ onUpdate: @escaping @MainActor (AIChatResponse) -> Void
    ) async throws -> Void

    @Binding private var conversation: AIConversation

    private let roles: [AIChatRole]
    private let title: String
    private let placeholder: String
    private let onSend: SendHandler
    private let onShowConversations: (() -> Void)?
    private let onDismiss: (() -> Void)?
    private let onMicrophoneTap: (() -> Void)?

    @State private var draft = ""
    @State private var attachments: [AIChatInput.Attachment] = []
#if os(iOS) || os(macOS) || os(visionOS)
    @State private var selectedMediaItems: [PhotosPickerItem] = []
#endif
    @State private var speechInput = SpeechInputController()
    @State private var speechInputPrefix = ""
#if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var isCameraPresented = false
#endif
    @State private var isSending = false
    @State private var sendTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool

    private static let bottomAnchor = "ai-chat-bottom-anchor"

    /// Creates a chat supporting either one or many AI roles.
    /// Call `onUpdate` repeatedly with the same response ID to replace it in place.
    public init(
        conversation: Binding<AIConversation>,
        roles: [AIChatRole],
        title: String? = nil,
        placeholder: String? = nil,
        onShowConversations: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        onMicrophoneTap: (() -> Void)? = nil,
        onSend: @escaping SendHandler
    ) {
        _conversation = conversation
        self.roles = roles
        self.title = title ?? String(localized: "Conversation", bundle: .module)
        self.placeholder = placeholder ?? String(localized: "Type a message...", bundle: .module)
        self.onShowConversations = onShowConversations
        self.onDismiss = onDismiss
        self.onMicrophoneTap = onMicrophoneTap
        self.onSend = onSend
    }

    /// Convenience initializer for a single-role, single-response conversation.
    public init(
        conversation: Binding<AIConversation>,
        role: AIChatRole,
        title: String? = nil,
        placeholder: String? = nil,
        onShowConversations: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        onMicrophoneTap: (() -> Void)? = nil,
        onSend: @escaping @MainActor (AIChatInput) async throws -> AIChatResponse
    ) {
        self.init(
            conversation: conversation,
            roles: [role],
            title: title,
            placeholder: placeholder,
            onShowConversations: onShowConversations,
            onDismiss: onDismiss,
            onMicrophoneTap: onMicrophoneTap
        ) { input, update in
            update(try await onSend(input))
        }
    }

    public var body: some View {
        NavigationStack {
            conversationView
                .navigationTitle(conversation.title ?? title)
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        }
        
        .alert(String(localized: "Send Failed", bundle: .module), isPresented: errorPresented) {
            Button(String(localized: "OK", bundle: .module), role: .cancel) {}
        } message: {
            Text(errorMessage ?? String(localized: "Unknown error", bundle: .module))
        }
#if os(iOS) && !targetEnvironment(macCatalyst)
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraInputView { imageData in
                if let imageData {
                    attachments.append(
                        AIChatInput.Attachment(
                            kind: .image,
                            data: imageData,
                            fileName: "camera-\(UUID().uuidString).jpg",
                            mimeType: "image/jpeg"
                        )
                    )
                }
                isCameraPresented = false
            }
            .ignoresSafeArea()
        }
#endif
        .onDisappear {
            sendTask?.cancel()
            speechInput.cancel()
        }
        .accessibilityIdentifier("aiChat.root")
    }

    private var headerControlRow: some View {
        HStack {
            if let onShowConversations {
                HeaderButton(systemName: "sidebar.left", action: onShowConversations)
                    .accessibilityLabel(String(localized: "Show conversations", bundle: .module))
            } else {
                Color.clear.frame(width: 52, height: 52)
            }

            Spacer()

            if let onDismiss {
                HeaderButton(systemName: "chevron.down", action: onDismiss)
                    .accessibilityLabel(String(localized: "Close", bundle: .module))
            } else {
                Color.clear.frame(width: 52, height: 52)
            }
        }
    }

    @ViewBuilder
    private var conversationView: some View {
#if os(iOS) || os(macOS)
        conversationScrollView
            .scrollDismissesKeyboard(.interactively)
#else
        conversationScrollView
#endif
    }

    private var conversationScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AIChatLayout.messageSpacing) {
                    ForEach(conversation.messages) { message in
                        MessageRow(message: message).id(message.id)
                    }

                    Color.clear.frame(height: 1).id(Self.bottomAnchor)
                }
                .frame(maxWidth: AIChatLayout.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AIChatLayout.contentHorizontalPadding)
                .padding(.vertical, AIChatLayout.contentVerticalPadding)
            }
            .onAppear { scrollToBottom(using: proxy, animated: false) }
            // `updatedAt` also changes when streaming replaces an existing response.
            .onChange(of: conversation.updatedAt) { _, _ in
                scrollToBottom(using: proxy)
            }
        }
    }

    private var composer: some View {
        composerWithMediaImport
            .onChange(of: speechInput.transcript) { _, transcript in
                draft = joinedSpeechText(prefix: speechInputPrefix, transcript: transcript)
            }
            .onChange(of: speechInput.errorMessage) { _, message in
                if let message {
                    errorMessage = message
                }
            }
    }

    @ViewBuilder
    private var composerWithMediaImport: some View {
#if os(iOS) || os(macOS) || os(visionOS)
        composerLayout
            .onChange(of: selectedMediaItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await importAttachments(from: items) }
            }
#else
        composerLayout
#endif
    }

    private var composerLayout: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.primary.opacity(0.08))

            composerSurface
                .frame(maxWidth: AIChatLayout.composerMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AIChatLayout.composerOuterHorizontalPadding)
                .padding(.vertical, AIChatLayout.composerOuterVerticalPadding)
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var composerSurface: some View {
#if os(visionOS)
        materialComposerSurface
#else
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            composerContent
                .glassEffect(
                    .regular.interactive(),
                    in: .rect(cornerRadius: AIChatLayout.composerCornerRadius)
                )
        } else {
            materialComposerSurface
        }
#endif
    }

    private var materialComposerSurface: some View {
        composerContent
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: AIChatLayout.composerCornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AIChatLayout.composerCornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            }
    }

    private var composerContent: some View {
        VStack(alignment: .leading, spacing: AIChatLayout.composerVerticalSpacing) {
            if !attachments.isEmpty {
                AttachmentDraftStrip(attachments: $attachments)
            }

            HStack(spacing: AIChatLayout.composerControlSpacing) {
//#if os(iOS) || os(macOS) || os(visionOS)
//                Button {} label: {
//                    Image(systemName: speechInput.isRecording ? "waveform" : "mic")
//                        .font(.system(size: AIChatLayout.microphoneIconSize, weight: .medium))
//                        .foregroundStyle(speechInput.isRecording ? Color.accentColor : Color.primary)
//                        .frame(
//                            width: AIChatLayout.accessoryControlSize,
//                            height: AIChatLayout.composerControlHeight
//                        )
//                }
//                .buttonStyle(.plain)
//                .onLongPressGesture(
//                    minimumDuration: 0.25,
//                    maximumDistance: 50,
//                    pressing: { isPressing in
//                        if !isPressing {
//                            endSpeechInput()
//                        }
//                    },
//                    perform: startSpeechInput
//                )
//                .accessibilityLabel(String(localized: "Hold to speak", bundle: .module))
//                .accessibilityHint(String(localized: "Hold to speak, release to stop", bundle: .module))
//#endif

                TextField(placeholder, text: $draft, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...AIChatLayout.maximumInputLines)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit(submit)

                attachmentMenu

                Button(action: submit) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: AIChatLayout.sendIconSize, weight: .bold))
                        .foregroundStyle(.background)
                        .frame(width: AIChatLayout.sendButtonSize, height: AIChatLayout.sendButtonSize)
                        .background(sendButtonColor, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit || isSending)
                .accessibilityLabel(String(localized: "Send", bundle: .module))
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, AIChatLayout.composerInnerHorizontalPadding)
        .padding(.vertical, AIChatLayout.composerInnerVerticalPadding)
    }

    @ViewBuilder
    private var attachmentMenu: some View {
#if os(iOS) || os(macOS) || os(visionOS)
        Menu {
#if os(iOS) && !targetEnvironment(macCatalyst)
                    Button {
                        isInputFocused = false
                        isCameraPresented = true
                    } label: {
                        Label(String(localized: "Camera", bundle: .module), systemImage: "camera")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
#endif

                    PhotosPicker(
                        selection: $selectedMediaItems,
                        maxSelectionCount: 8,
                        matching: .any(of: [.images, .videos])
                    ) {
                        Label(String(localized: "Photos & Videos", bundle: .module), systemImage: "photo.on.rectangle")
                    }
        } label: {
            Image(systemName: "plus.circle")
                .font(.system(size: AIChatLayout.attachmentIconSize))
                .frame(
                    width: AIChatLayout.accessoryControlSize,
                    height: AIChatLayout.composerControlHeight
                )
        }
        .accessibilityLabel(String(localized: "Add attachment", bundle: .module))
#endif
    }

    private var canSubmit: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    private var sendButtonColor: Color {
        canSubmit && !isSending ? .accentColor : .secondary.opacity(0.35)
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func submit() {
        let trimmedText = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSubmit, !isSending else { return }

        let input = AIChatInput(
            text: trimmedText.isEmpty ? nil : trimmedText,
            attachments: attachments
        )
        conversation.messages.append(.user(input))
        conversation.updatedAt = .now
        draft = ""
        attachments = []
        isSending = true

        sendTask = Task {
            defer {
                isSending = false
                sendTask = nil
            }
            do {
                try await onSend(input) { response in upsert(response) }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startSpeechInput() {
        guard !isSending else { return }
        speechInputPrefix = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        isInputFocused = false
        onMicrophoneTap?()
        Task { await speechInput.begin() }
    }

    private func endSpeechInput() {
        speechInput.end()
    }

    private func joinedSpeechText(prefix: String, transcript: String) -> String {
        guard !prefix.isEmpty else { return transcript }
        guard !transcript.isEmpty else { return prefix }
        return "\(prefix) \(transcript)"
    }

    private func upsert(_ response: AIChatResponse) {
        if let conversationTitle = response.conversationTitle {
            conversation.title = conversationTitle
        }

        if let index = conversation.messages.firstIndex(where: { $0.id == response.id }) {
            conversation.messages[index] = .assistant(response)
        } else {
            conversation.messages.append(.assistant(response))
        }
        conversation.updatedAt = .now
    }

#if os(iOS) || os(macOS) || os(visionOS)
    private func importAttachments(from items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let type = item.supportedContentTypes.first ?? .data
            let kind: AIChatInput.Attachment.Kind = type.conforms(to: .movie) ? .video : .image
            let fileExtension = type.preferredFilenameExtension ?? (kind == .video ? "mov" : "jpg")
            attachments.append(
                AIChatInput.Attachment(
                    kind: kind,
                    data: data,
                    fileName: "attachment-\(UUID().uuidString).\(fileExtension)",
                    mimeType: type.preferredMIMEType
                )
            )
        }
        selectedMediaItems = []
    }
#endif

    private func scrollToBottom(using proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.22)) {
                proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
        }
    }
}

#if os(iOS) && !targetEnvironment(macCatalyst)
@MainActor
private struct CameraInputView: UIViewControllerRepresentable {
    let onComplete: (Data?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onComplete: (Data?) -> Void

        init(onComplete: @escaping (Data?) -> Void) {
            self.onComplete = onComplete
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onComplete(nil)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            onComplete(image?.jpegData(compressionQuality: 0.9))
        }
    }
}
#endif

private struct HeaderButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
#if os(visionOS)
        materialButton
#else
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            button
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            materialButton
        }
#endif
    }

    private var materialButton: some View {
        button
            .background(.ultraThinMaterial, in: Circle())
            .overlay { Circle().stroke(Color.primary.opacity(0.08)) }
    }

    private var button: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
    }
}

private struct MessageRow: View {
    let message: AIConversation.Message

    var body: some View {
        switch message {
        case .user(let input): UserMessageRow(input: input)
        case .assistant(let response): AssistantMessageRow(response: response)
        }
    }
}

private struct UserMessageRow: View {
    let input: AIChatInput

    var body: some View {
        HStack(alignment: .bottom, spacing: 44) {
            Spacer(minLength: AIChatLayout.messageOppositeInset)
            VStack(alignment: .trailing, spacing: 8) {
                if !input.attachments.isEmpty {
                    AttachmentGrid(attachments: input.attachments)
                }
                if let text = input.text, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .chatTextSelection()
                        .padding(.horizontal, AIChatLayout.bubbleHorizontalPadding)
                        .padding(.vertical, AIChatLayout.bubbleVerticalPadding)
                        .background(
                            Color.secondary.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: AIChatLayout.bubbleCornerRadius)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct AssistantMessageRow: View {
    let response: AIChatResponse

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            RoleAvatar(role: response.role)
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(response.role.name).font(.caption.weight(.semibold))
                    if let subtitle = response.role.subtitle {
                        Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Group {
                    switch response.content {
                    case .markdown(let markdown):
                        MarkdownText(markdown).chatTextSelection()
                    case .view(let view):
                        view
                    }
                }
                .font(.body)
                .padding(.horizontal, AIChatLayout.bubbleHorizontalPadding)
                .padding(.vertical, AIChatLayout.bubbleVerticalPadding)
                .background(
                    Color.secondary.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: AIChatLayout.bubbleCornerRadius)
                )
            }
            Spacer(minLength: AIChatLayout.messageOppositeInset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RoleAvatar: View {
    let role: AIChatRole

    var body: some View {
        Group {
#if canImport(UIKit)
            if let data = role.avatarImageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let url = role.avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: { fallback }
            } else {
                fallback
            }
#elseif canImport(AppKit)
            if let data = role.avatarImageData, let image = NSImage(data: data) {
                Image(nsImage: image).resizable().scaledToFill()
            } else if let url = role.avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: { fallback }
            } else {
                fallback
            }
#else
            fallback
#endif
        }
        .frame(width: AIChatLayout.avatarSize, height: AIChatLayout.avatarSize)
        .clipShape(Circle())
        .overlay { Circle().stroke(Color.primary.opacity(0.12)) }
        .accessibilityLabel(role.name)
    }

    private var fallback: some View {
        Text(String(role.name.prefix(1)).uppercased())
            .font(.caption.weight(.bold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.secondary.opacity(0.16))
    }
}

private struct AttachmentGrid: View {
    let attachments: [AIChatInput.Attachment]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: AIChatLayout.attachmentWidth), spacing: 8)],
            spacing: 8
        ) {
            ForEach(attachments) { AttachmentPreview(attachment: $0) }
        }
        .frame(maxWidth: AIChatLayout.attachmentGridMaxWidth)
    }
}

private struct AttachmentDraftStrip: View {
    @Binding var attachments: [AIChatInput.Attachment]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachments) { attachment in
                    AttachmentPreview(attachment: attachment)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                attachments.removeAll { $0.id == attachment.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(
                                        Color.primary,
                                        Color.secondary.opacity(0.65)
                                    )
                            }
                            .buttonStyle(.plain)
                            .offset(x: 5, y: -5)
                            .accessibilityLabel(String(localized: "Remove attachment", bundle: .module))
                        }
                }
            }
            .padding(.top, 5)
        }
    }
}

private struct AttachmentPreview: View {
    let attachment: AIChatInput.Attachment

    var body: some View {
        ZStack {
#if canImport(UIKit)
            if attachment.kind == .image, let image = UIImage(data: attachment.data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                mediaPlaceholder
            }
#elseif canImport(AppKit)
            if attachment.kind == .image, let image = NSImage(data: attachment.data) {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                mediaPlaceholder
            }
#else
            mediaPlaceholder
#endif
        }
        .frame(width: AIChatLayout.attachmentWidth, height: AIChatLayout.attachmentHeight)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.primary.opacity(0.12))
        }
    }

    private var mediaPlaceholder: some View {
        VStack(spacing: 6) {
            Image(systemName: attachment.kind == .video ? "play.circle.fill" : "doc.fill")
                .font(.title2)
            Text(attachment.fileName).font(.caption2).lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.1))
    }
}

private enum AIChatLayout {
#if os(macOS)
    static let titleFont: Font = .subheadline
    static let headerHorizontalPadding: CGFloat = 12
    static let headerVerticalPadding: CGFloat = 7
    static let contentMaxWidth: CGFloat = 760
    static let contentHorizontalPadding: CGFloat = 14
    static let contentVerticalPadding: CGFloat = 16
    static let messageSpacing: CGFloat = 14
    static let composerMaxWidth: CGFloat = 760
    static let composerOuterHorizontalPadding: CGFloat = 12
    static let composerOuterVerticalPadding: CGFloat = 9
    static let composerInnerHorizontalPadding: CGFloat = 12
    static let composerInnerVerticalPadding: CGFloat = 8
    static let composerVerticalSpacing: CGFloat = 7
    static let composerControlSpacing: CGFloat = 8
    static let composerControlHeight: CGFloat = 28
    static let composerCornerRadius: CGFloat = 18
    static let accessoryControlSize: CGFloat = 26
    static let microphoneIconSize: CGFloat = 17
    static let attachmentIconSize: CGFloat = 20
    static let sendButtonSize: CGFloat = 26
    static let sendIconSize: CGFloat = 12
    static let maximumInputLines = 4
    static let avatarSize: CGFloat = 30
    static let messageOppositeInset: CGFloat = 36
    static let bubbleHorizontalPadding: CGFloat = 12
    static let bubbleVerticalPadding: CGFloat = 8
    static let bubbleCornerRadius: CGFloat = 14
    static let attachmentWidth: CGFloat = 96
    static let attachmentHeight: CGFloat = 76
    static let attachmentGridMaxWidth: CGFloat = 250
#elseif os(tvOS)
    static let titleFont: Font = .title3
    static let headerHorizontalPadding: CGFloat = 36
    static let headerVerticalPadding: CGFloat = 18
    static let contentMaxWidth: CGFloat = 1_000
    static let contentHorizontalPadding: CGFloat = 48
    static let contentVerticalPadding: CGFloat = 36
    static let messageSpacing: CGFloat = 28
    static let composerMaxWidth: CGFloat = 1_000
    static let composerOuterHorizontalPadding: CGFloat = 48
    static let composerOuterVerticalPadding: CGFloat = 24
    static let composerInnerHorizontalPadding: CGFloat = 24
    static let composerInnerVerticalPadding: CGFloat = 18
    static let composerVerticalSpacing: CGFloat = 14
    static let composerControlSpacing: CGFloat = 18
    static let composerControlHeight: CGFloat = 52
    static let composerCornerRadius: CGFloat = 30
    static let accessoryControlSize: CGFloat = 48
    static let microphoneIconSize: CGFloat = 24
    static let attachmentIconSize: CGFloat = 30
    static let sendButtonSize: CGFloat = 52
    static let sendIconSize: CGFloat = 22
    static let maximumInputLines = 3
    static let avatarSize: CGFloat = 48
    static let messageOppositeInset: CGFloat = 80
    static let bubbleHorizontalPadding: CGFloat = 22
    static let bubbleVerticalPadding: CGFloat = 16
    static let bubbleCornerRadius: CGFloat = 22
    static let attachmentWidth: CGFloat = 160
    static let attachmentHeight: CGFloat = 120
    static let attachmentGridMaxWidth: CGFloat = 520
#elseif os(watchOS)
    static let titleFont: Font = .headline
    static let headerHorizontalPadding: CGFloat = 4
    static let headerVerticalPadding: CGFloat = 4
    static let contentMaxWidth: CGFloat = .infinity
    static let contentHorizontalPadding: CGFloat = 4
    static let contentVerticalPadding: CGFloat = 8
    static let messageSpacing: CGFloat = 10
    static let composerMaxWidth: CGFloat = .infinity
    static let composerOuterHorizontalPadding: CGFloat = 3
    static let composerOuterVerticalPadding: CGFloat = 4
    static let composerInnerHorizontalPadding: CGFloat = 7
    static let composerInnerVerticalPadding: CGFloat = 6
    static let composerVerticalSpacing: CGFloat = 5
    static let composerControlSpacing: CGFloat = 5
    static let composerControlHeight: CGFloat = 30
    static let composerCornerRadius: CGFloat = 16
    static let accessoryControlSize: CGFloat = 28
    static let microphoneIconSize: CGFloat = 16
    static let attachmentIconSize: CGFloat = 18
    static let sendButtonSize: CGFloat = 28
    static let sendIconSize: CGFloat = 12
    static let maximumInputLines = 2
    static let avatarSize: CGFloat = 24
    static let messageOppositeInset: CGFloat = 4
    static let bubbleHorizontalPadding: CGFloat = 8
    static let bubbleVerticalPadding: CGFloat = 6
    static let bubbleCornerRadius: CGFloat = 12
    static let attachmentWidth: CGFloat = 72
    static let attachmentHeight: CGFloat = 58
    static let attachmentGridMaxWidth: CGFloat = 150
#elseif os(visionOS)
    static let titleFont: Font = .headline
    static let headerHorizontalPadding: CGFloat = 20
    static let headerVerticalPadding: CGFloat = 14
    static let contentMaxWidth: CGFloat = 720
    static let contentHorizontalPadding: CGFloat = 24
    static let contentVerticalPadding: CGFloat = 28
    static let messageSpacing: CGFloat = 22
    static let composerMaxWidth: CGFloat = 720
    static let composerOuterHorizontalPadding: CGFloat = 24
    static let composerOuterVerticalPadding: CGFloat = 18
    static let composerInnerHorizontalPadding: CGFloat = 18
    static let composerInnerVerticalPadding: CGFloat = 14
    static let composerVerticalSpacing: CGFloat = 10
    static let composerControlSpacing: CGFloat = 12
    static let composerControlHeight: CGFloat = 40
    static let composerCornerRadius: CGFloat = 24
    static let accessoryControlSize: CGFloat = 36
    static let microphoneIconSize: CGFloat = 21
    static let attachmentIconSize: CGFloat = 25
    static let sendButtonSize: CGFloat = 38
    static let sendIconSize: CGFloat = 17
    static let maximumInputLines = 5
    static let avatarSize: CGFloat = 38
    static let messageOppositeInset: CGFloat = 48
    static let bubbleHorizontalPadding: CGFloat = 16
    static let bubbleVerticalPadding: CGFloat = 12
    static let bubbleCornerRadius: CGFloat = 18
    static let attachmentWidth: CGFloat = 120
    static let attachmentHeight: CGFloat = 96
    static let attachmentGridMaxWidth: CGFloat = 320
#else
    static let titleFont: Font = .headline
    static let headerHorizontalPadding: CGFloat = 12
    static let headerVerticalPadding: CGFloat = 10
    static let contentMaxWidth: CGFloat = .infinity
    static let contentHorizontalPadding: CGFloat = 16
    static let contentVerticalPadding: CGFloat = 24
    static let messageSpacing: CGFloat = 20
    static let composerMaxWidth: CGFloat = .infinity
    static let composerOuterHorizontalPadding: CGFloat = 20
    static let composerOuterVerticalPadding: CGFloat = 20
    static let composerInnerHorizontalPadding: CGFloat = 18
    static let composerInnerVerticalPadding: CGFloat = 13
    static let composerVerticalSpacing: CGFloat = 10
    static let composerControlSpacing: CGFloat = 12
    static let composerControlHeight: CGFloat = 34
    static let composerCornerRadius: CGFloat = 28
    static let accessoryControlSize: CGFloat = 30
    static let microphoneIconSize: CGFloat = 22
    static let attachmentIconSize: CGFloat = 26
    static let sendButtonSize: CGFloat = 32
    static let sendIconSize: CGFloat = 16
    static let maximumInputLines = 5
    static let avatarSize: CGFloat = 36
    static let messageOppositeInset: CGFloat = 44
    static let bubbleHorizontalPadding: CGFloat = 15
    static let bubbleVerticalPadding: CGFloat = 11
    static let bubbleCornerRadius: CGFloat = 18
    static let attachmentWidth: CGFloat = 112
    static let attachmentHeight: CGFloat = 92
    static let attachmentGridMaxWidth: CGFloat = 280
#endif
}

private extension View {
    @ViewBuilder
    func chatTextSelection() -> some View {
#if os(iOS) || os(macOS) || os(visionOS)
        textSelection(.enabled)
#else
        self
#endif
    }
}

import SwiftUI

#if os(iOS)
import PhotosUI
#endif

/// Keeps the input capsule and send button in the same glass container.
struct ChatComposerGlassContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
#if os(visionOS)
        content
#else
        if #available(iOS 26, macOS 26, tvOS 26, watchOS 26, *) {
            GlassEffectContainer(spacing: 10) { content }
        } else {
            content
        }
#endif
    }
}

struct ChatComposerCapsule<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content.modifier(ChatComposerCapsuleStyle())
    }
}

/// Apply after the matched transition source so the glass participates in the morph.
private struct ChatComposerCapsuleStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
#if os(visionOS)
        materialSurface(content)
#else
        if #available(iOS 26, macOS 26, tvOS 26, watchOS 26, *) {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            materialSurface(content)
        }
#endif
    }

    private func materialSurface(_ content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().stroke(Color.primary.opacity(0.12)) }
    }
}

struct ChatSendButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        styledButton
            .disabled(!isEnabled)
            .accessibilityLabel(String(localized: "Send", bundle: .module))
            .accessibilityIdentifier("aiChat.send")
    }

    @ViewBuilder
    private var styledButton: some View {
#if os(visionOS)
        fallbackButton
#else
        if #available(iOS 26, macOS 26, tvOS 26, watchOS 26, *) {
            button
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
        } else {
            fallbackButton
        }
#endif
    }

    private var fallbackButton: some View {
        button
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
    }

    private var button: some View {
        Button(action: action) {
            Image(systemName: "paperplane")
                .font(.system(size: AIChatLayout.sendIconSize, weight: .medium))
                .frame(width: 20, height: 30)
        }
    }
}

struct ChatAttachmentButtonLabel: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: AIChatLayout.microphoneIconSize, weight: .medium))
            .frame(
                width: AIChatLayout.accessoryControlSize,
                height: AIChatLayout.composerControlHeight
            )
    }
}

private struct ChatPhotoPickerButtonStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, tvOS 26, watchOS 26, *) {
#if os(visionOS)
            content.buttonStyle(.bordered)
#else
            content.buttonStyle(.glass)
#endif
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

#if os(iOS)
/// The capsule itself is the zoom source, including its clipping and glass surface.
struct CompactChatImagePicker<Content: View>: View {
    @Binding var isPresented: Bool
    var onSelection: ([PhotosPickerItem]) -> Void
    var onCamera: (() -> Void)?
    @ViewBuilder var content: Content

    @State private var selection: PhotosPickerItem?
    @State private var expandedSelection: [PhotosPickerItem] = []
    @State private var isExpanded = false
    @State private var suppressZoom = false
    @State private var isCameraRequested = false
    @State private var capsuleWidth: CGFloat = 320
    @Namespace private var namespace

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .clipShape(Capsule())
            .matchedTransitionSource(id: "composer", in: namespace)
            .modifier(ChatComposerCapsuleStyle())
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { capsuleWidth = $0 }
            .popover(isPresented: $isPresented) {
                CompactChatPhotoLibrary(selection: $selection)
                    .frame(width: max(1, capsuleWidth), height: 250)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            expandedSelection = []
                            isExpanded = true
                            // Preserve CPPicker's initial zoom, then avoid a second
                            // zoom as the full library and popover close together.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                guard isExpanded else { return }
                                suppressZoom = true
                            }
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .frame(width: 24, height: 34)
                        }
                        .modifier(ChatPhotoPickerButtonStyle())
                        .buttonBorderShape(.circle)
                        .accessibilityLabel(String(localized: "Expand photo picker", bundle: .module))
                        .accessibilityIdentifier("aiChat.expandPhotoPicker")
                        .padding(10)
                    }
                    .overlay(alignment: .topLeading) {
                        if let onCamera {
                            Button {
                                isCameraRequested = true
                                isPresented = false
                            } label: {
                                Image(systemName: "camera").frame(width: 24, height: 34)
                            }
                            .modifier(ChatPhotoPickerButtonStyle())
                            .buttonBorderShape(.circle)
                            .accessibilityLabel(String(localized: "Camera", bundle: .module))
                            .padding(10)
                            .onDisappear {
                                if isCameraRequested {
                                    isCameraRequested = false
                                    onCamera()
                                }
                            }
                        }
                    }
                    .presentationCompactAdaptation(.popover)
                    // Keep the system popover background: it supplies native Liquid Glass.
                    .matchedTransitionSource(id: "compactPicker", in: namespace)
                    .modifier(ChatPhotoPickerZoomTransition(
                        sourceID: "composer",
                        namespace: namespace,
                        isSuppressed: suppressZoom
                    ))
                    .fullScreenCover(isPresented: $isExpanded, onDismiss: {
                        isPresented = false
                    }) {
                        ExpandedChatPhotoLibrary(selection: $expandedSelection) {
                            isExpanded = false
                        } onAdd: {
                            onSelection(expandedSelection)
                            expandedSelection = []
                            isExpanded = false
                        }
                        .modifier(ChatPhotoPickerZoomTransition(
                            sourceID: "compactPicker",
                            namespace: namespace,
                            isSuppressed: suppressZoom
                        ))
                        .interactiveDismissDisabled()
                    }
                    .onDisappear {
                        selection = nil
                        if !isExpanded { suppressZoom = false }
                    }
            }
            .onChange(of: isPresented) { _, presented in
                if presented { suppressZoom = false }
            }
            .onChange(of: selection) { _, item in
                guard let item else { return }
                onSelection([item])
                selection = nil
                isPresented = false
            }
    }
}

/// Type erasure keeps the picker alive when CPPicker switches its transition off.
/// Older systems retain the native zoom without requiring the iOS 27 API.
private struct ChatPhotoPickerZoomTransition: ViewModifier {
    let sourceID: String
    let namespace: Namespace.ID
    let isSuppressed: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 27, *) {
            content.navigationTransition(
                isSuppressed
                    ? AnyNavigationTransition(.automatic)
                    : AnyNavigationTransition(.zoom(sourceID: sourceID, in: namespace))
            )
        } else {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        }
    }
}

private struct CompactChatPhotoLibrary: View {
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        if #available(iOS 27, *) {
            picker.photosPickerMetadataOptions([.removeLocation])
        } else {
            picker
        }
    }

    private var picker: some View {
        PhotosPicker("", selection: $selection, matching: .any(of: [.images, .videos]))
            .photosPickerStyle(.inline)
            .photosPickerDisabledCapabilities(.collectionNavigation)
            .photosPickerAccessoryVisibility(.hidden)
    }
}

private struct ExpandedChatPhotoLibrary: View {
    @Binding var selection: [PhotosPickerItem]
    let onClose: () -> Void
    let onAdd: () -> Void

    var body: some View {
        library
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark").frame(width: 24, height: 34)
                    }
                    .accessibilityLabel(String(localized: "Close", bundle: .module))
                    Spacer()
                    Button(action: onAdd) {
                        Text("Add attachments", bundle: .module)
                    }
                    .disabled(selection.isEmpty)
                    .accessibilityIdentifier("aiChat.addSelectedAttachments")
                }
                .modifier(ChatPhotoPickerButtonStyle())
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
            }
    }

    @ViewBuilder
    private var library: some View {
        if #available(iOS 27, *) {
            picker.photosPickerMetadataOptions([.removeLocation])
        } else {
            picker
        }
    }

    private var picker: some View {
        PhotosPicker(
            "",
            selection: $selection,
            maxSelectionCount: 8,
            matching: .any(of: [.images, .videos])
        )
        .photosPickerStyle(.inline)
        .photosPickerDisabledCapabilities(.selectionActions)
    }
}
#endif

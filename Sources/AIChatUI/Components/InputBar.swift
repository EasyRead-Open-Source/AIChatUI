//
//  InputBar.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI

struct InputBar: View {
    @Binding var text: String
    let placeholder: String
    let isProcessing: Bool
    let hasSubmittableInput: Bool
    let sendAccessibilityLabel: String
    let attachAccessibilityLabel: String
    let cameraTitle: String
    let photoLibraryTitle: String
    let onSubmit: () -> Void
    let onAttachCamera: () -> Void
    let onAttachPhotoLibrary: () -> Void

    @FocusState private var isInputFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text)
                .font(.body)
                .textFieldStyle(.plain)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit(onSubmit)
                .disabled(isProcessing)
                .accessibilityIdentifier("aiChat.input")

            Menu {
                Button {
                    onAttachCamera()
                } label: {
                    Label(cameraTitle, systemImage: "camera")
                }
                .accessibilityIdentifier("aiChat.attach.camera")

                Button {
                    onAttachPhotoLibrary()
                } label: {
                    Label(photoLibraryTitle, systemImage: "photo")
                }
                .accessibilityIdentifier("aiChat.attach.photoLibrary")
            } label: {
                Image(systemName: "paperclip")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            .disabled(isProcessing)
            .accessibilityLabel(Text(attachAccessibilityLabel))
            .accessibilityIdentifier("aiChat.attachButton")

            Button(action: onSubmit) {
                Image(systemName: "paperplane.fill")
                    .imageScale(.medium)
            }
            .disabled(!hasSubmittableInput || isProcessing)
            .accessibilityLabel(Text(sendAccessibilityLabel))
            .accessibilityIdentifier("aiChat.submitButton")
        }
        .padding()
        .applyInputLiquidGlassBackground()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("aiChat.inputBar")
    }
}

private extension View {
    @ViewBuilder
    func applyInputLiquidGlassBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            self
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
                )
        }
    }
}

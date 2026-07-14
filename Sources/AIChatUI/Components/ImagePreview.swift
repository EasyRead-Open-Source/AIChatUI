//
//  ImagePreview.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI

struct ImagePreview: View {
    let imageData: Data
    let removeAccessibilityLabel: String
    let onRemove: () -> Void

    var body: some View {
        HStack {
            ZStack(alignment: .topTrailing) {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .imageScale(.medium)
                }
                .padding(6)
                .accessibilityLabel(Text(removeAccessibilityLabel))
                .accessibilityIdentifier("aiChat.imageRemoveButton")
            }
            .accessibilityIdentifier("aiChat.imagePreview")

            Spacer()
        }
    }
}

//
//  PhotoPickerView.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI
#if canImport(UIKit) && canImport(PhotosUI)
import UIKit
import PhotosUI

/// A photo library picker wrapper that returns image data via a closure.
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onSelect: (Data?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onSelect: onSelect)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding var isPresented: Bool
        let onSelect: (Data?) -> Void

        init(isPresented: Binding<Bool>, onSelect: @escaping (Data?) -> Void) {
            _isPresented = isPresented
            self.onSelect = onSelect
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onSelect(nil)
                isPresented = false
                return
            }

            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                DispatchQueue.main.async {
                    self?.onSelect(data)
                    self?.isPresented = false
                }
            }
        }
    }
}
#else
struct PhotoPickerView: View {
    @Binding var isPresented: Bool
    let onSelect: (Data?) -> Void

    var body: some View {
        EmptyView()
    }
}
#endif

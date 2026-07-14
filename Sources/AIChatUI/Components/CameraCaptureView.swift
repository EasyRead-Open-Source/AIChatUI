//
//  CameraCaptureView.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import SwiftUI
#if canImport(UIKit)
import UIKit

/// A camera capture wrapper that returns image data via a closure.
struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onCapture: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var isPresented: Bool
        let onCapture: (Data?) -> Void

        init(isPresented: Binding<Bool>, onCapture: @escaping (Data?) -> Void) {
            _isPresented = isPresented
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let data: Data?
            if let image = info[.originalImage] as? UIImage {
                data = image.jpegData(compressionQuality: 0.8)
            } else {
                data = nil
            }
            onCapture(data)
            isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
            isPresented = false
        }
    }
}
#else
struct CameraCaptureView: View {
    @Binding var isPresented: Bool
    let onCapture: (Data?) -> Void

    var body: some View {
        EmptyView()
    }
}
#endif

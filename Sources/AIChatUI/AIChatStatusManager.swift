//
//  AIChatStatusManager.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// An internal status manager for the package, replacing the host app's GenerationStatusManager.
/// The view holds an instance of this object to display generation progress.
@MainActor
public final class AIChatStatusManager: ObservableObject {
    @Published public var isProcessing: Bool = false
    @Published public var currentStep: String = ""
    @Published public var progress: Double = 0.0
    @Published public var errorMessage: String?
    @Published public var completedBookTitle: String?

    public init() {}

    public func apply(_ update: GenerationStatusUpdate) {
        isProcessing = update.isProcessing
        currentStep = update.currentStep
        progress = update.progress
        errorMessage = update.errorMessage
        completedBookTitle = update.completedBookTitle
    }

    public func reset() {
        isProcessing = false
        currentStep = ""
        progress = 0
        errorMessage = nil
        completedBookTitle = nil
    }
}

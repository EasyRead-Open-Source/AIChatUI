//
//  GenerationStatusUpdate.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/7/14
//

import Foundation

/// Callback data for status updates during generation.
public struct GenerationStatusUpdate: Sendable {
    public let isProcessing: Bool
    public let currentStep: String
    public let progress: Double
    public let errorMessage: String?
    public let completedBookTitle: String?

    public init(
        isProcessing: Bool,
        currentStep: String,
        progress: Double,
        errorMessage: String? = nil,
        completedBookTitle: String? = nil
    ) {
        self.isProcessing = isProcessing
        self.currentStep = currentStep
        self.progress = progress
        self.errorMessage = errorMessage
        self.completedBookTitle = completedBookTitle
    }

    /// The initial "processing" state.
    public static var starting: GenerationStatusUpdate {
        GenerationStatusUpdate(
            isProcessing: true,
            currentStep: "",
            progress: 0
        )
    }
}

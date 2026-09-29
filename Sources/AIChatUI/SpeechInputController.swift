//
//  SpeechInputController.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/8/26
//

import Foundation
import Observation

#if (os(iOS) || os(macOS) || os(visionOS)) && canImport(AVFoundation) && canImport(Speech)
@preconcurrency import AVFoundation
@preconcurrency import Speech

@MainActor
@Observable
final class SpeechInputController {
    private(set) var transcript = ""
    private(set) var isRecording = false
    private(set) var isProcessing = false
    private(set) var errorMessage: String?

    var isBusy: Bool { isRecording || isProcessing }

    private let audioEngine = AVAudioEngine()
    private let recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var wantsRecording = false
    private var permissionRequestID: UUID?
    private var hasInstalledAudioTap = false
    private var recognitionID: UUID?

    init(locale: Locale = .current) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func begin() async {
        guard !isBusy else { return }

        wantsRecording = true
        let requestID = UUID()
        permissionRequestID = requestID
        isProcessing = true
        transcript = ""
        errorMessage = nil

        do {
            guard await requestPermissions() else {
                throw SpeechInputError.permissionDenied
            }
            guard permissionRequestID == requestID, wantsRecording else { return }
            try startAudioRecognition()
            permissionRequestID = nil
        } catch {
            guard permissionRequestID == requestID else { return }
            permissionRequestID = nil
            errorMessage = error.localizedDescription
            stopAudioRecognition(cancelTask: true)
        }
    }

    func end() {
        wantsRecording = false
        guard isRecording else {
            if permissionRequestID != nil {
                permissionRequestID = nil
                isProcessing = false
            }
            return
        }

        stopAudioInput()
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        isRecording = false
        isProcessing = true
    }

    func cancel() {
        wantsRecording = false
        permissionRequestID = nil
        stopAudioRecognition(cancelTask: true)
    }

    private func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else { return false }

        return await withCheckedContinuation { continuation in
#if os(macOS) || os(visionOS)
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
#else
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
#endif
        }
    }

    private func startAudioRecognition() throws {
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechInputError.recognizerUnavailable
        }

        stopAudioRecognition(cancelTask: true)

#if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
#endif

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        let recognitionID = UUID()
        self.recognitionID = recognitionID

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw SpeechInputError.audioUnavailable
        }

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            request.append(buffer)
        }
        hasInstalledAudioTap = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal == true
            let errorDescription = error?.localizedDescription

            Task { @MainActor [weak self, text, isFinal, errorDescription, recognitionID] in
                guard let self, self.recognitionID == recognitionID else { return }
                if let text {
                    transcript = text
                }
                if let errorDescription {
                    errorMessage = errorDescription
                }
                if isFinal || errorDescription != nil {
                    stopAudioRecognition(cancelTask: false)
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isProcessing = false
        isRecording = true
    }

    private func stopAudioRecognition(cancelTask: Bool) {
        recognitionID = nil
        stopAudioInput()
        recognitionRequest?.endAudio()
        if cancelTask {
            recognitionTask?.cancel()
        }
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        isProcessing = false

#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
    }

    private func stopAudioInput() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInstalledAudioTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledAudioTap = false
        }
    }
}
#else
@MainActor
@Observable
final class SpeechInputController {
    private(set) var transcript = ""
    private(set) var isRecording = false
    private(set) var isProcessing = false
    private(set) var errorMessage: String?

    var isBusy: Bool { isRecording || isProcessing }

    func begin() async {
        errorMessage = String(localized: "Speech recognition is currently unavailable.", bundle: .module)
    }

    func end() {}
    func cancel() {}
}
#endif

private enum SpeechInputError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case audioUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            String(
                localized: "Please allow microphone and speech recognition access in Settings.",
                bundle: .module
            )
        case .recognizerUnavailable:
            String(localized: "Speech recognition is currently unavailable.", bundle: .module)
        case .audioUnavailable:
            String(localized: "Microphone audio is currently unavailable.", bundle: .module)
        }
    }
}

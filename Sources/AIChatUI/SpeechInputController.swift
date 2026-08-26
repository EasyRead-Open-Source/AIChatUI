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
    private(set) var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var wantsRecording = false
    private var hasInstalledAudioTap = false

    init(locale: Locale = .current) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func begin() async {
        guard !isRecording else { return }

        wantsRecording = true
        transcript = ""
        errorMessage = nil

        do {
            guard await requestPermissions() else {
                throw SpeechInputError.permissionDenied
            }
            guard wantsRecording else { return }
            try startAudioRecognition()
        } catch {
            errorMessage = error.localizedDescription
            stopAudioRecognition(cancelTask: true)
        }
    }

    func end() {
        wantsRecording = false
        stopAudioRecognition(cancelTask: false)
    }

    func cancel() {
        wantsRecording = false
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

            Task { @MainActor [weak self, text, isFinal, errorDescription] in
                guard let self else { return }
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
        isRecording = true
    }

    private func stopAudioRecognition(cancelTask: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInstalledAudioTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledAudioTap = false
        }

        recognitionRequest?.endAudio()
        if cancelTask {
            recognitionTask?.cancel()
        } else {
            recognitionTask?.finish()
        }
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
    }
}
#else
@MainActor
@Observable
final class SpeechInputController {
    private(set) var transcript = ""
    private(set) var isRecording = false
    private(set) var errorMessage: String?

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

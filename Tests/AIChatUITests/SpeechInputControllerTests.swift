import Dispatch
import Foundation
import Testing
@testable import AIChatUI

#if (os(iOS) || os(macOS) || os(visionOS)) && canImport(AVFoundation) && canImport(Speech)
@preconcurrency import AVFoundation
@preconcurrency import Speech

struct SpeechInputControllerTests {
    @Test @MainActor
    func recognitionCallbackCanEnterFromABackgroundQueue() async {
        let controller = SpeechInputController()
        let callback = controller.recognitionHandler(for: UUID())

        await onBackgroundQueue {
            #expect(!Thread.isMainThread)
            callback(nil, NSError(domain: "SpeechInputControllerTests", code: 1))
        }

        // A callback from an inactive recognition session must be ignored.
        #expect(controller.transcript.isEmpty)
        #expect(controller.errorMessage == nil)
        #expect(!controller.isBusy)
    }

    @Test
    func audioTapCanEnterFromABackgroundQueue() async {
        let request = SFSpeechAudioBufferRecognitionRequest()
        let callback = SpeechInputController.audioTap(for: request)

        await onBackgroundQueue {
            #expect(!Thread.isMainThread)
            let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16)!
            buffer.frameLength = 16
            buffer.floatChannelData![0].initialize(repeating: 0, count: 16)
            callback(buffer, AVAudioTime(sampleTime: 0, atRate: 44_100))
            request.endAudio()
        }
    }

    private func onBackgroundQueue(_ action: @escaping @Sendable () -> Void) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                action()
                continuation.resume()
            }
        }
    }
}
#endif

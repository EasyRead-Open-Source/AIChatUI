import SwiftUI

/// Frames share the chat surface's coordinates, including its bottom inset.
struct MessageSendFlight: Identifiable {
    static let coordinateSpace = "ai-chat-send-flight"

    let id: UUID
    let sourceText: String
    let text: String
    let source: CGRect
    var destination: CGRect?
}

struct MessageSendFlightView: View {
    let flight: MessageSendFlight
    let onComplete: () -> Void

    @State private var hasDeparted = false

    private var destination: CGRect { flight.destination ?? flight.source }
    private var position: CGPoint {
        let frame = hasDeparted ? destination : flight.source
        return CGPoint(x: frame.minX, y: frame.minY)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: AIChatLayout.bubbleCornerRadius)
                .fill(Color.secondary.opacity(0.18))
                .frame(
                    width: destination.width + 2 * AIChatLayout.bubbleHorizontalPadding,
                    height: destination.height + 2 * AIChatLayout.bubbleVerticalPadding
                )
                .offset(
                    x: -AIChatLayout.bubbleHorizontalPadding,
                    y: -AIChatLayout.bubbleVerticalPadding
                )
                .opacity(hasDeparted ? 1 : 0)

            // Keep both line layouts fixed during the flight. Only translation and
            // opacity animate, so wrapping never jumps or runs layout every frame.
            Text(flight.sourceText)
                .frame(width: flight.source.width, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: flight.source.height, alignment: .bottom)
                .clipped()
                .opacity(hasDeparted ? 0 : 1)

            Text(flight.text)
                .frame(width: destination.width, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(hasDeparted ? 1 : 0)
        }
        .font(.body)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
        .offset(x: position.x, y: position.y)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: flight.destination != nil) {
            guard flight.destination != nil else {
                // A parent can remove the submitted row before the lazy stack
                // realizes it. Never leave that submission hidden indefinitely.
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                onComplete()
                return
            }
            guard !hasDeparted else { return }
            // Give the source layout a frame before changing its presentation.
            do { try await Task.sleep(for: .milliseconds(16)) } catch { return }
            withAnimation(.easeInOut(duration: 0.36), completionCriteria: .removed) {
                hasDeparted = true
            } completion: {
                onComplete()
            }
        }
    }
}

struct AssistantWaitingRow: View {
    var body: some View {
        HStack {
            AssistantWaitingDots()
                .padding(.horizontal, AIChatLayout.bubbleHorizontalPadding)
                .padding(.vertical, AIChatLayout.bubbleVerticalPadding)
                .background(
                    Color.secondary.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: AIChatLayout.bubbleCornerRadius)
                )
            Spacer(minLength: AIChatLayout.messageOppositeInset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Waiting for response", bundle: .module))
        .accessibilityIdentifier("aiChat.waiting")
    }
}

private struct AssistantWaitingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 7

    var body: some View {
        let motionEnabled = !reduceMotion && scenePhase == .active
        let bounceHeight = diameter * 0.8
        HStack(spacing: diameter * 0.7) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: diameter, height: diameter)
                    .keyframeAnimator(
                        initialValue: CGFloat.zero,
                        repeating: motionEnabled
                    ) { dot, offset in
                        dot.offset(y: motionEnabled ? offset : 0)
                    } keyframes: { _ in
                        LinearKeyframe(0, duration: Double(index) * 0.22)
                        CubicKeyframe(-bounceHeight, duration: 0.16)
                        CubicKeyframe(0, duration: 0.22)
                        LinearKeyframe(0, duration: 1.25 - Double(index) * 0.22 - 0.38)
                    }
            }
        }
        .padding(.top, diameter * 0.8)
        .padding(.bottom, diameter * 0.25)
    }
}

#if DEBUG
#Preview("Waiting for response") {
    AssistantWaitingRow()
        .padding()
}
#endif

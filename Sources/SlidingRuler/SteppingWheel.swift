//
//  SteppingWheel.swift
//
//  SlidingRuler
//
//  MIT License
//
//  Copyright (c) 2020 Pierre Tacchi
//

import SwiftUI
import UIKit

/// State machine for the stepping wheel
enum SteppingWheelState {
    case idle
    case dragging
    case decelerating
}

/// Configuration for SteppingWheel appearance
public struct SteppingWheelConfig {
    /// Spacing between tick marks in points
    public var tickSpacing: CGFloat

    /// Whether to show value labels
    public var showLabels: Bool

    /// Show label every N ticks (only when showLabels is true)
    public var labelInterval: Int

    /// Accent color for the center indicator
    public var accentColor: Color

    /// Height of the control
    public var height: CGFloat

    /// Tick height for normal ticks
    public var tickHeight: CGFloat

    /// Tick height for the selected/center tick
    public var selectedTickHeight: CGFloat

    public init(
        tickSpacing: CGFloat = 20,
        showLabels: Bool = false,
        labelInterval: Int = 5,
        accentColor: Color = Color(red: 0.85, green: 0.65, blue: 0.25), // Gold
        height: CGFloat = 50,
        tickHeight: CGFloat = 16,
        selectedTickHeight: CGFloat = 24
    ) {
        self.tickSpacing = tickSpacing
        self.showLabels = showLabels
        self.labelInterval = labelInterval
        self.accentColor = accentColor
        self.height = height
        self.tickHeight = tickHeight
        self.selectedTickHeight = selectedTickHeight
    }

    public static let `default` = SteppingWheelConfig()
}

/// A discrete stepping wheel control for precise value selection.
/// Unlike SlidingRuler, this control snaps to discrete steps with no intermediate values.
@available(iOS 13.0, *)
public struct SteppingWheel<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {

    // MARK: - Configuration

    /// Bound value - always snapped to step multiples
    @Binding private var value: V

    /// Finite range of possible values
    private let bounds: ClosedRange<V>

    /// Step size - value changes in multiples of this
    private let step: V.Stride

    /// Callback when step changes
    private let onStep: ((V) -> Void)?

    /// Callback when editing starts/ends
    private let onEditingChanged: ((Bool) -> Void)?

    /// Visual configuration
    private let config: SteppingWheelConfig

    // MARK: - Internal State

    @State private var controlWidth: CGFloat = 0
    @State private var state: SteppingWheelState = .idle
    @State private var dragStartValue: V = 0
    @State private var dragOffset: CGFloat = 0
    @State private var previousStepIndex: Int = 0
    @State private var animationTimer: VSynchedTimer?
    @State private var velocity: CGFloat = 0

    // MARK: - Computed Properties

    /// Current step index (0-based from lower bound)
    private var currentStepIndex: Int {
        Int(((value - bounds.lowerBound) / V(step)).rounded())
    }

    /// Total number of steps in the range
    private var stepCount: Int {
        Int((bounds.upperBound - bounds.lowerBound) / V(step)) + 1
    }

    /// Value snapped to nearest step
    private var snappedValue: V {
        let stepIndex = ((value - bounds.lowerBound) / V(step)).rounded()
        let snapped = bounds.lowerBound + V(stepIndex) * V(step)
        return snapped.clamped(to: bounds)
    }

    /// Offset for rendering based on current value
    private var renderOffset: CGFloat {
        let stepIndex = (value - bounds.lowerBound) / V(step)
        return -CGFloat(stepIndex) * config.tickSpacing
    }

    // MARK: - Initialization

    /// Creates a SteppingWheel with discrete step positions.
    /// - Parameters:
    ///   - value: Binding to the current value (will be snapped to step multiples)
    ///   - bounds: Finite range of allowed values
    ///   - step: Size of each discrete step
    ///   - config: Visual configuration
    ///   - onStep: Called when value changes to a new step
    ///   - onEditingChanged: Called when drag begins/ends
    public init(
        value: Binding<V>,
        in bounds: ClosedRange<V>,
        step: V.Stride = 1,
        config: SteppingWheelConfig = .default,
        onStep: ((V) -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.config = config
        self.onStep = onStep
        self.onEditingChanged = onEditingChanged
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Step cells
                HStack(spacing: 0) {
                    ForEach(0..<stepCount, id: \.self) { index in
                        TickView(
                            index: index,
                            value: bounds.lowerBound + V(index) * V(step),
                            isSelected: index == currentStepIndex,
                            distanceFromCenter: distanceFromCenter(index: index, width: geometry.size.width),
                            config: config
                        )
                    }
                }
                .offset(x: effectiveOffset(in: geometry.size.width))

                // Center indicator
                CenterIndicator(accentColor: config.accentColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear {
                controlWidth = geometry.size.width
            }
        }
        .frame(height: config.height)
        .contentShape(Rectangle())
        .onHorizontalDragGesture(
            initialTouch: handleTouchBegan,
            prematureEnd: handleTouchEnded,
            perform: handleDrag
        )
    }

    // MARK: - Distance Calculation

    private func distanceFromCenter(index: Int, width: CGFloat) -> CGFloat {
        let centerIndex = currentStepIndex
        let indexDiff = abs(index - centerIndex)
        let pixelDistance = CGFloat(indexDiff) * config.tickSpacing
        let maxDistance = width / 2
        return min(pixelDistance / maxDistance, 1.0)
    }

    // MARK: - Offset Calculation

    private func effectiveOffset(in width: CGFloat) -> CGFloat {
        let centerOffset = width / 2 - config.tickSpacing / 2

        switch state {
        case .idle:
            return centerOffset + renderOffset
        case .dragging, .decelerating:
            let stepIndex = (dragStartValue - bounds.lowerBound) / V(step)
            let baseOffset = -CGFloat(stepIndex) * config.tickSpacing
            return centerOffset + baseOffset + dragOffset
        }
    }

    // MARK: - Gesture Handling

    private func handleTouchBegan() {
        if state == .decelerating {
            animationTimer?.cancel()
            animationTimer = nil
        }
        state = .idle
        velocity = 0
    }

    private func handleTouchEnded() {
        if state == .dragging {
            state = .idle
            snapToNearestStep()
            onEditingChanged?(false)
        }
    }

    private func handleDrag(_ gesture: HorizontalDragGestureValue) {
        switch gesture.state {
        case .began:
            dragBegan(gesture)
        case .changed:
            dragChanged(gesture)
        case .ended:
            dragEnded(gesture)
        default:
            break
        }
    }

    private func dragBegan(_ gesture: HorizontalDragGestureValue) {
        animationTimer?.cancel()
        animationTimer = nil

        dragStartValue = value
        dragOffset = 0
        previousStepIndex = currentStepIndex
        velocity = 0
        state = .dragging
        onEditingChanged?(true)
    }

    private func dragChanged(_ gesture: HorizontalDragGestureValue) {
        dragOffset = gesture.translation.width
        velocity = gesture.velocity

        // Calculate which step we're on based on drag
        let totalOffset = dragOffset
        let stepsDelta = Int((-totalOffset / config.tickSpacing).rounded())
        let newStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step)) + stepsDelta
        let clampedIndex = max(0, min(stepCount - 1, newStepIndex))

        // Haptic feedback when crossing step boundary
        if clampedIndex != previousStepIndex {
            tickHaptic()
            previousStepIndex = clampedIndex
        }

        // Update value to the step we're on
        let newValue = bounds.lowerBound + V(clampedIndex) * V(step)
        if value != newValue {
            value = newValue
            onStep?(newValue)
        }
    }

    private func dragEnded(_ gesture: HorizontalDragGestureValue) {
        let endVelocity = gesture.velocity

        // If velocity is significant, apply smooth inertia
        if abs(endVelocity) > 50 {
            applyInertia(velocity: endVelocity)
        } else {
            state = .idle
            snapToNearestStep()
            onEditingChanged?(false)
        }
    }

    // MARK: - Smooth Inertia Physics

    private func applyInertia(velocity: CGFloat) {
        state = .decelerating

        // Physics constants - tuned for smooth, natural feel
        let friction: CGFloat = 0.97  // Higher = more slide
        let minVelocity: CGFloat = 20  // Stop threshold

        var currentVelocity = velocity
        var currentOffset = dragOffset
        let startStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step))

        animationTimer = VSynchedTimer(duration: 3.0, animations: { progress, deltaTime in
            // Apply friction (exponential decay)
            currentVelocity *= friction

            // Update offset based on velocity
            let frameOffset = currentVelocity * CGFloat(deltaTime)
            currentOffset += frameOffset
            self.dragOffset = currentOffset

            // Calculate current step from offset
            let stepsDelta = Int((-currentOffset / config.tickSpacing).rounded())
            let currentIndex = max(0, min(stepCount - 1, startStepIndex + stepsDelta))

            // Haptic feedback on step crossing
            if currentIndex != self.previousStepIndex {
                self.tickHaptic()
                self.previousStepIndex = currentIndex

                // Update value
                let newValue = bounds.lowerBound + V(currentIndex) * V(step)
                if self.value != newValue {
                    self.value = newValue
                    self.onStep?(newValue)
                }
            }

            // Check if we should stop
            if abs(currentVelocity) < minVelocity {
                self.animationTimer?.cancel()
                self.finalizeDeceleration()
            }

        }, completion: { completed in
            if completed {
                self.finalizeDeceleration()
            }
        })
    }

    private func finalizeDeceleration() {
        // Animate snap to nearest step
        let targetValue = snappedValue
        let targetIndex = Int(((targetValue - bounds.lowerBound) / V(step)).rounded())
        let startStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step))
        let targetOffset = -CGFloat(targetIndex - startStepIndex) * config.tickSpacing

        let snapOffset = targetOffset - dragOffset

        if abs(snapOffset) > 1 {
            // Animate the snap
            let startOffset = dragOffset
            let snapDuration: TimeInterval = 0.15

            animationTimer = VSynchedTimer(duration: snapDuration, animations: { progress, _ in
                // Ease out
                let t = CGFloat(progress / snapDuration)
                let eased = 1 - pow(1 - t, 3)
                self.dragOffset = startOffset + snapOffset * eased
            }, completion: { _ in
                self.state = .idle
                self.dragOffset = 0
                self.value = targetValue
                self.onEditingChanged?(false)
            })
        } else {
            state = .idle
            dragOffset = 0
            value = targetValue
            onEditingChanged?(false)
        }
    }

    // MARK: - Snap

    private func snapToNearestStep() {
        let snapped = snappedValue
        if value != snapped {
            value = snapped
            onStep?(snapped)
        }
    }

    // MARK: - Haptics

    private func tickHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
    }
}

// MARK: - Tick View

private struct TickView<V: BinaryFloatingPoint>: View {
    let index: Int
    let value: V
    let isSelected: Bool
    let distanceFromCenter: CGFloat
    let config: SteppingWheelConfig

    var body: some View {
        VStack(spacing: 2) {
            // Tick mark
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(tickOpacity))
                .frame(width: 2, height: tickHeight)

            // Value label (only if enabled and at interval)
            if config.showLabels && index % config.labelInterval == 0 {
                Text("\(Int(value))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(tickOpacity))
            }
        }
        .frame(width: config.tickSpacing)
    }

    private var tickOpacity: Double {
        // Fade out towards edges
        let fadeStart: CGFloat = 0.3
        if distanceFromCenter < fadeStart {
            return 0.7
        }
        return Double(max(0.15, 0.7 * (1 - (distanceFromCenter - fadeStart) / (1 - fadeStart))))
    }

    private var tickHeight: CGFloat {
        isSelected ? config.selectedTickHeight : config.tickHeight
    }
}

// MARK: - Center Indicator

private struct CenterIndicator: View {
    let accentColor: Color

    var body: some View {
        ZStack {
            // Background rounded rectangle
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.2))
                .frame(width: 36, height: 40)

            // Accent line in center
            RoundedRectangle(cornerRadius: 1)
                .fill(accentColor)
                .frame(width: 2, height: 24)
        }
    }
}

// MARK: - Clamped Extension

private extension BinaryFloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

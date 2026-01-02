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

    // MARK: - Internal State

    @State private var controlWidth: CGFloat = 0
    @State private var state: SteppingWheelState = .idle
    @State private var dragStartValue: V = 0
    @State private var dragOffset: CGFloat = 0
    @State private var previousStepIndex: Int = 0
    @State private var animationTimer: VSynchedTimer?

    // MARK: - Computed Properties

    /// Width of each step cell in points
    private let cellWidth: CGFloat = 60

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
        return -CGFloat(stepIndex) * cellWidth
    }

    // MARK: - Initialization

    /// Creates a SteppingWheel with discrete step positions.
    /// - Parameters:
    ///   - value: Binding to the current value (will be snapped to step multiples)
    ///   - bounds: Finite range of allowed values
    ///   - step: Size of each discrete step
    ///   - onStep: Called when value changes to a new step
    ///   - onEditingChanged: Called when drag begins/ends
    public init(
        value: Binding<V>,
        in bounds: ClosedRange<V>,
        step: V.Stride = 1,
        onStep: ((V) -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
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
                        StepCell(
                            index: index,
                            value: bounds.lowerBound + V(index) * V(step),
                            isSelected: index == currentStepIndex,
                            cellWidth: cellWidth
                        )
                    }
                }
                .offset(x: effectiveOffset(in: geometry.size.width))

                // Center cursor
                CursorView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear {
                controlWidth = geometry.size.width
            }
        }
        .frame(height: 60)
        .contentShape(Rectangle())
        .onHorizontalDragGesture(
            initialTouch: handleTouchBegan,
            prematureEnd: handleTouchEnded,
            perform: handleDrag
        )
    }

    // MARK: - Offset Calculation

    private func effectiveOffset(in width: CGFloat) -> CGFloat {
        let centerOffset = width / 2 - cellWidth / 2

        switch state {
        case .idle:
            return centerOffset + renderOffset
        case .dragging, .decelerating:
            let stepIndex = (dragStartValue - bounds.lowerBound) / V(step)
            let baseOffset = -CGFloat(stepIndex) * cellWidth
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
        state = .dragging
        onEditingChanged?(true)
    }

    private func dragChanged(_ gesture: HorizontalDragGestureValue) {
        dragOffset = gesture.translation.width

        // Calculate which step we're on based on drag
        let totalOffset = dragOffset
        let stepsDelta = Int((-totalOffset / cellWidth).rounded())
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
        let velocity = gesture.velocity

        // If velocity is significant, apply inertia
        if abs(velocity) > 100 {
            applyInertia(velocity: velocity)
        } else {
            state = .idle
            snapToNearestStep()
            onEditingChanged?(false)
        }
    }

    // MARK: - Inertia

    private func applyInertia(velocity: CGFloat) {
        state = .decelerating

        let decelerationRate: CGFloat = 0.992
        let startOffset = dragOffset
        let startStepIndex = currentStepIndex

        // Calculate how many steps we'll travel
        let totalDistance = velocity * (1 / (1 - decelerationRate)) / 1000
        let stepsToTravel = Int((totalDistance / cellWidth).rounded())
        let targetStepIndex = max(0, min(stepCount - 1, startStepIndex - stepsToTravel))

        // Animate to target step
        let targetOffset = startOffset - CGFloat(targetStepIndex - startStepIndex) * cellWidth
        let duration: TimeInterval = min(0.4, Double(abs(totalDistance)) / 500.0)

        if duration < 0.05 {
            // Too short, just snap
            finalizeToStep(targetStepIndex)
            return
        }

        animationTimer = VSynchedTimer(duration: duration, animations: { progress, _ in
            // Ease out curve
            let easedProgress = 1 - pow(1 - CGFloat(progress / duration), 3)
            let currentOffset = startOffset + (targetOffset - startOffset) * easedProgress
            self.dragOffset = currentOffset

            // Check for step crossings during animation
            let currentStepsDelta = Int((-currentOffset / cellWidth).rounded())
            let currentIndex = Int((dragStartValue - bounds.lowerBound) / V(step)) + currentStepsDelta
            let clampedIndex = max(0, min(stepCount - 1, currentIndex))

            if clampedIndex != previousStepIndex {
                tickHaptic()
                previousStepIndex = clampedIndex

                let newValue = bounds.lowerBound + V(clampedIndex) * V(step)
                if value != newValue {
                    value = newValue
                    onStep?(newValue)
                }
            }
        }, completion: { completed in
            if completed {
                finalizeToStep(targetStepIndex)
            }
        })
    }

    private func finalizeToStep(_ stepIndex: Int) {
        let clampedIndex = max(0, min(stepCount - 1, stepIndex))
        let newValue = bounds.lowerBound + V(clampedIndex) * V(step)

        state = .idle
        dragOffset = 0
        value = newValue
        onStep?(newValue)
        onEditingChanged?(false)
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
        generator.impactOccurred(intensity: 0.6)
    }

    private func boundaryHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred(intensity: 0.8)
    }
}

// MARK: - Step Cell View

private struct StepCell<V: BinaryFloatingPoint>: View {
    let index: Int
    let value: V
    let isSelected: Bool
    let cellWidth: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            // Tick mark
            RoundedRectangle(cornerRadius: 1)
                .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                .frame(width: isSelected ? 3 : 2, height: isSelected ? 28 : 20)

            // Value label (only show for selected or every 5th)
            if isSelected || index % 5 == 0 {
                Text("\(Int(value))")
                    .font(isSelected ? .caption.bold() : .caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .frame(width: cellWidth)
    }
}

// MARK: - Cursor View

private struct CursorView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Triangle pointer
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 12))
                .foregroundColor(.red)

            // Line
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 35)
        }
    }
}

// MARK: - Clamped Extension (if not already available)

private extension BinaryFloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

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

    /// Tick height for minor ticks
    public var minorTickHeight: CGFloat

    /// Tick height for major ticks (every 5th)
    public var majorTickHeight: CGFloat

    /// Major tick interval
    public var majorTickInterval: Int

    public init(
        tickSpacing: CGFloat = 12,
        showLabels: Bool = false,
        labelInterval: Int = 10,
        accentColor: Color = Color(red: 0.83, green: 0.65, blue: 0.45), // Warm gold
        height: CGFloat = 56,
        minorTickHeight: CGFloat = 12,
        majorTickHeight: CGFloat = 20,
        majorTickInterval: Int = 5
    ) {
        self.tickSpacing = tickSpacing
        self.showLabels = showLabels
        self.labelInterval = labelInterval
        self.accentColor = accentColor
        self.height = height
        self.minorTickHeight = minorTickHeight
        self.majorTickHeight = majorTickHeight
        self.majorTickInterval = majorTickInterval
    }

    public static let `default` = SteppingWheelConfig()
}

/// A discrete stepping wheel control for precise value selection.
/// Premium design inspired by professional video equipment.
@available(iOS 13.0, *)
public struct SteppingWheel<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {

    // MARK: - Configuration

    @Binding private var value: V
    private let bounds: ClosedRange<V>
    private let step: V.Stride
    private let onStep: ((V) -> Void)?
    private let onEditingChanged: ((Bool) -> Void)?
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

    private var currentStepIndex: Int {
        Int(((value - bounds.lowerBound) / V(step)).rounded())
    }

    private var stepCount: Int {
        Int((bounds.upperBound - bounds.lowerBound) / V(step)) + 1
    }

    private var snappedValue: V {
        let stepIndex = ((value - bounds.lowerBound) / V(step)).rounded()
        let snapped = bounds.lowerBound + V(stepIndex) * V(step)
        return snapped.clamped(to: bounds)
    }

    private var renderOffset: CGFloat {
        let stepIndex = (value - bounds.lowerBound) / V(step)
        return -CGFloat(stepIndex) * config.tickSpacing
    }

    // MARK: - Initialization

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
                // Atmospheric background
                WheelBackground()

                // Tick marks layer
                HStack(spacing: 0) {
                    ForEach(0..<stepCount, id: \.self) { index in
                        PremiumTickView(
                            index: index,
                            value: bounds.lowerBound + V(index) * V(step),
                            distanceFromCenter: distanceFromCenter(index: index, width: geometry.size.width),
                            config: config
                        )
                    }
                }
                .offset(x: effectiveOffset(in: geometry.size.width))

                // Edge fade overlays
                HStack {
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 60)

                    Spacer()

                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 60)
                }

                // Premium center indicator
                CenterIndicatorPremium(accentColor: config.accentColor)
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
        let rawOffset = gesture.translation.width
        velocity = gesture.velocity

        // Calculate boundary limits for the offset
        let startStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step))
        let maxOffsetLeft = CGFloat(startStepIndex) * config.tickSpacing  // Can scroll left to index 0
        let maxOffsetRight = -CGFloat(stepCount - 1 - startStepIndex) * config.tickSpacing  // Can scroll right to last index

        // Clamp offset to valid bounds with rubber-band effect at edges
        let clampedOffset: CGFloat
        if rawOffset > maxOffsetLeft {
            // At start boundary - rubber band
            let overflow = rawOffset - maxOffsetLeft
            clampedOffset = maxOffsetLeft + overflow * 0.2
        } else if rawOffset < maxOffsetRight {
            // At end boundary - rubber band
            let overflow = rawOffset - maxOffsetRight
            clampedOffset = maxOffsetRight + overflow * 0.2
        } else {
            clampedOffset = rawOffset
        }

        dragOffset = clampedOffset

        let totalOffset = rawOffset  // Use raw for step calculation
        let stepsDelta = Int((-totalOffset / config.tickSpacing).rounded())
        let newStepIndex = startStepIndex + stepsDelta
        let clampedIndex = max(0, min(stepCount - 1, newStepIndex))

        if clampedIndex != previousStepIndex {
            tickHaptic()
            previousStepIndex = clampedIndex
        }

        let newValue = bounds.lowerBound + V(clampedIndex) * V(step)
        if value != newValue {
            value = newValue
            onStep?(newValue)
        }
    }

    private func dragEnded(_ gesture: HorizontalDragGestureValue) {
        let endVelocity = gesture.velocity

        // Check if we're at a boundary
        let isAtStartBoundary = currentStepIndex == 0
        let isAtEndBoundary = currentStepIndex == stepCount - 1

        // Don't apply inertia if at boundary and velocity would push past it
        let shouldApplyInertia: Bool
        if isAtStartBoundary && endVelocity > 0 {
            // At start, trying to go left - no inertia
            shouldApplyInertia = false
        } else if isAtEndBoundary && endVelocity < 0 {
            // At end, trying to go right - no inertia
            shouldApplyInertia = false
        } else {
            shouldApplyInertia = abs(endVelocity) > 50
        }

        if shouldApplyInertia {
            applyInertia(velocity: endVelocity)
        } else {
            // Snap back from any rubber-band offset
            animateSnapBack()
        }
    }

    private func animateSnapBack() {
        let targetOffset: CGFloat = 0
        let startOffset = dragOffset

        if abs(startOffset) < 1 {
            state = .idle
            dragOffset = 0
            snapToNearestStep()
            onEditingChanged?(false)
            return
        }

        state = .decelerating
        let snapDuration: TimeInterval = 0.25

        animationTimer = VSynchedTimer(duration: snapDuration, animations: { progress, _ in
            let t = CGFloat(progress / snapDuration)
            // Ease out cubic
            let eased = 1 - pow(1 - t, 3)
            self.dragOffset = startOffset * (1 - eased)
        }, completion: { _ in
            self.state = .idle
            self.dragOffset = 0
            self.snapToNearestStep()
            self.onEditingChanged?(false)
        })
    }

    // MARK: - Smooth Inertia Physics

    private func applyInertia(velocity: CGFloat) {
        state = .decelerating

        let friction: CGFloat = 0.97
        let minVelocity: CGFloat = 20

        var currentVelocity = velocity
        var currentOffset = dragOffset
        let startStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step))

        // Calculate boundary limits for the offset
        let maxOffsetLeft = CGFloat(startStepIndex) * config.tickSpacing
        let maxOffsetRight = -CGFloat(stepCount - 1 - startStepIndex) * config.tickSpacing

        animationTimer = VSynchedTimer(duration: 3.0, animations: { progress, deltaTime in
            currentVelocity *= friction

            let frameOffset = currentVelocity * CGFloat(deltaTime)
            currentOffset += frameOffset

            // Check if we hit boundaries
            var hitBoundary = false
            if currentOffset > maxOffsetLeft {
                currentOffset = maxOffsetLeft
                currentVelocity = 0
                hitBoundary = true
            } else if currentOffset < maxOffsetRight {
                currentOffset = maxOffsetRight
                currentVelocity = 0
                hitBoundary = true
            }

            self.dragOffset = currentOffset

            let stepsDelta = Int((-currentOffset / config.tickSpacing).rounded())
            let currentIndex = max(0, min(self.stepCount - 1, startStepIndex + stepsDelta))

            if currentIndex != self.previousStepIndex {
                self.tickHaptic()
                self.previousStepIndex = currentIndex

                let newValue = self.bounds.lowerBound + V(currentIndex) * V(self.step)
                if self.value != newValue {
                    self.value = newValue
                    self.onStep?(newValue)
                }
            }

            // Stop if velocity too low or hit boundary
            if abs(currentVelocity) < minVelocity || hitBoundary {
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
        let targetValue = snappedValue
        let targetIndex = Int(((targetValue - bounds.lowerBound) / V(step)).rounded())
        let startStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step))
        let targetOffset = -CGFloat(targetIndex - startStepIndex) * config.tickSpacing

        let snapOffset = targetOffset - dragOffset

        if abs(snapOffset) > 1 {
            let startOffset = dragOffset
            let snapDuration: TimeInterval = 0.15

            animationTimer = VSynchedTimer(duration: snapDuration, animations: { progress, _ in
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

// MARK: - Wheel Background

private struct WheelBackground: View {
    var body: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: [
                    Color(white: 0.08),
                    Color(white: 0.05),
                    Color(white: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle noise texture effect via overlapping gradients
            LinearGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.clear,
                    Color.white.opacity(0.01)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Top highlight line
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.5)
                Spacer()
            }

            // Bottom shadow line
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Premium Tick View

private struct PremiumTickView<V: BinaryFloatingPoint>: View {
    let index: Int
    let value: V
    let distanceFromCenter: CGFloat
    let config: SteppingWheelConfig

    private var isMajor: Bool {
        index % config.majorTickInterval == 0
    }

    private var tickHeight: CGFloat {
        isMajor ? config.majorTickHeight : config.minorTickHeight
    }

    private var tickWidth: CGFloat {
        isMajor ? 2.5 : 1.5
    }

    private var tickOpacity: Double {
        // Smooth fade based on distance from center
        let baseBrightness: Double = isMajor ? 0.7 : 0.45

        if distanceFromCenter < 0.2 {
            return baseBrightness
        } else if distanceFromCenter < 0.5 {
            let t = (distanceFromCenter - 0.2) / 0.3
            return baseBrightness * (1 - t * 0.4)
        } else {
            let t = (distanceFromCenter - 0.5) / 0.5
            return baseBrightness * 0.6 * (1 - t * 0.8)
        }
    }

    private var glowIntensity: Double {
        // Only center ticks get glow
        if distanceFromCenter < 0.15 {
            return 0.4 * (1 - distanceFromCenter / 0.15)
        }
        return 0
    }

    var body: some View {
        ZStack {
            // Glow layer for center ticks
            if glowIntensity > 0 {
                RoundedRectangle(cornerRadius: tickWidth / 2)
                    .fill(config.accentColor.opacity(glowIntensity * 0.5))
                    .frame(width: tickWidth + 4, height: tickHeight + 4)
                    .blur(radius: 4)
            }

            // Main tick
            RoundedRectangle(cornerRadius: tickWidth / 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.6).opacity(tickOpacity),
                            Color(white: 0.35).opacity(tickOpacity * 0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: tickWidth, height: tickHeight)

            // Top highlight on tick
            VStack {
                RoundedRectangle(cornerRadius: tickWidth / 2)
                    .fill(Color.white.opacity(tickOpacity * 0.3))
                    .frame(width: tickWidth, height: 2)
                Spacer()
            }
            .frame(height: tickHeight)
        }
        .frame(width: config.tickSpacing, height: config.majorTickHeight + 8)
    }
}

// MARK: - Premium Center Indicator

private struct CenterIndicatorPremium: View {
    let accentColor: Color

    var body: some View {
        ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.opacity(0.15))
                .frame(width: 44, height: 48)
                .blur(radius: 8)

            // Glass container
            ZStack {
                // Dark glass background
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.18),
                                Color(white: 0.12),
                                Color(white: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Inner shadow
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.6),
                                Color.clear,
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )

                // Outer border
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.black.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
            .frame(width: 38, height: 44)

            // Accent line with glow
            ZStack {
                // Glow
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(accentColor)
                    .frame(width: 3, height: 26)
                    .blur(radius: 4)
                    .opacity(0.6)

                // Main line
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.9),
                                accentColor,
                                accentColor.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2.5, height: 24)

                // Highlight on line
                VStack {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 1.5, height: 6)
                    Spacer()
                }
                .frame(height: 24)
            }
        }
    }
}

// MARK: - Clamped Extension

private extension BinaryFloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

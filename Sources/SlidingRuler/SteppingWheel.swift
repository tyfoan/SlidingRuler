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

// MARK: - State

enum SteppingWheelState {
    case idle
    case dragging
    case decelerating
}

// MARK: - Style Configuration

/// Complete visual style for SteppingWheel
public struct SteppingWheelStyle {

    // MARK: - Tick Appearance

    public var tickColor: Color
    public var minorTickWidth: CGFloat
    public var majorTickWidth: CGFloat
    public var minorTickHeight: CGFloat
    public var majorTickHeight: CGFloat
    public var majorTickInterval: Int
    public var tickFadeEnabled: Bool
    public var tickCenterOpacity: CGFloat
    public var tickEdgeOpacity: CGFloat

    // MARK: - Center Indicator

    public var showCenterIndicator: Bool
    public var centerIndicatorStyle: CenterIndicatorStyle
    public var accentColor: Color
    public var centerIndicatorWidth: CGFloat
    public var centerIndicatorHeight: CGFloat

    // MARK: - Background

    public var backgroundColor: Color?
    public var showEdgeFade: Bool
    public var edgeFadeColor: Color
    public var edgeFadeWidth: CGFloat

    // MARK: - Layout

    public var tickSpacing: CGFloat
    public var height: CGFloat

    public enum CenterIndicatorStyle {
        case line
        case lineWithGlow
        case box
        case triangle
        case none
    }

    public init(
        tickColor: Color = .white,
        minorTickWidth: CGFloat = 1.5,
        majorTickWidth: CGFloat = 2,
        minorTickHeight: CGFloat = 12,
        majorTickHeight: CGFloat = 20,
        majorTickInterval: Int = 5,
        tickFadeEnabled: Bool = true,
        tickCenterOpacity: CGFloat = 0.6,
        tickEdgeOpacity: CGFloat = 0.15,
        showCenterIndicator: Bool = true,
        centerIndicatorStyle: CenterIndicatorStyle = .line,
        accentColor: Color = .white,
        centerIndicatorWidth: CGFloat = 2,
        centerIndicatorHeight: CGFloat = 28,
        backgroundColor: Color? = nil,
        showEdgeFade: Bool = true,
        edgeFadeColor: Color = .black,
        edgeFadeWidth: CGFloat = 50,
        tickSpacing: CGFloat = 12,
        height: CGFloat = 48
    ) {
        self.tickColor = tickColor
        self.minorTickWidth = minorTickWidth
        self.majorTickWidth = majorTickWidth
        self.minorTickHeight = minorTickHeight
        self.majorTickHeight = majorTickHeight
        self.majorTickInterval = majorTickInterval
        self.tickFadeEnabled = tickFadeEnabled
        self.tickCenterOpacity = tickCenterOpacity
        self.tickEdgeOpacity = tickEdgeOpacity
        self.showCenterIndicator = showCenterIndicator
        self.centerIndicatorStyle = centerIndicatorStyle
        self.accentColor = accentColor
        self.centerIndicatorWidth = centerIndicatorWidth
        self.centerIndicatorHeight = centerIndicatorHeight
        self.backgroundColor = backgroundColor
        self.showEdgeFade = showEdgeFade
        self.edgeFadeColor = edgeFadeColor
        self.edgeFadeWidth = edgeFadeWidth
        self.tickSpacing = tickSpacing
        self.height = height
    }

    // MARK: - Presets

    public static let minimal = SteppingWheelStyle(
        tickColor: .white,
        minorTickWidth: 1,
        majorTickWidth: 1.5,
        minorTickHeight: 10,
        majorTickHeight: 16,
        majorTickInterval: 5,
        tickFadeEnabled: true,
        tickCenterOpacity: 0.5,
        tickEdgeOpacity: 0.1,
        showCenterIndicator: true,
        centerIndicatorStyle: .line,
        accentColor: .white,
        centerIndicatorWidth: 2,
        centerIndicatorHeight: 24,
        backgroundColor: nil,
        showEdgeFade: false,
        edgeFadeColor: .black,
        edgeFadeWidth: 0,
        tickSpacing: 10,
        height: 40
    )

    public static let `default` = SteppingWheelStyle()

    public static func pro(accent: Color) -> SteppingWheelStyle {
        SteppingWheelStyle(
            tickColor: .white,
            minorTickWidth: 1.5,
            majorTickWidth: 2.5,
            minorTickHeight: 12,
            majorTickHeight: 22,
            majorTickInterval: 5,
            tickFadeEnabled: true,
            tickCenterOpacity: 0.7,
            tickEdgeOpacity: 0.1,
            showCenterIndicator: true,
            centerIndicatorStyle: .lineWithGlow,
            accentColor: accent,
            centerIndicatorWidth: 2.5,
            centerIndicatorHeight: 30,
            backgroundColor: Color(white: 0.06),
            showEdgeFade: true,
            edgeFadeColor: .black,
            edgeFadeWidth: 60,
            tickSpacing: 14,
            height: 52
        )
    }

    public static let compact = SteppingWheelStyle(
        tickColor: .white,
        minorTickWidth: 1,
        majorTickWidth: 1.5,
        minorTickHeight: 8,
        majorTickHeight: 12,
        majorTickInterval: 5,
        tickFadeEnabled: true,
        tickCenterOpacity: 0.5,
        tickEdgeOpacity: 0.15,
        showCenterIndicator: true,
        centerIndicatorStyle: .line,
        accentColor: .white,
        centerIndicatorWidth: 1.5,
        centerIndicatorHeight: 16,
        backgroundColor: nil,
        showEdgeFade: false,
        edgeFadeColor: .black,
        edgeFadeWidth: 0,
        tickSpacing: 8,
        height: 32
    )
}

// MARK: - Legacy Config (backward compatibility)

public struct SteppingWheelConfig {
    public var tickSpacing: CGFloat
    public var showLabels: Bool
    public var labelInterval: Int
    public var accentColor: Color
    public var height: CGFloat
    public var minorTickHeight: CGFloat
    public var majorTickHeight: CGFloat
    public var majorTickInterval: Int

    public init(
        tickSpacing: CGFloat = 12,
        showLabels: Bool = false,
        labelInterval: Int = 10,
        accentColor: Color = .white,
        height: CGFloat = 48,
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

    func toStyle() -> SteppingWheelStyle {
        SteppingWheelStyle(
            tickColor: .white,
            minorTickHeight: minorTickHeight,
            majorTickHeight: majorTickHeight,
            majorTickInterval: majorTickInterval,
            accentColor: accentColor,
            showEdgeFade: false,
            tickSpacing: tickSpacing,
            height: height
        )
    }
}

// MARK: - SteppingWheel View (Canvas-based for performance)

@available(iOS 15.0, *)
public struct SteppingWheel<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {

    @Binding private var value: V
    private let bounds: ClosedRange<V>
    private let step: V.Stride
    private let onStep: ((V) -> Void)?
    private let onEditingChanged: ((Bool) -> Void)?
    private let style: SteppingWheelStyle

    @State private var state: SteppingWheelState = .idle
    @State private var dragStartValue: V = 0
    @State private var dragOffset: CGFloat = 0
    @State private var previousStepIndex: Int = 0
    @State private var animationTimer: VSynchedTimer?
    @State private var velocity: CGFloat = 0

    // MARK: - Computed

    private var currentStepIndex: Int {
        Int(((value - bounds.lowerBound) / V(step)).rounded())
    }

    private var stepCount: Int {
        Int((bounds.upperBound - bounds.lowerBound) / V(step)) + 1
    }

    private var snappedValue: V {
        let stepIndex = ((value - bounds.lowerBound) / V(step)).rounded()
        let snapped = bounds.lowerBound + V(stepIndex) * V(step)
        return min(max(snapped, bounds.lowerBound), bounds.upperBound)
    }

    private var renderOffset: CGFloat {
        let stepIndex = (value - bounds.lowerBound) / V(step)
        return -CGFloat(stepIndex) * style.tickSpacing
    }

    // MARK: - Init

    public init(
        value: Binding<V>,
        in bounds: ClosedRange<V>,
        step: V.Stride = 1,
        style: SteppingWheelStyle = .default,
        onStep: ((V) -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.style = style
        self.onStep = onStep
        self.onEditingChanged = onEditingChanged
    }

    public init(
        value: Binding<V>,
        in bounds: ClosedRange<V>,
        step: V.Stride = 1,
        config: SteppingWheelConfig,
        onStep: ((V) -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.style = config.toStyle()
        self.onStep = onStep
        self.onEditingChanged = onEditingChanged
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                if let bgColor = style.backgroundColor {
                    bgColor
                }

                // Canvas-based ticks (high performance)
                ticksCanvas(size: geometry.size)

                // Edge fades
                if style.showEdgeFade {
                    edgeFadeOverlay
                }

                // Center indicator (overlay, not in canvas for flexibility)
                if style.showCenterIndicator {
                    centerIndicator
                }
            }
            .clipped()
        }
        .frame(height: style.height)
        .contentShape(Rectangle())
        .onHorizontalDragGesture(
            initialTouch: handleTouchBegan,
            prematureEnd: handleTouchEnded,
            perform: handleDrag
        )
    }

    // MARK: - Canvas Rendering (Performance Optimized)

    private func ticksCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let centerX = canvasSize.width / 2
            let centerY = canvasSize.height / 2

            // Calculate current offset
            let offset: CGFloat
            switch state {
            case .idle:
                offset = renderOffset
            case .dragging, .decelerating:
                let stepIndex = (dragStartValue - bounds.lowerBound) / V(step)
                let baseOffset = -CGFloat(stepIndex) * style.tickSpacing
                offset = baseOffset + dragOffset
            }

            // Calculate visible tick range (only draw what's on screen)
            let ticksOnScreen = Int(canvasSize.width / style.tickSpacing) + 4
            let centerTickIndex = Int(-offset / style.tickSpacing)
            let startTick = max(0, centerTickIndex - ticksOnScreen / 2)
            let endTick = min(stepCount - 1, centerTickIndex + ticksOnScreen / 2)

            // Draw only visible ticks
            for i in startTick...endTick {
                let tickX = centerX + offset + CGFloat(i) * style.tickSpacing

                // Skip if off-screen
                guard tickX > -style.tickSpacing && tickX < canvasSize.width + style.tickSpacing else {
                    continue
                }

                let isMajor = i % style.majorTickInterval == 0
                let tickWidth = isMajor ? style.majorTickWidth : style.minorTickWidth
                let tickHeight = isMajor ? style.majorTickHeight : style.minorTickHeight

                // Calculate opacity based on distance from center
                let distanceFromCenter = abs(tickX - centerX) / (canvasSize.width / 2)
                let opacity: CGFloat
                if style.tickFadeEnabled {
                    let range = style.tickCenterOpacity - style.tickEdgeOpacity
                    opacity = style.tickCenterOpacity - (min(distanceFromCenter, 1.0) * range)
                } else {
                    opacity = style.tickCenterOpacity
                }

                // Draw tick
                let tickRect = CGRect(
                    x: tickX - tickWidth / 2,
                    y: centerY - tickHeight / 2,
                    width: tickWidth,
                    height: tickHeight
                )

                let tickPath = Path(roundedRect: tickRect, cornerRadius: tickWidth / 2)
                context.fill(tickPath, with: .color(style.tickColor.opacity(opacity)))
            }
        }
    }

    // MARK: - Edge Fade Overlay

    private var edgeFadeOverlay: some View {
        HStack {
            LinearGradient(
                colors: [style.edgeFadeColor, style.edgeFadeColor.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: style.edgeFadeWidth)

            Spacer()

            LinearGradient(
                colors: [style.edgeFadeColor.opacity(0), style.edgeFadeColor],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: style.edgeFadeWidth)
        }
    }

    // MARK: - Center Indicator

    @ViewBuilder
    private var centerIndicator: some View {
        switch style.centerIndicatorStyle {
        case .line:
            RoundedRectangle(cornerRadius: style.centerIndicatorWidth / 2)
                .fill(style.accentColor)
                .frame(width: style.centerIndicatorWidth, height: style.centerIndicatorHeight)

        case .lineWithGlow:
            ZStack {
                RoundedRectangle(cornerRadius: style.centerIndicatorWidth / 2)
                    .fill(style.accentColor)
                    .frame(width: style.centerIndicatorWidth + 4, height: style.centerIndicatorHeight + 4)
                    .blur(radius: 6)
                    .opacity(0.5)

                RoundedRectangle(cornerRadius: style.centerIndicatorWidth / 2)
                    .fill(style.accentColor)
                    .frame(width: style.centerIndicatorWidth, height: style.centerIndicatorHeight)
            }

        case .box:
            RoundedRectangle(cornerRadius: 4)
                .stroke(style.accentColor, lineWidth: 1.5)
                .frame(width: style.centerIndicatorWidth * 10, height: style.centerIndicatorHeight)

        case .triangle:
            VStack(spacing: 0) {
                Triangle()
                    .fill(style.accentColor)
                    .frame(width: 8, height: 6)
                Spacer()
                Triangle()
                    .fill(style.accentColor)
                    .frame(width: 8, height: 6)
                    .rotationEffect(.degrees(180))
            }
            .frame(height: style.centerIndicatorHeight)

        case .none:
            EmptyView()
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

        let startStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step))
        let maxOffsetLeft = CGFloat(startStepIndex) * style.tickSpacing
        let maxOffsetRight = -CGFloat(stepCount - 1 - startStepIndex) * style.tickSpacing

        // Rubber band at edges
        let clampedOffset: CGFloat
        if rawOffset > maxOffsetLeft {
            let overflow = rawOffset - maxOffsetLeft
            clampedOffset = maxOffsetLeft + overflow * 0.2
        } else if rawOffset < maxOffsetRight {
            let overflow = rawOffset - maxOffsetRight
            clampedOffset = maxOffsetRight + overflow * 0.2
        } else {
            clampedOffset = rawOffset
        }

        dragOffset = clampedOffset

        let stepsDelta = Int((-rawOffset / style.tickSpacing).rounded())
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

        let isAtStartBoundary = currentStepIndex == 0
        let isAtEndBoundary = currentStepIndex == stepCount - 1

        let shouldApplyInertia: Bool
        if isAtStartBoundary && endVelocity > 0 {
            shouldApplyInertia = false
        } else if isAtEndBoundary && endVelocity < 0 {
            shouldApplyInertia = false
        } else {
            shouldApplyInertia = abs(endVelocity) > 50
        }

        if shouldApplyInertia {
            applyInertia(velocity: endVelocity)
        } else {
            animateSnapBack()
        }
    }

    private func animateSnapBack() {
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
            let eased = 1 - pow(1 - t, 3)
            self.dragOffset = startOffset * (1 - eased)
        }, completion: { _ in
            self.state = .idle
            self.dragOffset = 0
            self.snapToNearestStep()
            self.onEditingChanged?(false)
        })
    }

    // MARK: - Inertia

    private func applyInertia(velocity: CGFloat) {
        state = .decelerating

        let friction: CGFloat = 0.97
        let minVelocity: CGFloat = 20

        var currentVelocity = velocity
        var currentOffset = dragOffset
        let startStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step))

        let maxOffsetLeft = CGFloat(startStepIndex) * style.tickSpacing
        let maxOffsetRight = -CGFloat(stepCount - 1 - startStepIndex) * style.tickSpacing

        animationTimer = VSynchedTimer(duration: 3.0, animations: { progress, deltaTime in
            currentVelocity *= friction

            let frameOffset = currentVelocity * CGFloat(deltaTime)
            currentOffset += frameOffset

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

            let stepsDelta = Int((-currentOffset / self.style.tickSpacing).rounded())
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
        let targetOffset = -CGFloat(targetIndex - startStepIndex) * style.tickSpacing

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

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

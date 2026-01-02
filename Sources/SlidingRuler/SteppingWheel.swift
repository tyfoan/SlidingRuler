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

    /// Color of tick marks
    public var tickColor: Color

    /// Width of minor ticks
    public var minorTickWidth: CGFloat

    /// Width of major ticks
    public var majorTickWidth: CGFloat

    /// Height of minor ticks
    public var minorTickHeight: CGFloat

    /// Height of major ticks
    public var majorTickHeight: CGFloat

    /// Interval for major ticks (e.g., every 5th tick)
    public var majorTickInterval: Int

    /// Whether ticks fade towards edges
    public var tickFadeEnabled: Bool

    /// Opacity of ticks at center (1.0 = full)
    public var tickCenterOpacity: CGFloat

    /// Opacity of ticks at edges (0.0 = invisible)
    public var tickEdgeOpacity: CGFloat

    // MARK: - Center Indicator

    /// Whether to show the center indicator
    public var showCenterIndicator: Bool

    /// Style of center indicator
    public var centerIndicatorStyle: CenterIndicatorStyle

    /// Accent color for center indicator
    public var accentColor: Color

    /// Width of center indicator line
    public var centerIndicatorWidth: CGFloat

    /// Height of center indicator
    public var centerIndicatorHeight: CGFloat

    // MARK: - Background

    /// Background color (nil = transparent)
    public var backgroundColor: Color?

    /// Whether to show edge fade gradients
    public var showEdgeFade: Bool

    /// Color for edge fade (usually matches parent background)
    public var edgeFadeColor: Color

    /// Width of edge fade gradient
    public var edgeFadeWidth: CGFloat

    // MARK: - Layout

    /// Spacing between tick marks
    public var tickSpacing: CGFloat

    /// Total height of the control
    public var height: CGFloat

    // MARK: - Center Indicator Styles

    public enum CenterIndicatorStyle {
        case line           // Simple colored line
        case lineWithGlow   // Line with subtle glow
        case box            // Rounded rectangle box
        case triangle       // Triangle pointer
        case none           // No indicator (just use tick highlight)
    }

    // MARK: - Initializer

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

    // MARK: - Preset Styles

    /// Minimal clean style - simple white ticks on transparent background
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
        showEdgeFade: true,
        edgeFadeColor: .black,
        edgeFadeWidth: 40,
        tickSpacing: 10,
        height: 40
    )

    /// Default balanced style
    public static let `default` = SteppingWheelStyle()

    /// Pro style with accent glow
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

    /// Compact style for tight spaces
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
        showEdgeFade: true,
        edgeFadeColor: .black,
        edgeFadeWidth: 30,
        tickSpacing: 8,
        height: 32
    )
}

// MARK: - Legacy Config (for backward compatibility)

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

    /// Convert to new style system
    func toStyle() -> SteppingWheelStyle {
        SteppingWheelStyle(
            tickColor: .white,
            minorTickHeight: minorTickHeight,
            majorTickHeight: majorTickHeight,
            majorTickInterval: majorTickInterval,
            accentColor: accentColor,
            tickSpacing: tickSpacing,
            height: height
        )
    }
}

// MARK: - Tick Context (passed to custom tick views)

public struct SteppingWheelTickContext {
    public let index: Int
    public let isMajor: Bool
    public let distanceFromCenter: CGFloat  // 0 = center, 1 = edge
    public let tickSpacing: CGFloat
}

// MARK: - Convenience Initializers (default tick/indicator)

@available(iOS 13.0, *)
public extension SteppingWheel where TickContent == EmptyView, IndicatorContent == EmptyView {

    /// Simple initializer using built-in tick and indicator styles
    init(
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
        self.customTick = nil
        self.customIndicator = nil
    }

    /// Legacy config-based initializer (backward compatible)
    init(
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
        self.customTick = nil
        self.customIndicator = nil
    }
}

// MARK: - Convenience Initializers (custom tick only)

@available(iOS 13.0, *)
public extension SteppingWheel where IndicatorContent == EmptyView {

    /// Initializer with custom tick view, default indicator
    init(
        value: Binding<V>,
        in bounds: ClosedRange<V>,
        step: V.Stride = 1,
        style: SteppingWheelStyle = .default,
        onStep: ((V) -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil,
        @ViewBuilder tick: @escaping (SteppingWheelTickContext) -> TickContent
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.style = style
        self.onStep = onStep
        self.onEditingChanged = onEditingChanged
        self.customTick = tick
        self.customIndicator = nil
    }
}

// MARK: - Convenience Initializers (custom indicator only)

@available(iOS 13.0, *)
public extension SteppingWheel where TickContent == EmptyView {

    /// Initializer with custom indicator view, default ticks
    init(
        value: Binding<V>,
        in bounds: ClosedRange<V>,
        step: V.Stride = 1,
        style: SteppingWheelStyle = .default,
        onStep: ((V) -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil,
        @ViewBuilder indicator: @escaping () -> IndicatorContent
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.style = style
        self.onStep = onStep
        self.onEditingChanged = onEditingChanged
        self.customTick = nil
        self.customIndicator = indicator
    }
}

// MARK: - SteppingWheel View

@available(iOS 13.0, *)
public struct SteppingWheel<V, TickContent: View, IndicatorContent: View>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {

    // MARK: - Configuration

    @Binding private var value: V
    private let bounds: ClosedRange<V>
    private let step: V.Stride
    private let onStep: ((V) -> Void)?
    private let onEditingChanged: ((Bool) -> Void)?
    private let style: SteppingWheelStyle
    private let customTick: ((SteppingWheelTickContext) -> TickContent)?
    private let customIndicator: (() -> IndicatorContent)?

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
        return -CGFloat(stepIndex) * style.tickSpacing
    }

    // MARK: - Initializers

    /// Full customization initializer with custom tick and indicator views
    public init(
        value: Binding<V>,
        in bounds: ClosedRange<V>,
        step: V.Stride = 1,
        style: SteppingWheelStyle = .default,
        onStep: ((V) -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil,
        @ViewBuilder tick: @escaping (SteppingWheelTickContext) -> TickContent,
        @ViewBuilder indicator: @escaping () -> IndicatorContent
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.style = style
        self.onStep = onStep
        self.onEditingChanged = onEditingChanged
        self.customTick = tick
        self.customIndicator = indicator
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Background
                if let bgColor = style.backgroundColor {
                    bgColor
                }

                // Tick marks layer
                HStack(spacing: 0) {
                    ForEach(0..<stepCount, id: \.self) { index in
                        let context = SteppingWheelTickContext(
                            index: index,
                            isMajor: index % style.majorTickInterval == 0,
                            distanceFromCenter: distanceFromCenter(index: index, width: geometry.size.width),
                            tickSpacing: style.tickSpacing
                        )

                        if let customTick = customTick {
                            customTick(context)
                                .frame(width: style.tickSpacing)
                        } else {
                            TickView(
                                index: index,
                                distanceFromCenter: context.distanceFromCenter,
                                style: style
                            )
                        }
                    }
                }
                .offset(x: effectiveOffset(in: geometry.size.width))

                // Edge fade overlays
                if style.showEdgeFade {
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

                // Center indicator
                if let customIndicator = customIndicator {
                    customIndicator()
                } else if style.showCenterIndicator {
                    CenterIndicator(style: style)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear {
                controlWidth = geometry.size.width
            }
        }
        .frame(height: style.height)
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
        let pixelDistance = CGFloat(indexDiff) * style.tickSpacing
        let maxDistance = width / 2
        return min(pixelDistance / maxDistance, 1.0)
    }

    // MARK: - Offset Calculation

    private func effectiveOffset(in width: CGFloat) -> CGFloat {
        let centerOffset = width / 2 - style.tickSpacing / 2

        switch state {
        case .idle:
            return centerOffset + renderOffset
        case .dragging, .decelerating:
            let stepIndex = (dragStartValue - bounds.lowerBound) / V(step)
            let baseOffset = -CGFloat(stepIndex) * style.tickSpacing
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

        let startStepIndex = Int((dragStartValue - bounds.lowerBound) / V(step))
        let maxOffsetLeft = CGFloat(startStepIndex) * style.tickSpacing
        let maxOffsetRight = -CGFloat(stepCount - 1 - startStepIndex) * style.tickSpacing

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

        let totalOffset = rawOffset
        let stepsDelta = Int((-totalOffset / style.tickSpacing).rounded())
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

    // MARK: - Inertia Physics

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

// MARK: - Tick View

private struct TickView: View {
    let index: Int
    let distanceFromCenter: CGFloat
    let style: SteppingWheelStyle

    private var isMajor: Bool {
        index % style.majorTickInterval == 0
    }

    private var tickHeight: CGFloat {
        isMajor ? style.majorTickHeight : style.minorTickHeight
    }

    private var tickWidth: CGFloat {
        isMajor ? style.majorTickWidth : style.minorTickWidth
    }

    private var tickOpacity: CGFloat {
        guard style.tickFadeEnabled else {
            return style.tickCenterOpacity
        }

        let range = style.tickCenterOpacity - style.tickEdgeOpacity
        return style.tickCenterOpacity - (distanceFromCenter * range)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: tickWidth / 2)
            .fill(style.tickColor.opacity(Double(tickOpacity)))
            .frame(width: tickWidth, height: tickHeight)
            .frame(width: style.tickSpacing, height: style.majorTickHeight + 8)
    }
}

// MARK: - Center Indicator

private struct CenterIndicator: View {
    let style: SteppingWheelStyle

    var body: some View {
        switch style.centerIndicatorStyle {
        case .line:
            lineIndicator
        case .lineWithGlow:
            lineWithGlowIndicator
        case .box:
            boxIndicator
        case .triangle:
            triangleIndicator
        case .none:
            EmptyView()
        }
    }

    private var lineIndicator: some View {
        RoundedRectangle(cornerRadius: style.centerIndicatorWidth / 2)
            .fill(style.accentColor)
            .frame(width: style.centerIndicatorWidth, height: style.centerIndicatorHeight)
    }

    private var lineWithGlowIndicator: some View {
        ZStack {
            // Glow
            RoundedRectangle(cornerRadius: style.centerIndicatorWidth / 2)
                .fill(style.accentColor)
                .frame(width: style.centerIndicatorWidth + 4, height: style.centerIndicatorHeight + 4)
                .blur(radius: 6)
                .opacity(0.5)

            // Line
            RoundedRectangle(cornerRadius: style.centerIndicatorWidth / 2)
                .fill(style.accentColor)
                .frame(width: style.centerIndicatorWidth, height: style.centerIndicatorHeight)
        }
    }

    private var boxIndicator: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(style.accentColor, lineWidth: 1.5)
            .frame(width: style.centerIndicatorWidth * 10, height: style.centerIndicatorHeight)
    }

    private var triangleIndicator: some View {
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

// MARK: - Clamped Extension

private extension BinaryFloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

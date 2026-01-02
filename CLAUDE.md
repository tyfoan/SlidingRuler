# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build for iOS Simulator (required - this is an iOS-only package)
xcodebuild -scheme SlidingRuler -destination 'generic/platform=iOS Simulator' build

# Run tests
xcodebuild -scheme SlidingRuler -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture Overview

This package provides two SwiftUI controls for numeric value input, targeting iOS 13+ with Swift 5.2+.

### Two Control Types

| Control | Use Case | Value Type | Range |
|---------|----------|------------|-------|
| **SlidingRuler** | Continuous values, infinite scrolling | Continuous (0.0, 0.1, ...) | Infinite or finite |
| **SteppingWheel** | Discrete steps, frame stepping | Discrete (0, 1, 2, ...) | Finite only |

### Core Components

**SlidingRuler.swift** - Main view containing all state management and gesture handling. Uses a state machine (`SlidingRulerState`) to manage interaction phases: idle, dragging, flicking, springing, animating.

**Mechanic.swift** - Physics simulation for scroll behavior:
- `Mechanic.Inertia` - Deceleration calculations matching UIScrollView behavior
- `Mechanic.Spring` - Critically damped spring for rubber band release

**VSynchedTimer.swift** - CADisplayLink wrapper for frame-synchronized animations during flick and spring states.

**SteppingWheel.swift** - Discrete stepping control for frame-accurate selection. Key differences from SlidingRuler:
- Values snap to discrete steps (no fractions)
- Finite range required
- Haptic feedback on each step crossing
- Simpler state machine: idle, dragging, decelerating
- Inertia lands on discrete steps

### Styling System

Located in `Sources/SlidingRuler/Styling/`:

- **SlidingRulerStyle protocol** - Defines custom appearance via `makeCellBody()` and `makeCursorBody()`
- **FractionableView protocol** - Cell views must specify `fractions` (subdivisions per unit)
- Built-in styles: `PrimarySlidingRulerStyle`, `CenteredSlidingRulerStyle`, `BlankSlidingRulerStyle`, `BlankCenteredSlidingRulerStyle`

Styles are propagated via SwiftUI environment using `slidingRulerStyle` key.

### Rendering Pipeline

1. `FlexibleWidthContainer` measures available width via preference key
2. `Ruler` creates cells based on visible width + overflow
3. `InfiniteOffsetEffect` applies translation (wraps at `cellWidthOverflow`)
4. `InfiniteMarkOffsetModifier` updates visible graduation marks without recreating cells

### Gesture Flow

`HorizontalPanGesture.swift` wraps UIKit gesture recognizer for velocity tracking. States flow:
- Touch → `.dragging` with rubber band at bounds
- Release with velocity → `.flicking` (inertia simulation)
- Hit bound during flick → `.springing` (bounce back)
- Settle → snap to nearest mark if configured

### Dependencies

- **SmoothOperators** - Operator overloads for cleaner math (`??` for CGFloat nil-coalescing)
- **CoreGeometry** - CGSize/CGPoint utilities

## Documentation

- [Project Spec](project_spec.md) - Full requirements, API specs, tech details
- [Architecture](docs/architecture.md) - System design and data flow
- [Changelog](docs/changelog.md) - Version history
- [Project Status](docs/project_status.md) - Current progress

Update files in the docs folder after major milestones and major additions to the project.

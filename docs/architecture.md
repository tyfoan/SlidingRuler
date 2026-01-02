# Architecture

> System design and data flow for SlidingRuler

## System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftUI View Layer                      │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    SlidingRuler<V>                       ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ ││
│  │  │   Cursor    │  │ Ruler Cells │  │ Boundary Marks  │ ││
│  │  └─────────────┘  └─────────────┘  └─────────────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Style Protocol                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │               SlidingRulerStyle                          ││
│  │  • cursorAlignment    • fractions                       ││
│  │  • makeCursorBody()   • makeCellBody()                  ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Gesture Handling                          │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐ │
│  │ DragGesture   │  │   Inertia     │  │  Rubber Band    │ │
│  │   Handler     │  │  Animation    │  │    Effect       │ │
│  └───────────────┘  └───────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Feedback Layer                            │
│  ┌───────────────────────┐  ┌─────────────────────────────┐ │
│  │   Haptic Feedback     │  │    Snap Behavior            │ │
│  │   (UIFeedbackGen)     │  │    (Mark enum)              │ │
│  └───────────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. SlidingRuler View
**Purpose**: Main SwiftUI view that renders the ruler and handles user interaction
**Key Files**: `Sources/SlidingRuler/SlidingRuler.swift`

### 2. Ruler Cell
**Purpose**: Individual cell rendering graduation marks and numbers
**Key Files**: `Sources/SlidingRuler/RulerCell.swift` (estimated)

### 3. Cursor
**Purpose**: Visual indicator pointing to current value
**Key Files**: `Sources/SlidingRuler/Cursor.swift` (estimated)

### 4. Style System
**Purpose**: Protocol-based customization of ruler appearance
**Key Files**: `Sources/SlidingRuler/SlidingRulerStyle.swift`

### 5. Built-in Styles
- `PrimarySlidingRulerStyle` (default)
- `CenteredSlidingRulerStyle`
- `BlankSlidingRulerStyle`
- `BlankCenteredSlidingRulerStyle`

## Data Flow

```
User Gesture
     │
     ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Drag      │────▶│   Value     │────▶│   View      │
│   Handler   │     │   Update    │     │   Redraw    │
└─────────────┘     └─────────────┘     └─────────────┘
     │                    │
     ▼                    ▼
┌─────────────┐     ┌─────────────┐
│   Haptic    │     │   Snap      │
│   Feedback  │     │   Logic     │
└─────────────┘     └─────────────┘
```

### Value Binding Flow
1. User initiates drag gesture
2. Gesture handler calculates new value based on drag translation
3. Value is clamped to bounds (if finite)
4. Rubber band effect applied if dragging beyond bounds
5. `onEditingChanged(true)` called on drag start
6. Value binding updated
7. View redraws with new ruler position
8. On drag end: inertia animation applied
9. Snap logic applied if configured
10. `onEditingChanged(false)` called when settled

### Styling Flow
1. Style set via `.slidingRulerStyle(_:)` modifier
2. Style stored in SwiftUI environment
3. SlidingRuler reads style from environment
4. Style's `makeCursorBody()` and `makeCellBody()` called during render

## Dependencies

| Package | Purpose |
|---------|---------|
| SmoothOperators | Utility operators for cleaner math expressions |
| CoreGeometry | Geometry helpers for layout calculations |

## Related Documents
- [Project Spec](../project_spec.md)
- [Changelog](./changelog.md)
- [Project Status](./project_status.md)

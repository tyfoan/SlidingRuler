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
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    SteppingWheel<V>                      ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ ││
│  │  │   Canvas    │  │  Indicator  │  │   Edge Fades    │ ││
│  │  │   Ticks     │  │   (Center)  │  │   (Optional)    │ ││
│  │  └─────────────┘  └─────────────┘  └─────────────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Style System                             │
│  ┌──────────────────────┐  ┌──────────────────────────────┐│
│  │  SlidingRulerStyle   │  │     SteppingWheelStyle       ││
│  │  (Protocol-based)    │  │     (Struct-based)           ││
│  │  • makeCursorBody()  │  │  • tickColor, tickSpacing    ││
│  │  • makeCellBody()    │  │  • centerIndicatorStyle      ││
│  │                      │  │  • edgeFade, background      ││
│  └──────────────────────┘  └──────────────────────────────┘│
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

### 5. Built-in SlidingRuler Styles
- `PrimarySlidingRulerStyle` (default)
- `CenteredSlidingRulerStyle`
- `BlankSlidingRulerStyle`
- `BlankCenteredSlidingRulerStyle`

### 6. SteppingWheel View
**Purpose**: Discrete step wheel control optimized for frame-by-frame navigation
**Key Files**: `Sources/SlidingRuler/SteppingWheel.swift`

Key features:
- Canvas-based rendering for performance (50,000+ steps)
- Only renders visible ticks (O(visible) complexity)
- State machine: idle → dragging → decelerating
- Inertia physics with friction-based deceleration
- Rubber-band effect at boundaries
- VSynchedTimer for frame-synced animations

### 7. SteppingWheelStyle
**Purpose**: Struct-based comprehensive visual customization
**Key Files**: `Sources/SlidingRuler/SteppingWheel.swift`

Configurable properties:
- **Tick appearance**: color, width, height, spacing, fade effects
- **Center indicator**: style (line, lineWithGlow, box, triangle, none), color, size
- **Background**: color, edge fade overlay
- **Layout**: tick spacing, overall height

Built-in presets:
- `.default` - Standard appearance
- `.minimal` - Reduced visual elements
- `.compact` - Smaller footprint
- `.pro(accent:)` - Premium look with glow effects

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

### SteppingWheel Data Flow

```
User Gesture
     │
     ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Drag      │────▶│   State     │────▶│   Canvas    │
│   Handler   │     │   Update    │     │   Redraw    │
└─────────────┘     └─────────────┘     └─────────────┘
     │                    │
     ▼                    ▼
┌─────────────┐     ┌─────────────┐
│   Haptic    │     │   Value     │
│   Feedback  │     │   Binding   │
└─────────────┘     └─────────────┘
```

### SteppingWheel State Machine

```
                    ┌──────────────┐
                    │     idle     │◀─────────────────┐
                    └──────┬───────┘                  │
                           │ drag started            │ settled
                           ▼                         │
                    ┌──────────────┐                  │
                    │   dragging   │                  │
                    └──────┬───────┘                  │
                           │ drag ended              │
              ┌────────────┴────────────┐            │
              │                         │            │
        (slow release)           (fast release)      │
              │                         │            │
              ▼                         ▼            │
       ┌──────────────┐         ┌──────────────┐     │
       │  snap idle   │         │ decelerating │─────┤
       └──────────────┘         └──────────────┘     │
              │                         │            │
              └────────────────────────────────────▶┘
```

### Canvas Rendering Optimization
1. Calculate visible tick range from viewport width
2. Determine center tick index from current offset
3. Compute start/end tick indices (visible range + buffer)
4. Draw only visible ticks using Path and context.fill()
5. Apply distance-based opacity fade for depth effect

## Dependencies

| Package | Purpose |
|---------|---------|
| SmoothOperators | Utility operators for cleaner math expressions |
| CoreGeometry | Geometry helpers for layout calculations |

## Related Documents
- [Project Spec](../project_spec.md)
- [Changelog](./changelog.md)
- [Project Status](./project_status.md)

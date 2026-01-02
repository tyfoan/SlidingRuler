# Project Spec: SlidingRuler

> **Definition**: What you want to build and how you want to build it.
>
> This document combines Product Requirements (PRD) and Engineering Design (EDD) into a single source of truth.

---

## Part 1: Product Requirements

### 1.1 Overview

**Project Name**: SlidingRuler

**One-liner**: A SwiftUI control that provides a sliding ruler interface for precise numeric value input.

**Problem Statement**: Standard sliders in iOS/iPadOS lack precision for certain use cases. Users need a more intuitive way to input numeric values, especially for measurements, percentages, or values in large/unlimited ranges. A sliding ruler metaphor provides better visual feedback and precision than traditional sliders.

---

### 1.2 Target Users

**Primary Users**: iOS/iPadOS developers building SwiftUI applications that require precise numeric input controls.

**User Personas**:
| Persona | Description | Pain Points |
|---------|-------------|-------------|
| SwiftUI Developer | Building measurement or data entry apps | Standard Slider lacks precision, no visual graduation marks |
| Form Designer | Creating complex input forms | Need consistent, precise numeric inputs across multiple fields |

---

### 1.3 Goals & Success Metrics

**Project Goals**:
1. Provide a native-feeling SwiftUI control that integrates seamlessly with iOS/iPadOS
2. Enable precise numeric value selection with visual feedback
3. Support both finite and infinite ranges with appropriate UX patterns

**Success Metrics**:
| Metric | Target | How to Measure |
|--------|--------|----------------|
| Swift Package adoption | Growing usage | GitHub stars, package downloads |
| API completeness | Full SwiftUI integration | Support for all standard View modifiers |

---

### 1.4 Functional Requirements

#### Core Features

**Feature 1: Basic Sliding Ruler**
- [x] Swipe/drag gesture to change value
- [x] Visual ruler with graduation marks
- [x] Cursor indicator pointing to current value
- [x] Support for `BinaryFloatingPoint` value types

**Feature 2: Range & Bounds**
- [x] Support infinite ranges (default)
- [x] Support finite ranges with visual boundary indicators
- [x] Rubber band effect at boundaries
- [x] Haptic feedback at boundaries

**Feature 3: Precision Controls**
- [x] Configurable step value
- [x] Snap-to-graduation options (none, unit, half, fraction)
- [x] Tick/haptic feedback options

**Feature 4: Customization**
- [x] Custom styling via `SlidingRulerStyle` protocol
- [x] Number formatter support
- [x] Light & dark mode support
- [x] Dynamic type support

**Feature 5: Interactions**
- [x] Scroll inertia
- [x] Pointer interactions (iPad)
- [ ] Accessibility support
- [ ] Layout direction (RTL) support

---

### 1.5 User Flows

**Flow 1: Basic Value Input**
```
User drags ruler → Value updates in real-time → User releases → Value settles (with optional snap)
```

**Flow 2: Boundary Interaction**
```
User drags to boundary → Haptic feedback → Rubber band effect → User releases → Ruler bounces back
```

---

### 1.6 Non-Functional Requirements

- **Performance**: Smooth 60fps scrolling with inertia
- **Platform**: iOS 13.1+, iPadOS 13.1+
- **Compatibility**: Swift 5.2+, SwiftUI

---

### 1.7 Out of Scope

- macOS support (currently)
- watchOS/tvOS support
- Vertical orientation

---

## Part 2: Engineering Design

### 2.1 Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Framework | SwiftUI | Native iOS UI framework |
| Language | Swift 5.2+ | Required for SwiftUI |
| Dependencies | SmoothOperators, CoreGeometry | Utility operators and geometry helpers |
| Distribution | Swift Package Manager | Standard Swift distribution |

---

### 2.2 System Architecture

```
See docs/architecture.md for details
```

---

### 2.3 Data Models

**SlidingRuler View**
```swift
struct SlidingRuler<V: BinaryFloatingPoint>: View {
    value: Binding<V>
    bounds: ClosedRange<V>
    step: V.Stride
    snap: Mark
    tick: Mark
    formatter: NumberFormatter?
}
```

**Mark Enum**
```swift
enum Mark {
    case none
    case unit
    case half
    case fraction
}
```

---

### 2.4 API Design

| Type | Name | Description |
|------|------|-------------|
| View | `SlidingRuler` | Main control |
| Protocol | `SlidingRulerStyle` | Custom styling |
| View Modifier | `slidingRulerStyle(_:)` | Apply style |
| View Modifier | `slidingRulerCellOverflow(_:)` | Cell overflow config |

---

### 2.5 Security Considerations

- No network access required
- No data persistence
- No sensitive data handling

---

## Part 3: Milestones

### Milestone 1: MVP (v0.1.0) - Complete
**Goal**: Basic functional sliding ruler

**Deliverables**:
- [x] Basic sliding interaction
- [x] Graduation marks
- [x] Value binding

---

### Milestone 2: Polish (v0.2.0) - Current
**Goal**: Production-ready features

**Deliverables**:
- [x] Haptic feedback
- [x] Custom styling
- [x] Inertia & rubber banding
- [ ] Accessibility support
- [ ] RTL layout support

---

### Milestone 3: v1.0.0 - Planned
**Goal**: Stable release

**Deliverables**:
- [ ] Complete accessibility support
- [ ] RTL layout direction
- [ ] Comprehensive documentation

---

## Part 4: Risks & Open Questions

| Risk | Impact | Mitigation |
|------|--------|------------|
| SwiftUI API changes | Medium | Pin minimum iOS version, test on betas |
| Performance on older devices | Low | Profile and optimize render loop |

**Open Questions**:
- [ ] How should custom styles adapt to accessibility settings?
- [ ] Should vertical orientation be supported?

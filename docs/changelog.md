# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- **SteppingWheel**: New discrete step wheel control for frame-by-frame navigation
  - Canvas-based rendering optimized for 50,000+ steps (long video support)
  - Only renders visible ticks for O(visible) performance instead of O(total)
  - Inertia physics with friction-based deceleration
  - Rubber-band effect at boundaries
  - Haptic feedback on step changes
- **SteppingWheelStyle**: Comprehensive visual customization system
  - Tick appearance (color, size, spacing, fade effects)
  - Center indicator styles (line, lineWithGlow, box, triangle, none)
  - Background and edge fade configuration
  - Built-in presets: `.default`, `.minimal`, `.compact`, `.pro(accent:)`
- **SteppingWheelConfig**: Legacy configuration for backward compatibility
- Project documentation structure

### Fixed
- Visual jump when releasing slow drag on SteppingWheel (using Transaction to disable implicit animations)

---

## [0.2.0] - BETA

### Added
- Dynamic type support
- Haptic feedback on compatible devices
- Light & dark color scheme support
- Scroll inertia & rubber banding
- Custom styling via `SlidingRulerStyle` protocol
- Animation support
- Pointer interactions for iPad
- Four built-in styles:
  - `PrimarySlidingRulerStyle` (default)
  - `CenteredSlidingRulerStyle`
  - `BlankSlidingRulerStyle`
  - `BlankCenteredSlidingRulerStyle`

### Fixed
- Environment value access outside of View installation

---

## [0.1.0] - Initial Release

### Added
- Basic `SlidingRuler` SwiftUI view
- Value binding with `BinaryFloatingPoint` support
- Configurable bounds (finite and infinite ranges)
- Configurable step size
- Snap behavior options (none, unit, half, fraction)
- Tick/haptic feedback options
- `onEditingChanged` callback
- Number formatter support
- `slidingRulerStyle(_:)` view modifier
- `slidingRulerCellOverflow(_:)` view modifier

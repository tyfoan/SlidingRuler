# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- Project documentation structure

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

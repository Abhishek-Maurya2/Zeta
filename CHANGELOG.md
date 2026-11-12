# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.1] - 2026-11-12

### Fixed
- **Android Gradle Build Compatibility**: Upgraded Android Gradle Plugin to `9.1.1` and Gradle wrapper to `9.5.0` to meet Flutter's minimum build requirements and resolve CI build failures.

### Changed
- **GlassMenu Refinements**: Refactored glass menu components with zero elevation and shadows, instant frame-0 backdrop blur scaling, and non-blocking outside tap pass-through interaction via `TapRegion`.
- **Submenu Hierarchy & Key Handling**: Fixed submenu re-tapping to collapse, automatic dismissal of previous submenus on switch, and scoped `Escape` key handling to prevent scaffold page pop.
- **Tasks Sort Split Button**: Organized sorting actions into dedicated submenus for Alphabetical and Creation Date ordering with active badges and high-contrast selection styling.

## [1.7.0] - 2026-11-12

### Added
- **AppBar Profile Menu Expressive Transform**: Implemented an expressive container transform for the profile avatar menu popup using `OverlayPortal`, `CompositedTransformFollower`, `AnimatedContainer`, `AnimatedSize`, and `GlassSurface`.
- **Mindmap Node Sizing & Soft Wrap**: Enforced a `maxNodeWidth` of 250px for mindmap nodes with clean text wrapping and robust layout calculations.

### Changed
- **Space Node Modularization**: Decomposed `MindMapNodeWidget` into dedicated subcomponents (`mindmap_node_card.dart`, `mindmap_node_editor.dart`, `mindmap_node_dnd.dart`, and `mindmap_node_metrics.dart`).
- **Design System Harmonization**: Standardized `material_ui` widgets, theme-aware color schemes, and dark mode styling across mindmap node components.
- **Tasks Filter Bar**: Refined filter bar layout, styling, and responsiveness.
- **GlassMenu**: Improved glass container styling, blur effects, and animations.

## [1.6.10] - 2026-11-11

### Changed
- Refined MindMapLayoutEngine overhead measurements and sizing formulas.
- Improved MindMapNodeWidget layout and collapse badge interactions.
- Added comprehensive unit tests for mindmap layout engine and node widget.

## [1.6.9] - 2026-11-10

### Added
- Keyboard navigation and in-place editing for mind map nodes.

## [1.6.8] - 2026-11-09

### Added
- Interactive mindmap canvas, spatial controls, and floating toolbar for Space page.
- Hover flyout functionality for tasks workload capsule with M3EList display.

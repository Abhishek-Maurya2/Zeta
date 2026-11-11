# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

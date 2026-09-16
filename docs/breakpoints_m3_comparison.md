# Material Design 3 (M3) vs. Zeta Breakpoints & Responsive Layout Specification

> **Document Version:** 1.0.0  
> **Status:** Comparative Analysis & Architectural Recommendation  
> **Scope:** Layout Breakpoints, Window Size Classes, Margin/Gutter Tokens, Pane Layouts, Navigation Adaptation, and Zeta Implementation Audit

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Material Design 3 Layout Foundation & Specifications](#2-material-design-3-layout-foundation--specifications)
   - [2.1 Window Size Classes Overview](#21-window-size-classes-overview)
   - [2.2 Compact Breakpoint (< 600dp)](#22-compact-breakpoint--600dp)
   - [2.3 Medium Breakpoint (600dp – 839dp)](#23-medium-breakpoint-600dp--839dp)
   - [2.4 Expanded Breakpoint (840dp – 1199dp)](#24-expanded-breakpoint-840dp--1199dp)
   - [2.5 Large Breakpoint (1200dp – 1599dp)](#25-large-breakpoint-1200dp--1599dp)
   - [2.6 Extra-Large Breakpoint (1600dp+)](#26-extra-large-breakpoint-1600dp)
   - [2.7 The 5 M3 Adaptation Strategies](#27-the-5-m3-adaptation-strategies)
   - [2.8 M3 Canonical Layout Types](#28-m3-canonical-layout-types)
   - [2.9 Spacing, Margins, Gutters, and Ergonomics](#29-spacing-margins-gutters-and-ergonomics)
3. [Zeta's Current Breakpoint Architecture Audit](#3-zetas-current-breakpoint-architecture-audit)
   - [3.1 Global Navigation & App Scaffold (`app_scaffold.dart`)](#31-global-navigation--app-scaffold-app_scaffolddart)
   - [3.2 Top App Bar (`top_app_bar.dart`)](#32-top-app-bar-top_app_bardart)
   - [3.3 Home Dashboard (`home_page.dart`)](#33-home-dashboard-home_pagedart)
   - [3.4 Tasks Management (`tasks_page.dart`)](#34-tasks-management-tasks_pagedart)
   - [3.5 Settings Screen (`settings_page.dart`)](#35-settings-screen-settings_pagedart)
   - [3.6 Pomodoro Timer & Analytics (`pomodoro_page.dart` & `pomodoro_timer_pane.dart`)](#36-pomodoro-timer--analytics-pomodoro_pagedart--pomodoro_timer_panedart)
   - [3.7 Bin & Revision Pages (`bin_page.dart`, `bin_header.dart`, `revision_page.dart`)](#37-bin--revision-pages-bin_pagedart-bin_headerdart-revision_pagedart)
   - [3.8 Modals, Dialogs, and Sheets (`task_edit_pane.dart`)](#38-modals-dialogs-and-sheets-task_edit_panedart)
4. [Granular Side-by-Side Comparison Matrix](#4-granular-side-by-side-comparison-matrix)
5. [In-Depth Gap Analysis & Discrepancies](#5-in-depth-gap-analysis--discrepancies)
   - [Discrepancy 1: Threshold Fragmentation (600, 640, 840, 960, 1200)](#discrepancy-1-threshold-fragmentation-600-640-840-960-1200)
   - [Discrepancy 2: Margins & Gutters Drifting (16 / 24 / 36 / 40dp)](#discrepancy-2-margins--gutters-drifting-16--24--36--40dp)
   - [Discrepancy 3: Fixed vs. Split Two-Pane Behavior in Medium Screens](#discrepancy-3-fixed-vs-split-two-pane-behavior-in-medium-screens)
   - [Discrepancy 4: Absence of a Centralized Breakpoint Token System](#discrepancy-4-absence-of-a-centralized-breakpoint-token-system)
   - [Discrepancy 5: Large (1200dp) and Extra-Large (1600dp+) Neglect](#discrepancy-5-large-1200dp-and-extra-large-1600dp-neglect)
6. [Recommendations & Implementation Roadmap for Zeta](#6-recommendations--implementation-roadmap-for-zeta)
   - [Phase 1: Establish `ZetaBreakpoints` & `ZetaWindowSizeClass`](#phase-1-establish-zetabreakpoints--zetawindowsizeclass)
   - [Phase 2: Standardize Page Margins & Gutters to M3 Tokens](#phase-2-standardize-page-margins--gutters-to-m3-tokens)
   - [Phase 3: Align Canonical Pane Thresholds](#phase-3-align-canonical-pane-thresholds)
   - [Phase 4: Responsive Sheet/Dialog & Extra-Large Desktop Handling](#phase-4-responsive-sheetdialog--extra-large-desktop-handling)
7. [Material Design 3 Scaffold System (Navigation Suite Scaffold)](#7-material-design-3-scaffold-system-navigation-suite-scaffold)
   - [7.1 Structural Anatomy & Slot Layout (Nav, Bar, Rail, Drawer, Side Sheet)](#71-structural-anatomy--slot-layout)
   - [7.2 Inset Consumption & Edge-to-Edge System Bars](#72-inset-consumption--edge-to-edge-system-bars)
   - [7.3 Floating Action Button (FAB) Placement Across Size Classes](#73-floating-action-button-fab-placement-across-size-classes)
   - [7.4 Bottom Navigation Toolbar vs. Standard M3 Navigation Bar](#74-bottom-navigation-toolbar-vs-standard-m3-navigation-bar)
8. [Material Design 3 Panes Architecture (Canonical Layouts)](#8-material-design-3-panes-architecture-canonical-layouts)
   - [8.1 List-Detail Layout: Dual-Pane Contract & Back-Stack State Machine](#81-list-detail-layout-dual-pane-contract--back-stack-state-machine)
   - [8.2 Supporting Pane Layout: Contextual Sidebar vs. Modal Bottom Sheet](#82-supporting-pane-layout-contextual-sidebar-vs-modal-bottom-sheet)
   - [8.3 Feed Layout: Multi-Column Responsive Grid Architecture](#83-feed-layout-multi-column-responsive-grid-architecture)
   - [8.4 Pane Dividers, Touch-Target Drag Handles & Collapsed Affordances](#84-pane-dividers-touch-target-drag-handles--collapsed-affordances)
9. [Surface Color Roles & Tonal Elevation in Multi-Pane Views](#9-surface-color-roles--tonal-elevation-in-multi-pane-views)
10. [Adaptive Motion, State Preservation & Window Resize Engine](#10-adaptive-motion-state-preservation--window-resize-engine)

---

## 1. Executive Summary

Material Design 3 (M3) defines a **device-agnostic layout grid and window size class system** built around five core breakpoints: **Compact**, **Medium**, **Expanded**, **Large**, and **Extra-Large**. Instead of optimizing for specific device hardware, M3 adapts dynamically to continuous window dimensions across foldables, portrait/landscape tablets, split-screen desktop windows, and ultra-wide displays.

The Zeta codebase already adopts several progressive Material 3 patterns—such as the **Material 3 Expressive (`material_3_expressive`) Navigation Rail and Bottom Floating Navigation Toolbar**, **Draggable Pane Dividers (`M3PaneDivider`)**, and **Responsive Dialogs/Bottom Sheets (`M3EBottomSheet`)**.

However, a thorough audit reveals significant architectural divergences:
1. **Ad-Hoc Thresholds**: Zeta scatters breakpoint numbers (`600`, `640`, `840`, `960`, `1200`) across ten separate files rather than consuming a unified design token system.
2. **Margin Discrepancies**: While M3 standardizes on `16dp` (Compact) and `24dp` (Medium+), Zeta applies variable outer paddings of `16dp`, `24dp`, `36dp`, and `40dp`.
3. **Pane Activation Inconsistency**: Settings switches to two-pane at `640dp`, Pomodoro switches at `840dp`, and Home switches to dual columns at `960dp`.
4. **Desktop / Ultra-Wide Handling**: Zeta caps page widths at `860dp` or `1120dp`, but does not implement M3's Extra-Large (`1600dp+`) 3-pane side-sheet canonical architecture or large fixed-pane expansion (`412dp`).

This document compiles the complete M3 specification, audits Zeta's implementation line-by-line, contrasts them side-by-side, and provides an actionable blueprint to align Zeta with M3 standards.

---

## 2. Material Design 3 Layout Foundation & Specifications

### 2.1 Window Size Classes Overview

Material Design 3 categorizes available screen width into **Window Size Classes**. Each size class represents a range of display widths in density-independent pixels (`dp`), dictating how content reflows, how many panes can be displayed concurrently, and what navigation paradigm should be used.

| Window Size Class | Width Range (dp) | Margins | Spacer (Gutter) | Pane Count | Recommended Navigation | Primary Form Factors |
|---|---|---|---|---|---|---|
| **Compact** | `< 600dp` | `16dp` | Standard | **1 Pane** | **Navigation Bar** (Bottom) or Modal Rail | Phone (portrait), small foldables |
| **Medium** | `600dp – 839dp` | `24dp` | `24dp` | **1 Pane** (rec) or **2 Panes** (50/50 low density) | **Navigation Rail** (1-pane) or **Navigation Bar** (2-pane) | Small tablets (portrait), large foldables (unfolded) |
| **Expanded** | `840dp – 1199dp` | `24dp` | `24dp` | **1 Pane** (dense) or **2 Panes** (rec; fixed 360dp) | **Navigation Rail** (collapsed 80dp or expanded 220–256dp) | Tablets (landscape), foldables (landscape), small laptops |
| **Large** | `1200dp – 1599dp` | `24dp` | `24dp` | **1 Pane** or **2 Panes** (rec; fixed 412dp) | **Navigation Rail** (expanded or collapsed) | Laptops, desktop monitors |
| **Extra-Large** | `1600dp+` | `24dp` | `24dp` | **1 to 3 Panes** (3rd pane max 400dp side sheet) | **Navigation Rail** (standard expanded) | Large monitors, ultra-wide screens |

---

### 2.2 Compact Breakpoint (`< 600dp`)

* **Width Threshold**: Strictly `< 600dp`.
* **Margins**: `16dp` outer margin on leading and trailing window edges.
* **Layout Hierarchy**:
  * Single-pane primary focus. All multi-pane layouts collapse into stacked or paginated single panes.
  * Hierarchical drilling: Moving from a list to a detail item pushes a new screen onto the navigation stack or uses horizontal shared-axis page transitions.
* **Navigation Components**:
  * Primary: **Navigation Bar** (Bottom Navigation Bar) placed along the bottom edge within the thumb zone.
  * Secondary: **Modal Navigation Drawer** or **Modal Navigation Rail** triggered from a Top App Bar menu icon.
* **Overlays & Dialogs**:
  * Input flows and auxiliary selection utilize **Modal Bottom Sheets** (expanding upwards from the bottom edge).
  * High-complexity tasks utilize **Full-Screen Dialogs** rather than floating modal alert boxes.
* **Ergonomics**: Content is optimized for single-hand or thumb interaction; actionable touch targets must be at least $48 \times 48\text{dp}$.

---

### 2.3 Medium Breakpoint (`600dp – 839dp`)

* **Width Threshold**: `600dp` to `839dp` inclusive.
* **Margins & Spacers**: `24dp` outer margins; `24dp` interior spacer/gutter between adjacent panels.
* **Pane Paradigms**:
  * **Single-Pane (Recommended for High Density)**: For content-heavy or dense experiences (task lists, message feeds, media grids), M3 strongly recommends remaining on a single-pane layout to avoid cramped columns.
  * **Two-Pane (Low Density Split Layout)**: Two panes are permitted *only* for low-density views such as Settings or simple forms. When two panes are used at this width, M3 prescribes a **50% / 50% split** with a centered spacer. Fixed-width panes (e.g. 360dp) are *discouraged* at `< 840dp` because they leave the flexible secondary pane with fewer than 300dp of usable width.
* **Navigation Patterns**:
  * **Single-pane configurations**: Use a **Navigation Rail** on the leading edge (collapsed 80dp wide), keeping thumb access along the left/right edge.
  * **Two-pane configurations**: M3 recommends retaining the **Navigation Bar** along the bottom edge so both panes have maximum horizontal breathing room without being constricted by a lateral rail.
* **Ergonomic Zones on Medium Form Factors**:
  * **Inconvenient Zone (Top 25%)**: Hard to reach during two-handed tablet grips. Critical buttons, FABs, and action bars must avoid this top quadrant.
  * **Comfortable Zone (Middle 50%)**: Optimal target for main content consumption and frequent tap targets.
  * **Challenging Zone (Extreme Bottom Edge)**: Often obstructed by device palms or software gesture bars.

---

### 2.4 Expanded Breakpoint (`840dp – 1199dp`)

* **Width Threshold**: `840dp` to `1199dp` inclusive.
* **Margins & Spacers**: `24dp` outer margins; `24dp` interior spacer between panes.
* **Pane Structure**:
  * **Two-Pane Layouts (Recommended Standard)**:
    * **Fixed-and-Flexible (Supporting Pane / List-Detail)**: The primary navigation or detail pane is locked at **360dp width**, while the remaining viewport dynamically flexes.
    * **Split-Pane Layout**: Two equally proportioned flexible panes (50% / 50%) with a centered 24dp divider.
  * **Single-Pane (Dense Media)**: Preserved only for wide canvas experiences such as video playback or code editors.
* **Navigation Patterns**:
  * **Navigation Rail**: Positioned on the leading edge.
  * Can be permanently collapsed (`80dp`) or dynamically expanded (`220dp – 256dp`) showing icon + text label side-by-side.
  * Sub-filtering within panes moves to internal segmented buttons, chips, or tabs embedded directly inside the pane header.

---

### 2.5 Large Breakpoint (`1200dp – 1599dp`)

* **Width Threshold**: `1200dp` to `1599dp` inclusive.
* **Margins & Spacers**: `24dp` outer margins; `24dp` interior spacer.
* **Pane Structure**:
  * Two-pane canonical layout remains the sweet spot.
  * **Fixed Pane Scale-Up**: The fixed pane widens from **360dp** (on Expanded) to **412dp** on Large screens to maintain visual balance with expansive high-resolution displays.
* **Navigation Patterns**:
  * **Expanded Navigation Rail** or **Permanent Navigation Drawer** default.
  * May collapse back to compact rail icon mode when user dives deep into hierarchical workflows.

---

### 2.6 Extra-Large Breakpoint (`1600dp+`)

* **Width Threshold**: $\ge 1600\text{dp}$.
* **Margins & Spacers**: `24dp` standard minimum outer margins, or variable margins that center content within a defined maximum container width.
* **Pane Structure**:
  * **1 to 3 Panes Simultaneously**:
    * Pane 1: Primary navigation / list view.
    * Pane 2: Primary content / canvas view.
    * Pane 3: **Standard Side Sheet** or contextual inspector pane (maximum allowed width: **400dp**).
  * **Hard Limit**: M3 states applications should **never exceed 3 simultaneous content panes**, as visual tracking degrades.
* **Navigation Patterns**:
  * Standard Expanded Navigation Rail on leading edge.

---

### 2.7 The 5 M3 Adaptation Strategies

When window dimensions change dynamically, M3 requires interfaces to adapt using five core strategies:

```
┌──────────────┬────────────────────────────────────────────────────────────────────────┐
│ Strategy     │ Behavioral Description & Concrete Examples                             │
├──────────────┼────────────────────────────────────────────────────────────────────────┤
│ 1. REVEAL    │ Unhide navigation labels, secondary panes, or tooltips as width grows. │
│              │ • Expanding collapsed 80dp rail to 240dp with full text labels.        │
│              │ • Unhiding a contextual supporting pane on desktop.                    │
├──────────────┼────────────────────────────────────────────────────────────────────────┤
│ 2. DIVIDE    │ Split a unified single pane into 2 panes (Expanded) or 3 panes (XL).   │
│              │ • Transitioning Settings from full-page navigation to dual-pane.       │
│              │ • Transitioning Pomodoro timer into Timer + Analysis panes.            │
├──────────────┼────────────────────────────────────────────────────────────────────────┤
│ 3. RESIZE    │ Fluidly scale elements or step up fixed pane dimensions.               │
│              │ • Fixed pane scales: 360dp on Expanded -> 412dp on Large/XL.           │
│              │ • Grid columns grow fluidly within constraint bounds.                  │
├──────────────┼────────────────────────────────────────────────────────────────────────┤
│ 4. REPOSITION│ Relocate UI elements to preserve ergonomic accessibility.               │
│              │ • Move actions from floating bottom bar to top app bar or rail header. │
│              │ • Reflow vertical list cards into a multi-column masonry/feed grid.    │
├──────────────┼────────────────────────────────────────────────────────────────────────┤
│ 5. SWAP      │ Replace an entire component with an ergonomically equivalent one.       │
│              │ • Navigation Bar (Compact) <-> Navigation Rail (Medium/Expanded).       │
│              │ • Modal Bottom Sheet (Compact) <-> Center Dialog / Side Sheet (Medium+)│
│              │ • Full-screen Dialog (Compact) <-> Modal Surface Dialog (Expanded).    │
└──────────────┴────────────────────────────────────────────────────────────────────────┘
```

---

### 2.8 M3 Canonical Layout Types

Material Design 3 establishes three canonical architectures that solve 95% of responsive layout challenges:

1. **Supporting Pane**:
   * *Purpose*: Main focus content (~60–70% width) accompanied by a secondary panel (~30–40% width) providing context, telemetry, or auxiliary tools.
   * *Typical Usage*: Document editors with comment sidebars; Pomodoro timer with session statistics.
2. **List-Detail**:
   * *Purpose*: Left pane displays an explorable list of items; right pane displays the details of the active selection.
   * *Typical Usage*: Email clients, messaging apps, and Settings hierarchies.
3. **Feed**:
   * *Purpose*: Fluid, homogeneous card grid designed for visual browsing.
   * *Typical Usage*: Dashboard overview, photo galleries, task cards in kanban or masonry flow.

---

### 2.9 Spacing, Margins, Gutters, and Ergonomics

* **Grid Columns**:
  * Compact (`< 600dp`): **4 Columns**
  * Medium (`600 – 839dp`): **8 Columns**
  * Expanded & Above (`840dp+`): **12 Columns**
* **Outer Margins**:
  * Compact: **16dp**
  * Medium+: **24dp**
* **Interior Pane Gutters**: **24dp** between major panes.
* **Component Spacing**: **8dp** or **16dp** token increments along a standard 4/8dp baseline grid.

---

## 3. Zeta's Current Breakpoint Architecture Audit

A comprehensive codebase audit reveals that Zeta implements responsive behavior across eight distinct modules. Below is the detailed breakdown of every breakpoint check, threshold, and layout branch currently active in Zeta.

### 3.1 Global Navigation & App Scaffold (`lib/navigation/app_scaffold.dart`)

```dart
// app_scaffold.dart: Lines 171-182
final width = MediaQuery.sizeOf(context).width;
final isCompact = width < 600;
final isExpanded = width >= 840;

// Top app bar visibility logic
final showTopAppBar = isExpanded || navProvider.activePage != PageId.settings;
```

* **Threshold `< 600dp` (Compact Mode)**:
  * Renders a `Stack` containing the full-bleed active `_BodyPane`.
  * Renders a floating `_FloatingBottomNav` docked at `bottom: 16dp` with animated slide transitions.
  * Hides the navigation rail toggle button in the top bar.
* **Threshold $\ge 600\text{dp}$ (Desktop / Tablet Mode)**:
  * Renders a horizontal `Row` containing `_NavigationRailWidget` and an `Expanded` body pane.
  * Rail supports `M3ENavigationRailType.alwaysExpand` and `M3ENavigationRailType.alwaysCollapse` driven by `NavigationProvider.isRailExpanded`.
* **Threshold $\ge 840\text{dp}$ (`isExpanded`)**:
  * Used to force the Top App Bar to remain visible even when viewing Settings (on `< 840dp`, Settings suppresses the global top bar in favor of its own `SliverAppBar.large`).

---

### 3.2 Top App Bar (`lib/navigation/top_app_bar.dart`)

```dart
// top_app_bar.dart: Lines 68-73
final width = MediaQuery.sizeOf(context).width;
final isCompact = width < 600;
final showBrandText = width >= 640;

// top_app_bar.dart: Line 90
height: isCompact ? 56 : 64,
padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),

// top_app_bar.dart: Line 421
if (MediaQuery.sizeOf(context).width >= 600) ...[
  // Displays 'KEYBOARD SHORTCUTS' tag pills
]
```

* **`< 600dp`**:
  * Container height clamped to `56dp`.
  * Horizontal padding set to `8dp`.
  * Leading hamburger/menu toggle button is omitted.
* **$\ge 600\text{dp}$**:
  * Container height increases to `64dp`.
  * Horizontal padding expands to `12dp`.
  * Displays the rail expand/collapse toggle button (`Icons.menu_rounded` / `Icons.menu_open_rounded`).
  * Displays the keyboard shortcuts drawer section (`/`, `N`, `R`, `Esc`).
* **$\ge 640\text{dp}$**:
  * Displays the 'Zeta' typography brand logo next to the app icon.

---

### 3.3 Home Dashboard (`lib/pages/home_page.dart`)

```dart
// home_page.dart: Lines 84-87
final width = MediaQuery.sizeOf(context).width;
final isCompact = width < 600;
final isWide = width >= 960;

// home_page.dart: Lines 160-167
padding: EdgeInsets.symmetric(
  horizontal: isCompact ? 16 : (isWide ? 40 : 24),
  vertical: 24,
),
child: Align(
  alignment: Alignment.topCenter,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 1120),
    ...
```

* **`< 600dp` (Mobile)**:
  * Horizontal padding = `16dp`.
  * Stacks `leftColumn` (Today's Focus + Recent Tasks) and `rightColumn` (Streak Calendar + Summary Widgets) vertically with `24dp` separation.
* **`600dp – 959dp` (Tablet / Medium)**:
  * Horizontal padding = `24dp`.
  * Keeps `leftColumn` and `rightColumn` vertically stacked.
* **$\ge 960\text{dp}$ (Wide Desktop)**:
  * Horizontal padding jumps to `40dp`.
  * Splits into a **dual-column layout**:
    * Left column: `flex: 6` (~60% width).
    * Right column: `flex: 4` (~40% width).
  * Entire dashboard content is constrained to `maxWidth: 1120dp` and centered.

---

### 3.4 Tasks Management (`lib/pages/tasks_page.dart`)

```dart
// tasks_page.dart: Lines 39-40
final width = MediaQuery.sizeOf(context).width;
final isCompact = width < 600;

// tasks_page.dart: Lines 115-121
padding: EdgeInsets.symmetric(
  horizontal: isCompact ? 16 : 36,
  vertical: 28,
),
child: ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 860),
```

* **`< 600dp` (Compact)**:
  * Horizontal padding = `16dp`.
  * Filter button group is centered on line 1; sort button drops to line 2 right-aligned (`mainAxisAlignment.end`).
* **$\ge 600\text{dp}$ (Medium & Up)**:
  * Horizontal padding increases to `36dp`.
  * Filter buttons and sort button sit on a single horizontal row (`mainAxisAlignment.spaceBetween`).
  * Task feed width is clamped to `maxWidth: 860dp` and centered.

---

### 3.5 Settings Screen (`lib/pages/settings_page.dart`)

```dart
// settings_page.dart: Lines 200-202
final width = MediaQuery.sizeOf(context).width;
final isTwoPane = width >= 640;

// settings_page.dart: Lines 318-323
final currentWidth = _hasCustomWidth
    ? _paneWidth
    : (totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth);
// _defaultPaneWidth = 310.0;
// _largePaneWidth = 360.0;
// _minPaneWidth = 240.0;
// _minContentPaneWidth = 360.0;
```

* **`< 640dp` (Single Pane)**:
  * Displays single category list with `SliverAppBar.large`.
  * Selecting a category triggers an animated `M3EPageTransition` with `M3EPageTransitionType.sharedAxisX` to the subcategory view.
* **$\ge 640\text{dp}$ (Two-Pane with M3PaneDivider)**:
  * Dual-pane Canonical List-Detail layout.
  * Left pane: Category selector (default `310dp`, resizable down to `240dp`).
  * Right pane: Category content pane.
  * At **$\ge 1200\text{dp}$**, default navigation pane expands to **`360dp`**.

---

### 3.6 Pomodoro Timer & Analytics (`lib/pages/pomodoro_page.dart` & `lib/components/pomodoro/pomodoro_timer_pane.dart`)

```dart
// pomodoro_page.dart: Lines 175-176
final width = MediaQuery.sizeOf(context).width;
final isTwoPane = width >= 840;

// pomodoro_page.dart: Lines 220-225
final currentWidth = _hasCustomWidth
    ? _supportingPaneWidth
    : (totalWidth >= 1200 ? _largeSupportingPaneWidth : _defaultSupportingPaneWidth);
// _defaultSupportingPaneWidth = 360.0;
// _largeSupportingPaneWidth = 420.0;
// _minFocusPaneWidth = 400.0;
// _minSupportingPaneWidth = 320.0;

// pomodoro_timer_pane.dart: Lines 24-26
final width = MediaQuery.sizeOf(context).width;
final isCompact = width < 840;
final bottomPadding = isCompact ? 96.0 : 24.0;
```

* **`< 840dp` (Single Pane)**:
  * Displays Timer pane only.
  * Applies `bottomPadding: 96dp` to accommodate the floating bottom navigation toolbar.
* **$\ge 840\text{dp}$ (Two-Pane Supporting Pane Layout)**:
  * Left pane: Main `PomodoroTimerPane` (Expanded).
  * Center: Resizable `M3PaneDivider`.
  * Right pane: `PomodoroAnalysisPane` (default `360dp`, expands to `420dp` at $\ge 1200\text{dp}$).
  * Bottom padding drops to `24dp`.

---

### 3.7 Bin & Revision Pages (`bin_page.dart`, `bin_header.dart`, `revision_page.dart`)

* **`< 600dp`**: Horizontal padding = `16dp`. `BinHeader` wraps action buttons under the title.
* **$\ge 600\text{dp}$**: Horizontal padding = `36dp`. `BinHeader` aligns count and action buttons horizontally in one row. `maxWidth: 860dp`.

---

### 3.8 Modals, Dialogs, and Sheets (`lib/components/tasks/task_edit_pane.dart`)

```dart
// task_edit_pane.dart: Lines 26-60
final width = MediaQuery.sizeOf(context).width;
final isCompact = width < 600;

if (isCompact) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => M3EBottomSheet(...),
  );
} else {
  return showM3EDialog(
    context: context,
    builder: (ctx) => Dialog(
      constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ...
    ),
  );
}
```

* **`< 600dp`**: Swaps dialog for a full-width bottom sheet (`M3EBottomSheet`) with drag handle.
* **$\ge 600\text{dp}$**: Displays an elevated Material 3 dialog (`showM3EDialog`) capped at $580 \times 720\text{dp}$ with `28dp` corner radius.

---

## 4. Granular Side-by-Side Comparison Matrix

| Architectural Dimension | Material Design 3 (M3) Official Specification | Zeta Current Implementation | Alignment Status |
|---|---|---|---|
| **Breakpoint Naming** | `Compact`, `Medium`, `Expanded`, `Large`, `Extra-Large` | Unnamed ad-hoc boolean flags (`isCompact`, `isWide`, `isTwoPane`) | ⚠️ **Divergent** (Lacks formal enum) |
| **Compact Threshold** | `< 600dp` | `< 600dp` across App Scaffold, Tasks, Home, Bin, Revision, Edit Pane |  **Fully Aligned** |
| **Medium Threshold** | `600dp – 839dp` | Partially mapped (`600dp` in Scaffold, `640dp` in Settings & Top Bar) | ⚠️ **Partial Alignment** |
| **Expanded Threshold** | `840dp – 1199dp` | `840dp` in Pomodoro & Scaffold; `960dp` in Home | ⚠️ **Fragmented** |
| **Large Threshold** | `1200dp – 1599dp` | `1200dp` used in Settings & Pomodoro pane scaling |  **Aligned for Pane Scaling** |
| **Extra-Large Threshold**| `1600dp+` | Not implemented; capped by static `BoxConstraints` | ⚠️ **Missing** |
| **Outer Margins (Compact)**| `16dp` | `16dp` across Home, Tasks, Revision, Bin |  **Fully Aligned** |
| **Outer Margins (Medium+)**| `24dp` | `36dp` (Tasks, Revision, Bin), `40dp` (Home wide), `24dp` (Home mid) | ❌ **Non-Standard Margins** |
| **Pane Spacer / Gutter** | `24dp` | `24dp` in Home columns; `M3PaneDivider` in Settings & Pomodoro |  **Aligned** |
| **Primary Navigation** | Bottom Nav Bar (<600dp) $\leftrightarrow$ Nav Rail (600dp+) | Floating Bottom Toolbar (<600dp) $\leftrightarrow$ M3ENavigationRail (600dp+) |  **Expressive M3 Aligned** |
| **Top App Bar Adaptation** | 64dp standard; collapses/elevates on scroll | 56dp (<600dp) $\leftrightarrow$ 64dp (600dp+); hide on compact settings |  **Fully Aligned** |
| **Canonical Supporting Pane**| Main canvas + 360dp fixed pane (at $\ge 840\text{dp}$) | Pomodoro Timer + 360dp Analysis pane (at $\ge 840\text{dp}$) |  **Exemplary M3 Alignment** |
| **Canonical List-Detail** | 50/50 split on Medium, or 360dp fixed list on Expanded | 310dp list on Settings (triggered at 640dp instead of 840dp) | ⚠️ **Sub-optimal for 640–839dp** |
| **Modal Adaptation (Swap)**| Bottom Sheet (<600dp) $\leftrightarrow$ Dialog (600dp+) | `M3EBottomSheet` (<600dp) $\leftrightarrow$ `Dialog` (600dp+) |  **Fully Aligned** |
| **Desktop Max Widths** | Unconstrained or responsive content margin gutters | Clamped at `860dp` (Tasks) and `1120dp` (Home) | ⚠️ **Stops Content Expansion** |

---

## 5. In-Depth Gap Analysis & Discrepancies

### Discrepancy 1: Threshold Fragmentation (600, 640, 840, 960, 1200)

* **Problem**: Zeta contains five distinct magic breakpoint numbers scattered across different files:
  1. `600dp`: Used by `AppScaffold`, `TasksPage`, `BinPage`, `RevisionPage`, `TaskEditPane`, and `TopAppBar`.
  2. `640dp`: Used by `SettingsPage` (`isTwoPane = width >= 640`) and `TopAppBar` (`showBrandText = width >= 640`).
  3. `840dp`: Used by `PomodoroPage` (`isTwoPane = width >= 840`) and `AppScaffold` (`isExpanded = width >= 840`).
  4. `960dp`: Used by `HomePage` (`isWide = width >= 960`).
  5. `1200dp`: Used by `SettingsPage` and `PomodoroPage` for pane width scaling.
* **Impact**: Different parts of the app adapt at disjointed moments. For example, resizing a desktop window from `1000dp` to `700dp` causes the Home page to collapse into a single column at `960dp`, the Pomodoro timer to collapse into a single pane at `840dp`, but Settings remains in two panes until `639dp`!

### Discrepancy 2: Margins & Gutters Drifting (16 / 24 / 36 / 40dp)

* **Problem**: In M3 layout documentation:
  * Compact is always **`16dp`**.
  * Medium, Expanded, Large, and Extra-Large are uniformly **`24dp`**.
* **In Zeta**:
  * Tasks, Revision, and Bin use `horizontal: 36dp` on screens $\ge 600\text{dp}$.
  * Home uses `horizontal: 40dp` on screens $\ge 960\text{dp}$.
  * Settings uses `16dp` inner padding for its navigation pane sliver.
* **Impact**: Pages feel slightly inconsistent when switching tabs on wide desktop monitors (e.g. content suddenly jumps from 24dp to 36dp or 40dp margins).

### Discrepancy 3: Fixed vs. Split Two-Pane Behavior in Medium Screens

* **Problem**: `SettingsPage` activates two panes at `width >= 640dp`:
  * At `640dp`, the navigation rail already takes `80dp` of horizontal width.
  * That leaves $640 - 80 = 560\text{dp}$.
  * The settings navigation pane takes `310dp`.
  * The remaining details pane is left with only $560 - 310 - 16 = 234\text{dp}$!
* **Impact**: On a small tablet or foldable in portrait mode (width 600–768dp), the right settings pane becomes severely cramped and horizontally constrained.
* **M3 Solution**:
  * Either wait until **Expanded (`840dp`)** before activating dual-pane mode, OR
  * If activating dual-pane on Medium (`600–839dp`), use an ergonomic **50% / 50% split** and retain the bottom navigation bar rather than a side rail.

### Discrepancy 4: Absence of a Centralized Breakpoint Token System

* **Problem**: Every widget invokes `MediaQuery.sizeOf(context).width` directly:
  ```dart
  // In Home:
  final isCompact = width < 600;
  final isWide = width >= 960;
  
  // In Tasks:
  final isCompact = width < 600;
  
  // In Settings:
  final isTwoPane = width >= 640;
  
  // In Pomodoro:
  final isTwoPane = width >= 840;
  ```
* **Impact**: No single source of truth exists. Testing responsive behavior, modifying thresholds, or querying window size classes requires hunting through multiple UI files.

### Discrepancy 5: Large (1200dp) and Extra-Large (1600dp+) Neglect

* **Problem**: Modern desktop monitors and high-DPI displays routinely exceed 1920dp width.
* **In Zeta**:
  * Content is hard-capped inside `ConstrainedBox(maxWidth: 860)` or `maxWidth: 1120`.
  * On a 1440p or 4K monitor, Zeta produces vast empty gutters on either side of a relatively narrow center column.
* **M3 Solution**:
  * Large screens (`1200dp+`) scale up fixed panes to `412dp`.
  * Extra-Large screens (`1600dp+`) can surface a **third supporting pane** (e.g. Quick Task Inspector or Persistent Pomodoro Mini-Widget) up to 400dp wide, turning unused whitespace into valuable productivity real estate.

---

## 6. Recommendations & Implementation Roadmap for Zeta

### Phase 1: Establish `ZetaBreakpoints` & `ZetaWindowSizeClass`

Create a centralized design token file in `lib/theme/breakpoints.dart`:

```dart
/// Centralized Material 3 Window Size Class Breakpoints for Zeta
enum ZetaWindowSizeClass {
  compact,   // < 600dp (Phone portrait)
  medium,    // 600dp - 839dp (Tablet portrait, foldable unfolded)
  expanded,  // 840dp - 1199dp (Tablet landscape, laptop)
  large,     // 1200dp - 1599dp (Desktop monitor)
  extraLarge // 1600dp+ (Ultra-wide desktop)
}

class ZetaBreakpoints {
  static const double compactMax = 599.0;
  static const double mediumMin = 600.0;
  static const double mediumMax = 839.0;
  static const double expandedMin = 840.0;
  static const double expandedMax = 1199.0;
  static const double largeMin = 1200.0;
  static const double largeMax = 1599.0;
  static const double extraLargeMin = 1600.0;

  // Standard M3 Spacing Tokens
  static const double marginCompact = 16.0;
  static const double marginMedium = 24.0;
  static const double paneSpacer = 24.0;

  // Pane Dimension Tokens
  static const double defaultFixedPaneWidth = 360.0;
  static const double largeFixedPaneWidth = 412.0;
  static const double maxSideSheetWidth = 400.0;

  static ZetaWindowSizeClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mediumMin) return ZetaWindowSizeClass.compact;
    if (width < expandedMin) return ZetaWindowSizeClass.medium;
    if (width < largeMin) return ZetaWindowSizeClass.expanded;
    if (width < extraLargeMin) return ZetaWindowSizeClass.large;
    return ZetaWindowSizeClass.extraLarge;
  }
}
```

### Phase 2: Standardize Page Margins & Gutters to M3 Tokens

1. Replace `36dp` in `tasks_page.dart`, `revision_page.dart`, and `bin_page.dart` with standard `24dp` padding.
2. In `home_page.dart`, align the wide padding to standard M3 increments (`24dp` outer margins, `24dp` column gutter).
3. Ensure all scrollable list views share an identical horizontal alignment grid.

### Phase 3: Align Canonical Pane Thresholds

1. **Unify Two-Pane Activation to `840dp` (Expanded)**:
   * Both `SettingsPage` and `PomodoroPage` should activate their dual-pane supporting views at `width >= 840dp`.
   * For Medium screens (`600dp – 839dp`), `SettingsPage` should remain single-pane with `M3EPageTransition` (or use a 50%/50% split) so the content pane never drops below `300dp`.
2. **Harmonize Home Page Grid**:
   * Switch the Home dashboard to dual-column layout at `840dp` (matching Expanded) rather than `960dp`.

### Phase 4: Responsive Sheet/Dialog & Extra-Large Desktop Handling

1. **Pane Sizing on Large Screens (`1200dp+`)**:
   * Align Settings and Pomodoro fixed pane defaults to M3's official **`412dp`** token when window width $\ge 1200\text{dp}$.
2. **Desktop Constraint Optimization**:
   * On Extra-Large viewports ($\ge 1600\text{dp}$), allow the dashboard max-width to expand comfortably to `1360dp` or introduce a contextual quick-action inspector, making full use of expansive desktop real estate.

---

## 7. Material Design 3 Scaffold System (Navigation Suite Scaffold)

Breakpoints are only the **trigger thresholds** of a responsive interface. The container that orchestrates where UI elements live across those thresholds is the **Scaffold**. 

In official Material Design 3 and modern Android/Compose/Flutter architecture, this is formalized as the **`NavigationSuiteScaffold`**. Without a standardized scaffold specification, apps end up with fractured navigation hierarchies, inconsistent system bar handling, and misplaced action buttons.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        COMPACT SCAFFOLD LAYOUT (< 600dp)                               │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ [Top App Bar] (Height: 56dp / 64dp, Search, Profile, Navigation Back)                 │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                        │
│                                  BODY CONTENT PANE                                     │
│                         (Single scrollable primary view)                               │
│                                                                                        │
│                                                  [Floating Action Button (FAB)]        │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ [Bottom Navigation Bar / Floating Toolbar] (Height: 80dp or Floating 64dp)             │
└────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────┐
│                     EXPANDED / LARGE SCAFFOLD LAYOUT (840dp+)                          │
├───────────────┬────────────────────────────────────────────────────────────────────────┤
│               │ [Top App Bar] (Height: 64dp, Global Search, Brand, Actions, Window Controls) │
│ [M3           ├───────────────────────────────────┬────────────────────────────────────┤
│  Navigation   │                                   │                                    │
│  Rail]        │         PRIMARY PANE              │       SUPPORTING / DETAIL PANE     │
│               │       (Flexible Canvas)           │     (Fixed 360dp / 412dp or 50%)   │
│ • [FAB Slot]  │                                   │                                    │
│ • Dest 1      │                                   │                                    │
│ • Dest 2      │                                   │                                    │
│ • Dest 3      │                                   │                                    │
│               │                                   │                                    │
└───────────────┴───────────────────────────────────┴────────────────────────────────────┘
```

### 7.1 Structural Anatomy & Slot Layout

An M3 Scaffold exposes six dedicated structural slots:

1. **`navigationSuite` Slot**:
   * Automatically swaps between:
     * **Compact (`< 600dp`)**: `NavigationBar` docked at screen bottom ($80\text{dp}$ height) or floating bottom pill toolbar ($64\text{dp}$ height, $16\text{dp}$ bottom margin).
     * **Medium (`600dp – 839dp`)**: `NavigationRail` ($80\text{dp}$ width collapsed) on the leading edge for single-pane views, OR `NavigationBar` at screen bottom for 50/50 dual-pane views.
     * **Expanded & Large (`840dp+`)**: `NavigationRail` ($80\text{dp}$ collapsed or $220\text{dp}–256\text{dp}$ expanded) or permanent `NavigationDrawer` ($360\text{dp}$ max).
2. **`topAppBar` Slot**:
   * **Small Top App Bar** ($64\text{dp}$): Standard for utility and dense screens.
   * **Medium** ($112\text{dp}$) & **Large** ($152\text{dp}$) **Top App Bars**: Used for primary top-level destinations (Tasks, Settings). On scroll, they collapse into a $64\text{dp}$ pinned surface with dynamic tonal elevation.
3. **`body` Slot**:
   * Consumes window insets and hosts the canonical pane scaffold (`ListDetailPaneScaffold` or `SupportingPaneScaffold`).
4. **`floatingActionButton` (FAB) Slot**:
   * Position adapts dynamically:
     * On Compact: Floats in the lower-right corner ($16\text{dp}$ above the bottom bar) or docks directly inside the bottom bar cutout.
     * On Medium/Expanded/Large: Mounts inside the `NavigationRailFabSlot` at the top of the rail, maintaining an aligned vertical visual rhythm.
5. **`sideSheet` Slot**:
   * Standard persistent side sheet on Large/Extra-Large viewports ($\ge 1200\text{dp}$) with maximum width **$400\text{dp}$**. Swaps to a modal sheet or full-screen dialog on Compact.
6. **`snackbar` / `floatingToolbar` Slot**:
   * Floats centered or docked at bottom margin; automatically offsets upward when bottom sheets or keyboards appear.

### 7.2 Inset Consumption & Edge-to-Edge System Bars

Material 3 enforces an **edge-to-edge layout contract**:
* The root scaffold spans under system status bars, navigation bars, and desktop window title bars.
* **Double Padding Anti-Pattern**: The scaffold must consume system insets once and pass the remaining `innerPadding` down to its body children. In Zeta, several components query `MediaQuery.paddingOf(context)` directly, risking double-padding if an outer widget also injects safe area insets.
* **Desktop Title Bar Synchronization**: On Windows/macOS, caption controls (minimize, maximize, close) share the horizontal line with the `TopAppBar`. Zeta currently handles this via `WindowsTitleBar.update()` in `app_scaffold.dart`.

### 7.3 Floating Action Button (FAB) Placement Across Size Classes

* **Compact (`< 600dp`)**: Floating at `bottom: 88, right: 16` (above floating nav), or embedded in floating bottom action bar.
* **Expanded (`840dp+`)**: The FAB must move into the Navigation Rail (`M3ENavigationRailFabSlot`).
* **Zeta Audit**: Zeta's `_NavigationRailWidget` implements `M3ENavigationRailFabSlot(label: 'New Task', icon: Icons.add_rounded)`, which accurately reflects the M3 desktop FAB paradigm.

### 7.4 Bottom Navigation Toolbar vs. Standard M3 Navigation Bar

* **Standard M3 Navigation Bar**: Edge-to-edge container, $80\text{dp}$ height, container color `surfaceContainer`, with pill indicators ($32\text{dp}$ height, $64\text{dp}$ width).
* **M3 Expressive Floating Bottom Nav (Zeta's implementation)**:
  * Zeta uses a floating pill container (`_FloatingBottomNav`) with rounded stadium shape ($32\text{dp}$ radius), docked $16\text{dp}$ above the bottom screen edge.
  * When multi-selection mode activates (`TaskSelectionToolbar`), the navigation bar slides down and off-screen (`AnimatedSlide(offset: Offset(0, 2.0))`), and the selection toolbar slides into its place.
  * This is a recognized Material 3 Expressive interaction pattern that optimizes thumb accessibility on mobile devices.

---

## 8. Material Design 3 Panes Architecture (Canonical Layouts)

While breakpoints dictate *when* to adapt, **Panes** dictate *how* content divides and flows. M3 defines three canonical pane layouts: **List-Detail**, **Supporting Pane**, and **Feed**.

```
   CANONICAL LIST-DETAIL                        CANONICAL SUPPORTING PANE
┌───────────────┬──────────────────────┐     ┌──────────────────────┬───────────────┐
│   LIST PANE   │     DETAIL PANE      │     │  PRIMARY FOCUS PANE  │SUPPORTING PANE│
│ (Hierarchical │ (Leaf Node Content   │     │  (Editor, Main Feed, │  (Telemetry,  │
│  Navigation   │  Updated in Place)   │     │   Timer, Document)   │  Properties)  │
│  360dp/50%)   │   (Flexible)         │     │     (Flexible)       │ (Fixed 360dp) │
└───────────────┴──────────────────────┘     └──────────────────────┴───────────────┘
```

### 8.1 List-Detail Layout: Dual-Pane Contract & Back-Stack State Machine

The **List-Detail** layout displays a parent collection in one pane and the selected child item in the adjacent pane. In Zeta, this pattern is represented by `SettingsPage` (category list $\rightarrow$ category detail).

#### The State Machine & Back-Stack Contract
Implementing List-Detail *exactly as per M3* requires adhering to a strict state and navigation machine:

```
                          ┌──────────────────────────┐
                          │  Window Width < 600dp    │
                          │     (Single Pane)        │
                          └─────────────┬────────────┘
                                        │
                      User selects item │ User presses Back
                                        ▼
┌───────────────────┐    Push route     ┌───────────────────┐
│     LIST VIEW     │ ───────────────>  │    DETAIL VIEW    │
│ (Active Selection │ <───────────────  │ (Full screen, own │
│     Hidden)       │     Pop route     │   Back Button)    │
└───────────────────┘                   └───────────────────┘

                          ┌──────────────────────────┐
                          │  Window Width >= 840dp   │
                          │      (Dual Pane)         │
                          └─────────────┬────────────┘
                                        │
                      User selects item │ User presses Back
                                        ▼
┌───────────────────────────────────────┬───────────────────────────────────────┐
│              LIST PANE                │             DETAIL PANE               │
│ • Persistent active item highlight    │ • Updates in-place with crossfade     │
│ • Scroll position preserved           │ • Back press DOES NOT navigate back   │
│ • Never pops on Back press            │ • Back press clears selection / exits │
└───────────────────────────────────────┴───────────────────────────────────────┘
```

* **Compact (`< 600dp`)**:
  * List and Detail **never coexist**.
  * Tapping a list item navigates to the detail screen with a `sharedAxisX` motion transition.
  * The detail screen provides a leading Back icon to return to the list.
* **Expanded (`840dp+`)**:
  * Both panes display simultaneously.
  * Tapping a list item **must not push a new navigator route**; it mutates the active ID in state, crossfading the detail pane content.
  * The detail pane **must not show a Back button**.
  * If no item is selected, the detail pane displays a semantic **empty state card** (e.g. "Select a setting category from the left").
* **Zeta Gap in Settings**:
  * In `settings_page.dart`, dual-pane is triggered at **`640dp`** with a custom navigation pane width of **`310dp`**.
  * On a small 7" tablet ($600\text{dp}–768\text{dp}$), after subtracting the $80\text{dp}$ rail, the detail pane is squished into $\sim 234\text{dp}$, causing overflow.
  * **Fix**: Retain single pane until **`840dp`** (Expanded) or implement a **50% / 50% split** with bottom navigation.

### 8.2 Supporting Pane Layout: Contextual Sidebar vs. Modal Bottom Sheet

The **Supporting Pane** layout pairs a primary focus canvas (~60–70% width) with a secondary contextual tool/analytics panel (~30–40% width). In Zeta, this is implemented in `PomodoroPage` (Timer focus pane + Analysis supporting pane).

* **Expanded Viewports ($\ge 840\text{dp}$)**:
  * Supporting pane docks to the trailing edge.
  * Default width: **`360dp`** on Expanded ($840\text{dp}–1199\text{dp}$); expands to **`412dp`** on Large ($1200\text{dp}+$); max width capped at **`400dp–420dp`**.
  * Fixed pane separation: A **`24dp`** gutter or a draggable divider (`M3PaneDivider`).
* **Compact Viewports (`< 600dp`) & Medium Single-Pane (`600dp–839dp`)**:
  * The supporting pane **swaps** into an on-demand **Modal Bottom Sheet** or **Full-Screen Dialog**. It must never compress the primary focus canvas.
* **Collapse Affordance**:
  * When a user collapses the supporting pane, a trailing edge affordance button (e.g. `Icons.dock_to_right`) must remain visible on the primary canvas so the user can restore it without reloading the screen.

### 8.3 Feed Layout: Multi-Column Responsive Grid Architecture

The **Feed Layout** displays collections of cards or uniform data widgets. In Zeta, this represents `HomePage` and `TasksPage`.

* **Column Count Tokens**:
  * Compact: **4 Columns** (Cards span 4/4 width = 1 card per row).
  * Medium: **8 Columns** (Cards span 4/8 width = 2 cards per row).
  * Expanded & Large: **12 Columns** (Cards span 4/12 or 6/12 width = 2 to 3 cards per row).
* **Card Width Limits**:
  * Minimum card width: **$280\text{dp}$** (below this, typography wraps awkwardly).
  * Maximum card width: **$480\text{dp}$** (above this, single-line text stretches past comfortable reading lengths of 50–75 characters).

### 8.4 Pane Dividers, Touch-Target Drag Handles & Collapsed Affordances

When allowing users to resize panes:
* **Divider Thickness**:
  * Visual hairline: **$1\text{dp}–2\text{dp}$** width colored with `colorScheme.outlineVariant`.
  * Interactive touch target: Must be expanded to at least **$24\text{dp}–48\text{dp}$** hit-test padding with a visible grab handle pill ($4\text{dp} \times 32\text{dp}$, $2\text{dp}$ radius).
* **Clamping Limits**:
  * Minimum Primary Focus Pane width: **$360\text{dp}$**.
  * Minimum Supporting / List Pane width: **$240\text{dp}$**.
  * Double-tap gesture: Resets pane width to default M3 token ($360\text{dp}$ or $412\text{dp}$).

---

## 9. Surface Color Roles & Tonal Elevation in Multi-Pane Views

Material Design 3 eliminates drop shadows for desktop panes, replacing them with **Tonal Surface Container Roles**. When multiple panes are visible concurrently, their background tones establish visual hierarchy and depth:

| M3 Surface Token | Typical Scaffold / Pane Role | Contrast Intent |
|---|---|---|
| **`surface`** | Base canvas background | Clean, neutral backdrop |
| **`surfaceContainerLowest`** | Primary content pane (e.g. document editor or timer card) | Highest contrast area; draws user focus |
| **`surfaceContainerLow`** | Main scrollable body area | Subtle framing container |
| **`surfaceContainer`** | Top App Bar, Navigation Rail, Supporting Pane background | Primary framing level; distinctly separates panes |
| **`surfaceContainerHigh`** | List-Detail selected item card, floating bottom navigation | Elevated interactive layer |
| **`surfaceContainerHighest`** | Drag handles, dialog surfaces, search input fields | Highest tonal layer before modal overlays |

### Color Hierarchy in Dual-Pane Architecture:
* **List Pane (Left)**: Sits on **`surfaceContainerLow`** with active item pills on **`secondaryContainer`**.
* **Detail / Supporting Pane (Right)**: Sits on **`surfaceContainer`** or **`surface`**, bordered by a $1\text{dp}$ stroke of `outlineVariant` ($0.2$ alpha) or a $24\text{dp}$ whitespace gutter.

---

## 10. Adaptive Motion, State Preservation & Window Resize Engine

When a user resizes their window (or rotates a mobile device between portrait and landscape), the application must transition seamlessly without jarring visual jumps or lost user state:

1. **State Preservation Contract**:
   * **Active Selection**: When resizing from Compact ($500\text{dp}$) to Expanded ($900\text{dp}$), if a detail item was open in a sub-route, the router must flatten the route and highlight that active item in the dual-pane list without losing user input.
   * **Independent Scroll Positions**: Each pane must maintain its own `PageStorageKey` (e.g. `PageStorageKey('settings_list')` and `PageStorageKey('settings_detail')`) so scrolling one pane never resets or jerks the other.
2. **Motion Curve & Durations**:
   * **Pane Expanding / Collapsing**: Duration **$350\text{ms}$**, easing `Curves.easeInOutCubicEmphasized` (`standardDecelerate`).
   * **Compact Shared-Axis Drill-down**: Duration **$300\text{ms}$**, using `M3EPageTransitionType.sharedAxisX`.
   * **Selection Crossfade**: Duration **$200\text{ms}$**, using `Curves.easeOutCubic` when swapping active items in a dual-pane view.

---

*Authored for the Zeta Task Management Application · Aligned with Google Material Design 3 Guidelines*


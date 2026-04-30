# AccessibilitySupport

Small app-local helper module for Accessibility-driven launcher behavior in `EmojiMatch`.

## Purpose

This target owns two things:

- checking and requesting macOS Accessibility permission
- resolving the best available text anchor near the current insertion point

It is intentionally app-specific. It is not meant to be shared through `Package.swift`.

## Public API

Use the module through two static helpers:

```swift
import AccessibilitySupport

AccessibilityPermission.requestIfNeeded()
let anchorRect = TextAnchorResolver.anchorRect()
```

### `AccessibilityPermission`

- `AccessibilityPermission.status`
- `AccessibilityPermission.isGranted`
- `AccessibilityPermission.requestIfNeeded()`

This is the simple app-facing permission API. App code decides when to prompt, so onboarding and
future error handling can stay outside the resolver logic.

### `TextAnchorResolver`

- `TextAnchorResolver.anchorRect()`

Returns a `CGRect` for the focused text caret when a reliable anchor can be resolved.
Returns `nil` when Accessibility is unavailable or the current app does not expose enough text
context.

## Resolution Strategy

The resolver prefers:

1. exact AX text marker bounds
2. exact AX selected-range bounds
3. nearby character bounds
4. estimated caret position from text content and selection
5. `nil` so the app can fall back to screen center

It also enables `AXManualAccessibility` on the frontmost app to improve support for Electron and
WebView wrappers.

## Internal Structure

- `Sources/Public`
  - app-facing helper API only
- `Sources/Internal/TextAnchorLocator.swift`
  - main resolution flow and fallback order
- `Sources/Internal/AccessibilityElementReader.swift`
  - AX tree and attribute access
- `Sources/Internal/ManualAccessibilityWarmup.swift`
  - `AXManualAccessibility` warmup cache
- `Sources/Internal/FocusedTextAnchorHeuristics.swift`
  - pure heuristics used by fallbacks
- `Tests/TextAnchorHeuristicsTests.swift`
  - pure logic coverage

The internals are deliberately hidden behind the small public surface because this logic is
necessarily messy and platform-specific.

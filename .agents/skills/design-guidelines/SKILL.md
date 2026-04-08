---
name: design-guidelines
description: "Use for any UI design work that should feel Apple-style and aligned with the Human Interface Guidelines."
---

# Apple HIG UI

- Use the local `DesignSystem` package when building apps in this repository. This is required, not optional.
- Prefer `DesignSystem` tokens and native SwiftUI APIs together instead of introducing parallel styling systems or raw literals.
- Make the UI feel native to Apple platforms.
- Follow HIG principles: clarity, hierarchy, consistency, and restraint.
- Prefer system patterns, typography, spacing, and controls.
- Keep color, glass, and motion subtle and purposeful.
- Keep repeated elements consistent across the full flow.
- Optimize for readability, touch targets, and scrolling on real device sizes.
- Remove decoration that does not improve understanding or usability.

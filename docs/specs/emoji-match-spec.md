# Emoji Match 🎯

> Working spec for shaping the first version of the app. This document is intentionally temporary
> and may later be replaced by app-level documentation such as a README.

## Summary

Emoji Match is a macOS-first utility for finding and inserting the right emoji while writing.

It is not an emoji keyboard replacement. It is a shortcut-driven helper that stays out of the
way, opens instantly, understands intent, and pastes a useful emoji into the current app with
minimal friction.

The core loop is:

1. Trigger a global shortcut while typing.
2. Type what you mean, or use currently selected text as the starting query.
3. See a ranked list of emoji suggestions.
4. Press Enter to paste the best result into the current app.

## Problem

Default emoji pickers are good when the user already knows the emoji or exact keyword.

They are poor at intent-based lookup such as:

- `emoji for an "Architecture" section header`
- `emoji for a section header`
- `anime`
- `soft spring vibe`
- `subtle celebration`

The current workaround is to leave the writing flow and ask an LLM for emoji suggestions. That is
slow, repetitive, and unnecessary for such a small task.

## Current Development Target

- macOS only
- global shortcut first
- compact picker UI, not a replacement keyboard
- default action is paste
- semantic lookup is core
- supports quick browsing of the full emoji library

## V1 Scope

### Core Features

#### 1. Global shortcut launcher

The app opens from a user-configurable global shortcut.

Expected behavior:

- opens as a compact picker panel
- focuses the search field immediately
- can be used without touching the mouse
- still allows quick browsing of the full emoji library, similar to the default picker

#### 2. Query-based emoji search

The app supports:

- direct keyword search with fuzzy typo tolerance
- category and group search
- multilingual search across all bundled locales
- natural-language intent search

Examples:

- `sparkle`
- `flower`
- `emoji for an "Architecture" section header`
- `anime`
- `subtle celebration`

#### 3. Selected-text prefill

If the user has text selected when the shortcut is triggered, that text becomes the initial query.

Expected behavior:

- selected text is used only for the current lookup
- if selected text cannot be accessed, the launcher opens with an empty field
- no automatic replacement occurs in v1

If text is selected, the UI may also expose an explicit `Emojify` action that enriches the selected
text with emoji suggestions. This should be a deliberate secondary action, not the default path.

#### 4. Ranked suggestions

The app shows a small ranked list of emoji results.

The top result should usually be the default action.

The list should favor:

- strong exact matches
- semantically relevant results
- common and broadly useful emoji over overly obscure matches when relevance is similar

#### 5. Paste as the default action

Pressing Enter pastes the selected emoji into the current app.

This is the primary success path for the product.

Secondary actions may exist, but the default should remain:

- trigger
- query
- Enter

#### 6. Recents and most used

The app stores local usage history on device.

V1 behavior:

- recent selections
- frequently used selections
- local only

#### 7. Secondary copy actions

Secondary actions may include:

- copy emoji to clipboard
- copy emoji as image

These are useful, but not the defining behavior of v1.

## Core UX Flow

### Flow A: Direct lookup

1. User triggers the global shortcut.
2. Launcher appears and search field is focused.
3. User types a query such as `flower`.
4. Results update immediately.
5. User presses Enter to paste the top emoji, or chooses a different result.

### Flow B: Intent lookup

1. User triggers the global shortcut.
2. User types a natural-language query such as `emoji for an "Architecture" section header`.
3. Search system interprets the phrase as intent, not literal keyword matching only.
4. Results are ranked by semantic relevance.
5. User presses Enter to paste the best match.

### Flow C: Selected-text prefill

1. User selects text in another app.
2. User triggers the global shortcut.
3. The selected text is inserted into the search field automatically.
4. Results are shown immediately.
5. User chooses one and pastes it manually via Enter.

### Flow D: Selected-text emojify

1. User selects text in another app.
2. User triggers the global shortcut.
3. The selected text is inserted into the search field automatically.
4. User chooses the `Emojify` action instead of the default paste action.
5. The app produces an emoji-enriched version of the selected text and inserts it back only after
   explicit confirmation.

## Supported Flows

This section lists the flows the product should intentionally support, even while some details are
still open.

### Primary Flows

#### Flow 1: Open launcher

1. User triggers the global shortcut with no selected text.
2. Launcher appears and focuses the search field.
3. If the query is empty, the launcher may show recents, most used, or another lightweight default
   state.
4. User can begin typing immediately.

#### Flow 2: Search and insert

1. User types a query such as `flower`, `sparkle`, or `emoji for a section header`.
2. Local search results appear immediately while typing when relevant matches exist.
3. AI-enhanced results may appear later as a secondary layer when helpful.
4. User can confirm a result without waiting for AI if the direct result is already good enough.
5. Confirming inserts the chosen emoji into the current app and closes the launcher.

Notes:
- direct and natural-language queries are not separate product flows; both use the same search UI
- natural-language queries may sometimes show mostly AI-driven results

#### Flow 3: Selected-text prefill

1. User selects text in another app.
2. User triggers the global shortcut.
3. The selected text becomes the initial query when available.
4. Results appear for that query.
5. User selects an emoji to insert.

#### Flow 4: Recents and most used

1. User opens the launcher with an empty query.
2. Launcher may show recent selections and frequently used emoji.
3. User can choose one directly without typing.
4. Once typing starts, search results become the primary view.

#### Flow 5: Full catalog browsing

1. User opens the launcher.
2. User enters an explicit browse mode to see the emoji catalog.
3. User browses by category, grouping, or search within the catalog.
4. User selects an emoji and inserts it into the current app.

### Result States

These are states within the main search flow, not separate top-level flows.

- `AI loading`
  - direct results may already be visible
  - AI results are still loading
  - launcher may show a lightweight placeholder for the AI section

- `Expanded results`
  - compact view may show only a subset of results
  - user can explicitly expand to inspect more results
  - this can apply to direct results, AI results, or both

- `No results`
  - query returns no useful local match
  - AI may still be loading, unavailable, or also fail to produce a useful suggestion
  - launcher presents a clear no-results state with practical fallback actions

### Keyboard And Dismissal

#### Flow 6: Keyboard-only operation

1. User opens the launcher without using the mouse.
2. User types, navigates results, expands secondary result areas if needed, and confirms a choice.
3. The full primary flow can be completed entirely by keyboard.

Exact keyboard shortcuts remain an open design decision and should be specified later.

#### Flow 7: Dismiss without side effects

1. User opens the launcher.
2. User decides not to insert anything.
3. User dismisses the launcher.
4. No text is inserted and the prior app remains in focus or regains focus appropriately.

### System And Failure Cases

These are support cases around the main flows.

- `Accessibility permission missing`
  - selected-text retrieval or insertion needs Accessibility support
  - required permission is missing
  - app explains degraded behavior and guides the user if needed
  - core search should remain usable when possible

- `Selected text unavailable`
  - user expects selected-text prefill
  - current app does not expose selected text, or access fails
  - launcher opens with an empty query instead of failing

- `AI unavailable`
  - Foundation Models are unsupported, disabled, unavailable, or time out
  - launcher continues to operate using deterministic local search only

- `Insertion or paste failure`
  - user confirms an emoji
  - insertion into the current app fails or is unreliable in that context
  - app handles the failure gracefully

Exact fallback behavior remains open.

### Settings And App Management Flows

#### Flow 8: Settings

1. User opens settings.
2. User updates app preferences.
3. Changes take effect immediately or with clearly defined behavior.

The exact settings list remains open, but likely includes:

- global shortcut customization
- launch behavior such as launch on login
- permissions guidance and status
- optional search or AI preferences
- optional insertion behavior preferences

#### Flow 9: First run

1. User launches Emoji Match for the first time.
2. App explains the core shortcut-driven model briefly.
3. App may surface any important permission or setup steps.

Exact onboarding depth remains open.

#### Flow 10: Reopening while already running

1. Emoji Match is already running in the background.
2. User triggers the shortcut again.
3. Launcher opens or toggles predictably.

Exact toggle behavior remains open.

## Open Questions

The following items are intentionally left undecided for now and should be filled in later as the
product and UI mature.

### Interaction Decisions

- default global shortcut
- result navigation shortcuts
- shortcut for opening the full catalog
- shortcut for expanding secondary result sections
- dismissal behavior when the launcher is already open

### Layout And Presentation Decisions

- exact launcher size and placement
- exact organization of direct results vs AI results
- how many results are visible before expansion
- exact empty-state presentation
- exact recents and most-used layout
- exact catalog layout and grouping
- exact settings layout

### Settings Decisions

- final settings list for v1
- whether to expose launch-on-login in v1
- whether to expose AI-specific settings in v1
- whether to expose insertion-mode preferences in v1

### Failure-Handling Decisions

- exact paste fallback behavior
- exact no-results fallback actions
- exact messaging when Accessibility permission is missing
- exact messaging when AI is unavailable
- exact behavior when selected text is very long or multiline

### Scope Decisions

- whether `Emojify` ships in v1 or later
- whether copy actions ship in v1 or later
- whether clipboard preservation is part of v1

## Search Model

The search stack should be hybrid.

### Baseline search

Use the bundled emoji dataset for:

- emoji value matching
- localized name matching
- localized keyword matching
- group and subgroup matching
- fuzzy matching for misspellings, typos, and near matches

This path should be deterministic and fast.

### Intent-aware search

Use Foundation Models when available to improve queries that are naturally phrased or vague.

Possible uses:

- query rewriting
- concept expansion
- tone interpretation
- reranking candidate emoji

Examples:

- `anime` might surface results like `✨`, `🌸`, `💮`, `🫧`
- `an "Architecture" section header` might favor `🏛️`, `📐`, `🧱`

### Query interpretation

The app should recognize that some phrases are framing text rather than meaningful keywords, for
example:

- `emoji for`
- `emoji for a`
- `emoji for an`

These prefixes should not dominate ranking.

## Technical Notes

### App shape

Likely a small macOS utility app with:

- global shortcut support
- floating launcher panel
- accessibility integration where needed
- pasteboard and insertion support

### Search data

The app should use the existing `Emojis` package and bundled resources as the canonical search
dataset.

This gives:

- multilingual emoji names
- multilingual keywords
- group and subgroup metadata
- deterministic local search behavior

### AI integration

Foundation Models should be treated as an enhancement layer, not the sole search implementation.

V1 should target Foundation Models first, but the intent-search layer should be structured so other
model providers can be added later if needed.

The app should still remain useful if:

- Foundation Models are unavailable
- model latency is too high
- the system does not support the desired features

### Selected text

Selected-text prefill likely requires accessibility-based retrieval from the currently focused app.

Important constraints:

- may require permissions
- may not work uniformly across all apps
- must fail gracefully

### Paste behavior

Default behavior is to paste into the current app, not just copy to clipboard.

This is an important technical area because it affects:

- perceived speed
- reliability
- clipboard side effects

Clipboard preservation may be desirable, but is not required to define v1.

### Copy as image

Copy as image can be implemented by rendering the selected emoji to an image using Apple emoji
rendering on macOS and writing that representation to the pasteboard.

This is a secondary feature and should not complicate the main insertion flow.

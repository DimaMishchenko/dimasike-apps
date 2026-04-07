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

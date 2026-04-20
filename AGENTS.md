## Code Style

Use built-in `swift-format` as the source of truth for code style and linting.

- Configuration file: `.swift-format` at repository root.
- Run lint on code changes:
  `swift format lint Sources Tests apps -r -p`
- Auto-format where possible:
  `swift format Sources Tests apps -r -p -i`
- Fix all the reported issues.

## Tooling

Repository structure:

- The root package is SwiftPM-based and is the source of truth for shared packages and tests.
- Only put reusable cross-app modules in `Package.swift`. App-specific modules and tests must live
  under `apps/` and be modeled with Tuist/local targets instead of SwiftPM targets.
- App code lives under `apps/` and is managed through Tuist manifests.
- Tuist generates the workspace/projects used for app builds and runs. If app files or Tuist manifests change, regenerate with:
  `tuist generate --no-open`

Use the `swift` CLI for SwiftPM package workflows at the repository root, including `swift build`, `swift test`, and other package-oriented commands.

Use the `xcodebuildmcp` CLI by default for Xcode, Tuist workspace, simulator, device, and other Apple-platform app workflows in this repository.

- Before falling back from `xcodebuildmcp`, verify that the needed workflow is unavailable or insufficient in the installed CLI, not just absent from the currently exposed agent tool surface.

Fallback order for `xcodebuildmcp`-driven workflows:

- Fall back to `xcodebuild` when the `xcodebuildmcp` CLI is unavailable or insufficient.
- When using `xcodebuild` directly, pipe output through `xcbeautify`.

## Specs And Contracts

If a change modifies behavior, public API, generation rules, file formats, or invariants, update the corresponding spec or contract document in the same logic change.

## Temporary State Hygiene

Tests and tools that create temporary files or directories must clean them up automatically.

## Code Style

Use built-in `swift-format` as the source of truth for code style and linting.

- Configuration file: `.swift-format` at repository root.
- Run lint on code changes:
  `swift format lint ./ -r -p`
- Auto-format where possible:
  `swift format ./ -r -p -i`
- Fix all the reported issues.

## Tooling

Repository structure:

- The root package is SwiftPM-based and is the source of truth for shared packages and tests.
- App code lives under `apps/` and is managed through Tuist manifests.
- Tuist generates the workspace/projects used for app builds and runs. If app files or Tuist manifests change, regenerate with:
  `tuist generate --no-open`

Use `XcodeBuildMCP` by default for build, test, simulator, device, and related Apple-platform workflows in this repository, regardless of project type.

Fallback order when `XcodeBuildMCP` is unavailable:

- Try the `xcodebuildmcp` CLI.
- If the task is SwiftPM-only, fall back to `swift build` / `swift test`.
- Otherwise, fall back to `xcodebuild`.

## Specs And Contracts

If a change modifies behavior, public API, generation rules, file formats, or invariants, update the corresponding spec or contract document in the same logic change.

## Temporary State Hygiene

Tests and tools that create temporary files or directories must clean them up automatically.

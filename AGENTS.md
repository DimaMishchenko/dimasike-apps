## Code Style

Use built-in `swift-format` as the source of truth for code style and linting.

- Configuration file: `.swift-format` at repository root.
- Run lint on code changes:
  `swift format lint ./ -r -p`
- Auto-format where possible:
  `swift format ./ -r -p -i`
- Fix all the reported issues.

## Tooling

Use `XcodeBuildMCP` by default for Xcode, Swift package, simulator, build, test, and related Apple-platform workflows in this repository.

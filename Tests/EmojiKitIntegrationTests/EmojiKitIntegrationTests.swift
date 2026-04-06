import Foundation
import Testing

@testable import EmojiKit

private let liveTestsEnabled = ProcessInfo.processInfo.environment["EMOJIKIT_LIVE_TESTS"] == "1"

@Test(.enabled(if: liveTestsEnabled))
func liveIntegrationIsOptIn() async throws {
  let dataLoader = EmojiDataLoader()
  let release = try await dataLoader.fetchLatestRelease()
  let locales = try await dataLoader.fetchAvailableLocales(release: release)
  #expect(!locales.isEmpty)
}

@Test(.enabled(if: liveTestsEnabled))
func liveFetchLatestWritesBundleToTempDirectory() async throws {
  let fileManager = FileManager.default
  let outputRoot = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
  defer {
    try? fileManager.removeItem(at: outputRoot)
  }

  let paths = try CLIOutputPaths(
    outputRoot: outputRoot.path,
    metadataPath: nil,
    emojisPath: nil,
    localizationsPath: nil
  )
  let generator = EmojiGenerator()

  let summary = try await generator.fetchLatest(
    paths: paths,
    localeSelection: .explicit(["en"]),
    defaultLocale: "en",
    force: false,
    dryRun: false
  )

  #expect(summary.localeCount == 1)
  #expect(fileManager.fileExists(atPath: paths.metadataPath))
  #expect(fileManager.fileExists(atPath: paths.emojisPath))
  #expect(fileManager.fileExists(atPath: "\(paths.localizationsPath)/index.json"))
  #expect(fileManager.fileExists(atPath: "\(paths.localizationsPath)/en.json"))
}

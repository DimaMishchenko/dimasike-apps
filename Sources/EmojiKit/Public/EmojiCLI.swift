import ArgumentParser
import Foundation

@main
struct EmojiCLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "emoji",
    abstract: "Fetches and generates bundled emoji resources.",
    subcommands: [FetchCommand.self, LocalesCommand.self]
  )
}

struct FetchCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "fetch",
    abstract: "Fetches Unicode and CLDR emoji data.",
    subcommands: [FetchLatestCommand.self]
  )
}

struct LocalesCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "locales",
    abstract: "Lists supported upstream locales.",
    subcommands: [LocalesLatestCommand.self]
  )
}

struct FetchLatestCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "latest",
    abstract: "Fetches the latest supported Unicode and CLDR releases."
  )

  @Option(
    help:
      "Root output directory for generated resources. Defaults to `\(CLIOutputPaths.defaultOutputRoot)`."
  )
  var outputRoot: String?

  @Option(help: "Optional override for metadata.json.")
  var metadataPath: String?

  @Option(help: "Optional override for emojis.json.")
  var emojisPath: String?

  @Option(help: "Optional override for the localizations directory.")
  var localizationsPath: String?

  @Option(help: "Locales to generate: `all` or a comma-separated list.")
  var locales: String?

  @Option(help: "Default fallback locale identifier.")
  var defaultLocale: String = "en"

  @Flag(help: "Rewrite outputs even when content is unchanged.")
  var force = false

  @Flag(help: "Generate in memory and report what would change without writing files.")
  var dryRun = false

  mutating func run() async throws {
    let generator = EmojiGenerator()
    let paths = try CLIOutputPaths(
      outputRoot: outputRoot,
      metadataPath: metadataPath,
      emojisPath: emojisPath,
      localizationsPath: localizationsPath
    )
    let localeSelection = try LocaleSelection(argument: locales)
    let summary = try await generator.fetchLatest(
      paths: paths,
      localeSelection: localeSelection,
      defaultLocale: defaultLocale,
      force: force,
      dryRun: dryRun
    )
    print(summary.rendered)
  }
}

struct LocalesLatestCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "latest",
    abstract: "Prints locale identifiers for the latest supported CLDR release."
  )

  mutating func run() async throws {
    let dataLoader = EmojiDataLoader()
    let release = try await dataLoader.fetchLatestRelease()
    let locales = try await dataLoader.fetchAvailableLocales(release: release)
    for locale in locales.sorted() {
      print(locale)
    }
  }
}

import ArgumentParser
import Foundation

internal struct EmojiGenerator {
  private let dataLoader: EmojiDataLoader
  private let fileManager: FileManager

  internal init(
    dataLoader: EmojiDataLoader = EmojiDataLoader(),
    fileManager: FileManager = .default
  ) {
    self.dataLoader = dataLoader
    self.fileManager = fileManager
  }

  internal func fetchLatest(
    paths: CLIOutputPaths,
    localeSelection: LocaleSelection,
    defaultLocale: String,
    force: Bool,
    dryRun: Bool
  ) async throws -> WriteSummary {
    let release = try await dataLoader.fetchLatestRelease()
    let allLocales = try await dataLoader.fetchAvailableLocales(release: release)
    let selectedLocales =
      switch localeSelection {
      case .all:
        allLocales
      case .explicit(let locales):
        locales.sorted()
      }

    guard selectedLocales.contains(defaultLocale) else {
      throw ValidationError(
        "The default locale `\(defaultLocale)` must be included in the generated locale set."
      )
    }

    let unicodeFiles = try await dataLoader.fetchUnicodeSourceFiles(release: release)
    let emojiTest = try requiredFile(named: "emoji-test.txt", in: unicodeFiles)
    let baseEmojis = try UnicodeEmojiParser.parseEmojiTest(emojiTest.data)

    let localizations = try await generateLocalizations(
      locales: selectedLocales,
      emojis: baseEmojis,
      release: release
    )
    try validate(baseEmojis: baseEmojis, localizations: localizations, defaultLocale: defaultLocale)

    let sourceFiles =
      unicodeFiles.map {
        GeneratedMetadata.SourceFile(name: $0.name, url: $0.url.absoluteString, sha256: $0.sha256)
      }
      + localizations.values
      .flatMap(\.sourceFiles)
      .map {
        GeneratedMetadata.SourceFile(name: $0.name, url: $0.url.absoluteString, sha256: $0.sha256)
      }

    let bundle = GeneratedBundle(
      metadata: GeneratedMetadata(
        schemaVersion: 2,
        unicodeEmojiVersion: release.unicodeEmojiVersion,
        cldrVersion: release.cldrVersion,
        generatedAt: Date(),
        defaultLocaleIdentifier: defaultLocale,
        availableLocaleIdentifiers: selectedLocales,
        sourceFiles: sourceFiles.sorted { ($0.url, $0.name) < ($1.url, $1.name) }
      ),
      emojis: baseEmojis.sorted { $0.sortOrder < $1.sortOrder },
      localizations: Dictionary(
        uniqueKeysWithValues: localizations.map { key, value in
          (
            key,
            GeneratedLocalizationFile(
              localeIdentifier: key,
              entries: value.entries.sorted { $0.key < $1.key }
                .reduce(into: [:]) { result, pair in
                  result[pair.key] = pair.value
                }
            )
          )
        }
      )
    )

    return try BundleWriter(fileManager: fileManager)
      .write(
        bundle: bundle,
        paths: paths,
        force: force,
        dryRun: dryRun
      )
  }

  private func generateLocalizations(
    locales: [String],
    emojis: [GeneratedBaseEmoji],
    release: EmojiDataRelease
  ) async throws
    -> [String: (entries: [String: GeneratedLocalizationEntry], sourceFiles: [EmojiDataFile])]
  {
    let sortedEmojis = emojis.sorted { $0.sortOrder < $1.sortOrder }
    var results:
      [String: (entries: [String: GeneratedLocalizationEntry], sourceFiles: [EmojiDataFile])] = [:]
    var directByLocale: [String: [String: GeneratedLocalizationEntry]] = [:]
    var derivedByLocale: [String: [String: GeneratedLocalizationEntry]] = [:]
    var sourceFilesByLocale: [String: [EmojiDataFile]] = [:]

    for locale in locales {
      let files = try await dataLoader.fetchLocalizationSources(locale: locale, release: release)
      let direct = try localizationEntries(
        in: files,
        matching: "cldr-annotations-full",
        locale: locale
      )
      let derived = try localizationEntries(
        in: files,
        matching: "cldr-annotations-derived-full",
        locale: locale
      )

      directByLocale[locale] = direct
      derivedByLocale[locale] = derived
      sourceFilesByLocale[locale] = files
    }

    guard locales.contains("en") else {
      throw ValidationError("The generated locale set must include `en`.")
    }

    var englishEntries: [String: GeneratedLocalizationEntry] = [:]
    for emoji in sortedEmojis {
      englishEntries[emoji.id] = try effectiveLocalization(
        for: emoji,
        locale: "en",
        direct: directByLocale["en"] ?? [:],
        derived: derivedByLocale["en"] ?? [:],
        english: nil
      )
    }
    results["en"] = (englishEntries, sourceFilesByLocale["en"] ?? [])

    for locale in locales where locale != "en" {
      var entries: [String: GeneratedLocalizationEntry] = [:]
      for emoji in sortedEmojis {
        entries[emoji.id] = try effectiveLocalization(
          for: emoji,
          locale: locale,
          direct: directByLocale[locale] ?? [:],
          derived: derivedByLocale[locale] ?? [:],
          english: englishEntries[emoji.id]
        )
      }

      results[locale] = (entries, sourceFilesByLocale[locale] ?? [])
    }

    return results
  }

  internal func mergeLocalizations(
    direct: [String: GeneratedLocalizationEntry],
    derived: [String: GeneratedLocalizationEntry],
    locale: String,
    emojiIDs: Set<String>
  ) throws -> [String: GeneratedLocalizationEntry] {
    var merged: [String: GeneratedLocalizationEntry] = [:]

    for emojiID in emojiIDs.sorted() {
      let directEntry = localizationEntry(for: emojiID, in: direct)
      let derivedEntry = localizationEntry(for: emojiID, in: derived)

      let name = directEntry?.name.isEmpty == false ? directEntry?.name : derivedEntry?.name
      let tokensSource = directEntry?.searchTokens.isEmpty == false ? directEntry : derivedEntry

      guard let name, let tokens = tokensSource?.searchTokens, !tokens.isEmpty else {
        throw ValidationError("Missing localization values for \(emojiID) in locale \(locale)")
      }

      merged[emojiID] = GeneratedLocalizationEntry(
        name: name,
        searchTokens: stableDeduplicatedTokens(tokens + [name])
      )
    }

    return merged
  }

  internal func effectiveLocalization(
    for emoji: GeneratedBaseEmoji,
    locale: String,
    direct: [String: GeneratedLocalizationEntry],
    derived: [String: GeneratedLocalizationEntry],
    english: GeneratedLocalizationEntry?
  ) throws -> GeneratedLocalizationEntry {
    let directEntry = localizationEntry(for: emoji.id, in: direct)
    let derivedEntry = localizationEntry(for: emoji.id, in: derived)

    let name = directEntry?.name.isEmpty == false ? directEntry?.name : derivedEntry?.name
    let tokensSource = directEntry?.searchTokens.isEmpty == false ? directEntry : derivedEntry

    if let name, let tokens = tokensSource?.searchTokens, !tokens.isEmpty {
      return GeneratedLocalizationEntry(
        name: name,
        searchTokens: stableDeduplicatedTokens(tokens + [name])
      )
    }

    if locale != "en", let english {
      return GeneratedLocalizationEntry(
        name: english.name,
        searchTokens: stableDeduplicatedTokens(english.searchTokens + [english.name])
      )
    }

    return try synthesizedLocalization(for: emoji, locale: locale)
  }

  private func localizationEntry(
    for emojiID: String,
    in entries: [String: GeneratedLocalizationEntry]
  ) -> GeneratedLocalizationEntry? {
    if let exact = entries[emojiID] {
      return exact
    }

    if let alias = localizationAlias(for: emojiID) {
      return entries[alias]
    }

    return nil
  }

  // CLDR keycap annotations are keyed by the base ASCII character rather than the full
  // fully-qualified keycap sequence from emoji-test.txt.
  private func localizationAlias(for emojiID: String) -> String? {
    let components = emojiID.split(separator: "-").map(String.init)
    guard components.count == 3, components[1] == "FE0F", components[2] == "20E3" else {
      return nil
    }

    return components[0]
  }

  private func stableDeduplicatedTokens(_ tokens: [String]) -> [String] {
    var seen: Set<String> = []
    var ordered: [String] = []

    for token in tokens.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
      .filter({ !$0.isEmpty }) where seen.insert(token).inserted
    {
      ordered.append(token)
    }

    return ordered
  }

  private func synthesizedLocalization(
    for emoji: GeneratedBaseEmoji,
    locale: String
  ) throws -> GeneratedLocalizationEntry {
    let name = emoji.fallbackName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      throw ValidationError("Missing synthesized fallback name for \(emoji.id) in locale \(locale)")
    }

    let wordTokens = name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    return GeneratedLocalizationEntry(
      name: name,
      searchTokens: stableDeduplicatedTokens(wordTokens + [name])
    )
  }

  private func validate(
    baseEmojis: [GeneratedBaseEmoji],
    localizations: [String: (
      entries: [String: GeneratedLocalizationEntry], sourceFiles: [EmojiDataFile]
    )],
    defaultLocale: String
  ) throws {
    let ids = baseEmojis.map(\.id)
    guard Set(ids).count == ids.count else {
      throw ValidationError("Generated emoji IDs must be unique.")
    }

    let values = baseEmojis.map(\.value)
    guard Set(values).count == values.count else {
      throw ValidationError("Generated emoji values must be unique.")
    }

    guard localizations.keys.contains(defaultLocale) else {
      throw ValidationError("Generated default locale `\(defaultLocale)` is missing.")
    }

    for emoji in baseEmojis {
      guard !emoji.group.isEmpty, !emoji.subgroup.isEmpty else {
        throw ValidationError("Generated group and subgroup values must be non-empty.")
      }
    }

    let expectedIDs = Set(ids)
    for (locale, localization) in localizations {
      let localizedIDs = Set(localization.entries.keys)
      guard localizedIDs == expectedIDs else {
        throw ValidationError("Localization IDs do not match base emoji IDs for locale \(locale).")
      }
    }
  }

  private func requiredFile(named name: String, in files: [EmojiDataFile]) throws -> EmojiDataFile {
    guard let file = files.first(where: { $0.name == name }) else {
      throw ValidationError("Required source file missing: \(name)")
    }
    return file
  }

  private func file(
    named fileName: String,
    in files: [EmojiDataFile],
    matching needle: String
  ) -> EmojiDataFile? {
    files.first(where: {
      $0.url.absoluteString.contains(needle) && $0.name == fileName
    })
  }

  private func localizationEntries(
    in files: [EmojiDataFile],
    matching needle: String,
    locale: String
  ) throws -> [String: GeneratedLocalizationEntry] {
    guard let file = file(named: "annotations.json", in: files, matching: needle) else {
      return [:]
    }

    return try CLDRParser.parseLocalization(data: file.data, locale: locale)
  }
}

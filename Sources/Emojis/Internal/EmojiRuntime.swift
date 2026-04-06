import Foundation

internal protocol EmojiResourceLoading: Sendable {
  func data(for relativePath: String) throws -> Data
}

internal struct BundleResourceLoader: EmojiResourceLoading {
  private let bundle: Bundle

  internal init(bundle: Bundle = .module) {
    self.bundle = bundle
  }

  internal func data(for relativePath: String) throws -> Data {
    let components = relativePath.split(separator: "/").map(String.init)
    let fileName = components.last ?? relativePath
    let directory = components.dropLast().joined(separator: "/")
    let resourceName = (fileName as NSString).deletingPathExtension
    let resourceExtension = (fileName as NSString).pathExtension

    if let url = bundle.url(
      forResource: resourceName,
      withExtension: resourceExtension.isEmpty ? nil : resourceExtension,
      subdirectory: directory.isEmpty ? nil : directory
    ) {
      return try Data(contentsOf: url)
    }

    if let url = bundle.url(
      forResource: resourceName,
      withExtension: resourceExtension.isEmpty ? nil : resourceExtension
    ) {
      return try Data(contentsOf: url)
    }

    if let resourceRoot = bundle.resourceURL {
      let fallbackURL = resourceRoot.appending(path: relativePath)
      if FileManager.default.fileExists(atPath: fallbackURL.path()) {
        return try Data(contentsOf: fallbackURL)
      }
    }

    throw EmojisError.missingBundledResource(relativePath)
  }
}

internal struct BundledEmojiRecord: Codable, Sendable, Equatable {
  let id: String
  let value: String
  let group: String
  let subgroup: String
  let unicodeVersion: String
  let sortOrder: Int
  let skinToneSupport: Emoji.SkinToneSupport
  let skinToneVariants: [Emoji.SkinToneVariant]
}

internal struct BundledLocalizationIndex: Codable, Sendable, Equatable {
  let defaultLocaleIdentifier: String
  let availableLocaleIdentifiers: [String]
}

internal struct BundledLocalizationFile: Codable, Sendable, Equatable {
  let localeIdentifier: String
  let entries: [String: BundledLocalizationEntry]
}

internal struct BundledLocalizationEntry: Codable, Sendable, Equatable {
  let name: String
  let searchTokens: [String]
}

internal struct EmojiCatalog: Sendable {
  internal let loader: any EmojiResourceLoading
  internal let systemLocale: @Sendable () -> Locale

  #if canImport(CoreText)
    internal let appleVerifier: AppleEmojiSupportVerifier
  #endif

  internal init(
    loader: any EmojiResourceLoading,
    systemLocale: @escaping @Sendable () -> Locale = {
      #if canImport(Darwin)
        Locale.autoupdatingCurrent
      #else
        Locale.current
      #endif
    }
  ) {
    self.loader = loader
    self.systemLocale = systemLocale
    #if canImport(CoreText)
      self.appleVerifier = AppleEmojiSupportVerifier.shared
    #endif
  }

  internal func metadata() throws -> Metadata {
    let data = try loader.data(for: "metadata.json")
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    guard let metadata = try? decoder.decode(Metadata.self, from: data),
      metadata.schemaVersion > 0,
      !metadata.unicodeEmojiVersion.isEmpty,
      !metadata.cldrVersion.isEmpty,
      !metadata.defaultLocaleIdentifier.isEmpty
    else {
      throw EmojisError.invalidMetadata
    }

    return metadata
  }

  internal func fetch(locale: Locale?, filter: Emojis.Filter) throws -> [Emoji] {
    let metadata = try metadata()
    let localizationIndex = try localizationIndex()
    let resolvedLocale = try resolveLocaleIdentifier(
      requested: locale,
      metadata: metadata,
      localizationIndex: localizationIndex
    )
    let baseRecords = try baseEmojis()
    let localization = try localization(for: resolvedLocale)

    let localized =
      try baseRecords.map { record in
        guard let localizedEntry = localization.entries[record.id] else {
          throw EmojisError.missingLocalization(locale: resolvedLocale, emojiID: record.id)
        }

        return Emoji(
          id: .init(rawValue: record.id),
          value: record.value,
          group: .init(rawValue: record.group),
          subgroup: .init(rawValue: record.subgroup),
          unicodeVersion: record.unicodeVersion,
          sortOrder: record.sortOrder,
          skinToneSupport: record.skinToneSupport,
          skinToneVariants: record.skinToneVariants,
          localization: .init(
            localeIdentifier: localization.localeIdentifier,
            name: localizedEntry.name,
            searchTokens: localizedEntry.searchTokens
          )
        )
      }
      .sorted { $0.sortOrder < $1.sortOrder }

    switch filter {
    case .none:
      return localized
    case .custom(let predicate):
      return try localized.filter(predicate)
    #if canImport(CoreText)
      case .apple:
        do {
          return try appleVerifier.filter(localized, metadata: metadata)
        } catch let error as EmojisError {
          throw error
        } catch {
          throw EmojisError.appleVerificationFailed
        }
    #endif
    }
  }

  internal func searchIndex(locales: SearchLocaleSelection) throws -> SearchIndex {
    let metadata = try metadata()
    let localizationIndex = try localizationIndex()
    let baseRecords = try baseEmojis()

    let resolvedLocales: [String] =
      switch locales {
      case .all:
        localizationIndex.availableLocaleIdentifiers
      case .explicit(let locales):
        try resolveLocaleIdentifiers(
          requestedLocales: locales,
          metadata: metadata,
          available: localizationIndex.availableLocaleIdentifiers
        )
      }

    let localizations = try Dictionary(
      uniqueKeysWithValues: resolvedLocales.map { locale in
        (locale, try localization(for: locale))
      }
    )

    let entries = try baseRecords.map { record in
      let localizedEntries = try resolvedLocales.map { locale in
        guard let localized = localizations[locale]?.entries[record.id] else {
          throw EmojisError.missingLocalization(locale: locale, emojiID: record.id)
        }
        return Emoji.Localization(
          localeIdentifier: locale,
          name: localized.name,
          searchTokens: localized.searchTokens
        )
      }

      return SearchIndex.Entry(
        id: .init(rawValue: record.id),
        value: record.value,
        skinToneSupport: record.skinToneSupport,
        skinToneVariants: record.skinToneVariants,
        localizations: localizedEntries
      )
    }

    return SearchIndex(
      availableLocaleIdentifiers: resolvedLocales,
      entries: entries
    )
  }

  internal func localizationIndex() throws -> BundledLocalizationIndex {
    let data = try loader.data(for: "localizations/index.json")
    guard let index = try? JSONDecoder().decode(BundledLocalizationIndex.self, from: data) else {
      throw EmojisError.invalidLocalizationData("localizations/index.json")
    }
    return index
  }

  internal func baseEmojis() throws -> [BundledEmojiRecord] {
    let data = try loader.data(for: "emojis.json")
    guard let emojis = try? JSONDecoder().decode([BundledEmojiRecord].self, from: data) else {
      throw EmojisError.invalidEmojiData
    }
    return emojis
  }

  internal func localization(for localeIdentifier: String) throws -> BundledLocalizationFile {
    let path = "localizations/\(localeIdentifier).json"
    let data = try loader.data(for: path)
    guard let localization = try? JSONDecoder().decode(BundledLocalizationFile.self, from: data)
    else {
      throw EmojisError.invalidLocalizationData(path)
    }
    return localization
  }

  // Locale resolution uses a stable fallback chain so bundled locale lookup behaves the same
  // across Apple platforms and Linux.
  internal func resolveLocaleIdentifier(
    requested: Locale?,
    metadata: Metadata,
    localizationIndex: BundledLocalizationIndex
  ) throws -> String {
    let available = Set(localizationIndex.availableLocaleIdentifiers)
    let requestedLocale = requested ?? systemLocale()
    let candidates = EmojiLocaleResolver.candidates(for: requestedLocale.identifier)

    if let firstMatch = candidates.first(where: available.contains) {
      return firstMatch
    }

    if requested == nil {
      return metadata.defaultLocaleIdentifier
    }

    throw EmojisError.unsupportedLocale(
      requested: EmojiLocaleResolver.normalize(requestedLocale.identifier),
      available: localizationIndex.availableLocaleIdentifiers
    )
  }

  internal func resolveLocaleIdentifiers(
    requestedLocales: [Locale],
    metadata: Metadata,
    available: [String]
  ) throws -> [String] {
    var resolved: [String] = []
    let localizationIndex = BundledLocalizationIndex(
      defaultLocaleIdentifier: metadata.defaultLocaleIdentifier,
      availableLocaleIdentifiers: available
    )

    for locale in requestedLocales {
      let identifier = try resolveLocaleIdentifier(
        requested: locale,
        metadata: metadata,
        localizationIndex: localizationIndex
      )
      if !resolved.contains(identifier) {
        resolved.append(identifier)
      }
    }

    return resolved
  }
}

internal enum EmojiLocaleResolver {
  internal static func normalize(_ rawIdentifier: String) -> String {
    normalizedParts(from: rawIdentifier).identifier
  }

  internal static func candidates(for rawIdentifier: String) -> [String] {
    let normalized = normalizedParts(from: rawIdentifier)
    var candidates: [String] = []

    func append(_ value: String?) {
      guard let value, !value.isEmpty, !candidates.contains(value) else {
        return
      }
      candidates.append(value)
    }

    append(normalized.identifier)
    append(
      identifier(
        language: normalized.language, script: normalized.script, region: normalized.region))
    append(identifier(language: normalized.language, script: normalized.script, region: nil))
    append(identifier(language: normalized.language, script: nil, region: normalized.region))
    append(normalized.language)

    return candidates
  }

  private static func identifier(language: String, script: String?, region: String?) -> String {
    ([language, script, region].compactMap { $0 }).joined(separator: "-")
  }

  private static func normalizedParts(
    from rawIdentifier: String
  ) -> (
    identifier: String,
    language: String,
    script: String?,
    region: String?
  ) {
    let normalized = rawIdentifier.replacingOccurrences(of: "_", with: "-")
    let subtags = normalized.split(separator: "-").map(String.init)
    let language =
      if let first = subtags.first, !first.isEmpty {
        first.lowercased()
      } else {
        normalized.lowercased()
      }
    var script: String?
    var region: String?

    for subtag in subtags.dropFirst() {
      if script == nil, subtag.count == 4, subtag.allSatisfy(\.isLetter) {
        script = subtag.prefix(1).uppercased() + subtag.dropFirst().lowercased()
        continue
      }

      if region == nil,
        (subtag.count == 2 && subtag.allSatisfy(\.isLetter))
          || (subtag.count == 3 && subtag.allSatisfy(\.isNumber))
      {
        region = subtag.uppercased()
      }
    }

    let identifier = identifier(language: language, script: script, region: region)
    return (identifier, language, script, region)
  }
}

import Foundation

/// Loads bundled emoji metadata and localized emoji values.
public enum Emojis {
  /// Controls runtime filtering of localized emoji results.
  public enum Filter: Sendable {
    /// Returns every localized emoji bundled with the package.
    case none

    /// Applies a caller-supplied predicate after localization resolution.
    case custom(@Sendable (Emoji) throws -> Bool)

    #if canImport(CoreText)
      /// Filters results using an Apple-platform support heuristic backed by CoreText.
      case apple
    #endif
  }

  private static let catalog = EmojiCatalog(loader: BundleResourceLoader())

  /// Returns bundled dataset metadata.
  ///
  /// - Returns: The decoded package metadata.
  /// - Throws: ``EmojisError/missingBundledResource(_:)`` when the metadata resource is absent or
  ///   ``EmojisError/invalidMetadata`` when decoding fails.
  public static func metadata() throws -> Metadata {
    try catalog.metadata()
  }

  /// Returns localized emojis for the requested locale and filter.
  ///
  /// - Parameters:
  ///   - locale: The preferred locale. When `nil`, the runtime resolves the system locale and
  ///     falls back to the bundled default locale if needed.
  ///   - filter: The runtime filter to apply after localization resolution.
  /// - Returns: Localized emojis sorted by Unicode sort order.
  /// - Throws: ``EmojisError`` values for missing resources, invalid data, unsupported locales,
  ///   incomplete localizations, and Apple-only verification failures when that filter is used.
  public static func fetch(
    locale: Locale? = nil,
    filter: Filter = .none
  ) throws -> [Emoji] {
    try catalog.fetch(locale: locale, filter: filter)
  }

  /// Returns a multilingual search index built from the bundled locale files.
  ///
  /// - Parameter locales: The locales to include in the loaded index. `.all` loads every bundled
  ///   localization, while `.explicit` resolves and filters to the requested locales.
  /// - Returns: A search index containing locale-tagged search localizations.
  /// - Throws: ``EmojisError`` values for missing resources, invalid data, or unsupported locales.
  public static func searchIndex(
    locales: SearchLocaleSelection = .all
  ) throws -> SearchIndex {
    try catalog.searchIndex(locales: locales)
  }
}

/// Describes the bundled emoji dataset version and upstream sources.
public struct Metadata: Codable, Sendable, Equatable {
  /// Describes one upstream file used to produce the bundled dataset.
  public struct SourceFile: Codable, Sendable, Equatable {
    /// The upstream file name.
    public let name: String

    /// The upstream file URL.
    public let url: String

    /// The SHA-256 digest of the fetched file contents.
    public let sha256: String

    /// Creates a source-file record.
    ///
    /// - Parameters:
    ///   - name: The upstream file name.
    ///   - url: The upstream file URL.
    ///   - sha256: The SHA-256 digest of the fetched file contents.
    public init(name: String, url: String, sha256: String) {
      self.name = name
      self.url = url
      self.sha256 = sha256
    }
  }

  /// The resource schema version.
  public let schemaVersion: Int

  /// The Unicode emoji version used to generate the dataset.
  public let unicodeEmojiVersion: String

  /// The CLDR version used to generate localizations.
  public let cldrVersion: String

  /// The generation timestamp recorded by the CLI.
  public let generatedAt: Date

  /// The bundled fallback locale identifier.
  public let defaultLocaleIdentifier: String

  /// The bundled locale identifiers available at runtime.
  public let availableLocaleIdentifiers: [String]

  /// The upstream source files used to build the dataset.
  public let sourceFiles: [SourceFile]

  /// Creates metadata for a generated emoji dataset.
  ///
  /// - Parameters:
  ///   - schemaVersion: The resource schema version.
  ///   - unicodeEmojiVersion: The Unicode emoji version.
  ///   - cldrVersion: The CLDR version.
  ///   - generatedAt: The generation timestamp.
  ///   - defaultLocaleIdentifier: The fallback locale identifier.
  ///   - availableLocaleIdentifiers: The bundled locale identifiers.
  ///   - sourceFiles: The upstream source files.
  public init(
    schemaVersion: Int,
    unicodeEmojiVersion: String,
    cldrVersion: String,
    generatedAt: Date,
    defaultLocaleIdentifier: String,
    availableLocaleIdentifiers: [String],
    sourceFiles: [SourceFile]
  ) {
    self.schemaVersion = schemaVersion
    self.unicodeEmojiVersion = unicodeEmojiVersion
    self.cldrVersion = cldrVersion
    self.generatedAt = generatedAt
    self.defaultLocaleIdentifier = defaultLocaleIdentifier
    self.availableLocaleIdentifiers = availableLocaleIdentifiers
    self.sourceFiles = sourceFiles
  }
}

/// Represents one localized emoji record.
public struct Emoji: Codable, Sendable, Hashable {
  /// A stable identifier derived from the emoji scalar sequence.
  public struct ID: RawRepresentable, Codable, Hashable, Sendable {
    /// The normalized raw identifier value.
    public let rawValue: String

    /// Creates a stable emoji identifier.
    ///
    /// - Parameter rawValue: The normalized raw identifier value.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  /// The Unicode group name from `emoji-test.txt`.
  public struct Group: RawRepresentable, Codable, Hashable, Sendable {
    /// The raw group label.
    public let rawValue: String

    /// Creates a Unicode group wrapper.
    ///
    /// - Parameter rawValue: The raw group label.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// The `Smileys & Emotion` group.
    public static let smileysEmotion = Self(rawValue: "Smileys & Emotion")

    /// The `People & Body` group.
    public static let peopleBody = Self(rawValue: "People & Body")

    /// The `Component` group.
    public static let component = Self(rawValue: "Component")

    /// The `Animals & Nature` group.
    public static let animalsNature = Self(rawValue: "Animals & Nature")

    /// The `Food & Drink` group.
    public static let foodDrink = Self(rawValue: "Food & Drink")

    /// The `Travel & Places` group.
    public static let travelPlaces = Self(rawValue: "Travel & Places")

    /// The `Activities` group.
    public static let activities = Self(rawValue: "Activities")

    /// The `Objects` group.
    public static let objects = Self(rawValue: "Objects")

    /// The `Symbols` group.
    public static let symbols = Self(rawValue: "Symbols")

    /// The `Flags` group.
    public static let flags = Self(rawValue: "Flags")
  }

  /// The Unicode subgroup name from `emoji-test.txt`.
  public struct Subgroup: RawRepresentable, Codable, Hashable, Sendable {
    /// The raw subgroup label.
    public let rawValue: String

    /// Creates a Unicode subgroup wrapper.
    ///
    /// - Parameter rawValue: The raw subgroup label.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  /// Holds locale-specific strings for one emoji.
  public struct Localization: Codable, Sendable, Hashable {
    /// The locale identifier associated with the localized values.
    public let localeIdentifier: String

    /// The localized display name.
    public let name: String

    /// Stable localized search tokens for the emoji.
    public let searchTokens: [String]

    /// Creates localized emoji values.
    ///
    /// - Parameters:
    ///   - localeIdentifier: The locale identifier.
    ///   - name: The localized display name.
    ///   - searchTokens: Stable localized search tokens.
    public init(localeIdentifier: String, name: String, searchTokens: [String]) {
      self.localeIdentifier = localeIdentifier
      self.name = name
      self.searchTokens = searchTokens
    }
  }

  /// The supported Unicode skin-tone modifiers for tone-capable emoji variants.
  public enum SkinTone: String, Codable, Sendable, Hashable, CaseIterable {
    /// Fitzpatrick type 1-2.
    case light

    /// Fitzpatrick type 3.
    case mediumLight

    /// Fitzpatrick type 4.
    case medium

    /// Fitzpatrick type 5.
    case mediumDark

    /// Fitzpatrick type 6.
    case dark
  }

  /// Describes whether an emoji supports no, single-slot, or multi-slot skin-tone variants.
  public enum SkinToneSupport: String, Codable, Sendable, Hashable {
    /// The emoji does not provide skin-tone variants.
    case none

    /// The emoji provides one tone slot per variant.
    case single

    /// The emoji provides multiple ordered tone slots per variant.
    case multiple
  }

  /// One concrete tone-modified Unicode sequence for a logical emoji entry.
  public struct SkinToneVariant: Codable, Sendable, Hashable {
    /// The stable identifier for the concrete tone-modified sequence.
    public let id: ID

    /// The concrete tone-modified emoji sequence.
    public let value: String

    /// The ordered tones applied by this variant.
    public let tones: [SkinTone]

    /// Creates a tone-modified emoji variant.
    ///
    /// - Parameters:
    ///   - id: The stable identifier for the concrete tone-modified sequence.
    ///   - value: The concrete tone-modified emoji sequence.
    ///   - tones: The ordered tones applied by this variant.
    public init(id: ID, value: String, tones: [SkinTone]) {
      self.id = id
      self.value = value
      self.tones = tones
    }
  }

  /// The stable identifier for the emoji sequence.
  public let id: ID

  /// The canonical emoji sequence string.
  public let value: String

  /// The Unicode group label.
  public let group: Group

  /// The Unicode subgroup label.
  public let subgroup: Subgroup

  /// The Unicode emoji version from the source catalog.
  public let unicodeVersion: String

  /// The source sort order from `emoji-test.txt`.
  public let sortOrder: Int

  /// Whether the emoji supports no, single-slot, or multi-slot skin-tone variants.
  public let skinToneSupport: SkinToneSupport

  /// The concrete tone-modified Unicode sequences for this logical emoji entry.
  public let skinToneVariants: [SkinToneVariant]

  /// The localized strings associated with this emoji.
  public let localization: Localization

  /// Creates a localized emoji record.
  ///
  /// - Parameters:
  ///   - id: The stable emoji identifier.
  ///   - value: The canonical emoji sequence string.
  ///   - group: The Unicode group.
  ///   - subgroup: The Unicode subgroup.
  ///   - unicodeVersion: The Unicode emoji version.
  ///   - sortOrder: The Unicode sort order.
  ///   - skinToneSupport: The skin-tone support mode for the logical entry.
  ///   - skinToneVariants: The concrete tone-modified Unicode sequences for the logical entry.
  ///   - localization: The localized strings.
  public init(
    id: ID,
    value: String,
    group: Group,
    subgroup: Subgroup,
    unicodeVersion: String,
    sortOrder: Int,
    skinToneSupport: SkinToneSupport,
    skinToneVariants: [SkinToneVariant],
    localization: Localization
  ) {
    self.id = id
    self.value = value
    self.group = group
    self.subgroup = subgroup
    self.unicodeVersion = unicodeVersion
    self.sortOrder = sortOrder
    self.skinToneSupport = skinToneSupport
    self.skinToneVariants = skinToneVariants
    self.localization = localization
  }
}

/// Selects which locale localizations should be loaded into the search index.
public enum SearchLocaleSelection: Sendable, Equatable {
  /// Loads every bundled search localization.
  case all

  /// Loads only the explicitly requested locales after locale resolution.
  case explicit([Locale])
}

/// A multilingual emoji search index.
public struct SearchIndex: Codable, Sendable, Equatable {
  /// One search-index entry for an emoji.
  public struct Entry: Codable, Sendable, Hashable {
    /// The stable emoji identifier.
    public let id: Emoji.ID

    /// The canonical emoji sequence string.
    public let value: String

    /// Whether the logical emoji entry supports no, single-slot, or multi-slot skin-tone
    /// variants.
    public let skinToneSupport: Emoji.SkinToneSupport

    /// The concrete tone-modified Unicode sequences for the logical emoji entry.
    public let skinToneVariants: [Emoji.SkinToneVariant]

    /// Locale-tagged names and search tokens for this emoji.
    public let localizations: [Emoji.Localization]

    /// Creates a search-index entry.
    ///
    /// - Parameters:
    ///   - id: The stable emoji identifier.
    ///   - value: The canonical emoji sequence string.
    ///   - skinToneSupport: The skin-tone support mode for the logical entry.
    ///   - skinToneVariants: The concrete tone-modified Unicode sequences for the logical entry.
    ///   - localizations: Locale-tagged names and search tokens.
    public init(
      id: Emoji.ID,
      value: String,
      skinToneSupport: Emoji.SkinToneSupport,
      skinToneVariants: [Emoji.SkinToneVariant],
      localizations: [Emoji.Localization]
    ) {
      self.id = id
      self.value = value
      self.skinToneSupport = skinToneSupport
      self.skinToneVariants = skinToneVariants
      self.localizations = localizations
    }
  }

  /// The bundled locale identifiers present in the index.
  public let availableLocaleIdentifiers: [String]

  /// The search-index entries sorted by emoji sort order.
  public let entries: [Entry]

  /// Creates a multilingual emoji search index.
  ///
  /// - Parameters:
  ///   - availableLocaleIdentifiers: The bundled locale identifiers.
  ///   - entries: The search-index entries.
  public init(availableLocaleIdentifiers: [String], entries: [Entry]) {
    self.availableLocaleIdentifiers = availableLocaleIdentifiers
    self.entries = entries
  }
}

/// Describes runtime errors thrown by the bundled emoji loader.
public enum EmojisError: Error, Sendable, Equatable {
  /// A required bundled resource file was not found.
  case missingBundledResource(String)

  /// `metadata.json` could not be decoded or validated.
  case invalidMetadata

  /// `emojis.json` could not be decoded or validated.
  case invalidEmojiData

  /// A locale resource file could not be decoded.
  case invalidLocalizationData(String)

  /// The requested explicit locale is not bundled.
  case unsupportedLocale(requested: String, available: [String])

  /// A bundled locale file does not contain one of the shipped emoji IDs.
  case missingLocalization(locale: String, emojiID: String)

  #if canImport(CoreText)
    /// Apple-only verification support could not be initialized.
    case appleVerificationUnavailable

    /// Apple-only verification failed unexpectedly.
    case appleVerificationFailed
  #endif
}

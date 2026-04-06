import Foundation
import Testing

@testable import Emojis

@Test func metadataDecodesFromFixtureResources() throws {
  let metadata = try testCatalog().metadata()

  #expect(metadata.schemaVersion == 2)
  #expect(metadata.defaultLocaleIdentifier == "en")
  #expect(metadata.availableLocaleIdentifiers == ["cs", "de", "en"])
}

@Test func fetchResolvesLanguageFallback() throws {
  let catalog = try testCatalog()

  let emojis = try catalog.fetch(locale: Locale(identifier: "de-AT"), filter: .none)

  #expect(emojis.count == 4)
  #expect(emojis.first?.localization.localeIdentifier == "de")
  #expect(emojis.first?.localization.name == "grinsendes gesicht")
}

@Test func fetchResolvesEnglishRegionalVariantToBundledEnglish() throws {
  let catalog = try testCatalog()

  let emojis = try catalog.fetch(locale: Locale(identifier: "en-GB"), filter: .none)

  #expect(emojis.first?.localization.localeIdentifier == "en")
  #expect(emojis.first?.localization.name == "grinning face")
}

@Test func explicitUnsupportedLocaleThrows() throws {
  let catalog = try testCatalog()

  #expect(throws: EmojisError.unsupportedLocale(requested: "fr-FR", available: ["cs", "de", "en"]))
  {
    try catalog.fetch(locale: Locale(identifier: "fr-FR"), filter: .none)
  }
}

@Test func unsupportedSystemLocaleFallsBackToDefaultLocale() throws {
  let catalog = try testCatalog(systemLocale: Locale(identifier: "fr-FR"))

  let emojis = try catalog.fetch(locale: nil, filter: .none)

  #expect(emojis.first?.localization.localeIdentifier == "en")
}

@Test func missingLocalizationEntryThrows() throws {
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601

  let metadata = Metadata(
    schemaVersion: 2,
    unicodeEmojiVersion: "17.0",
    cldrVersion: "47",
    generatedAt: Date(timeIntervalSince1970: 0),
    defaultLocaleIdentifier: "en",
    availableLocaleIdentifiers: ["en"],
    sourceFiles: []
  )
  let emojis = [
    BundledEmojiRecord(
      id: "1F600",
      value: "😀",
      group: "Smileys & Emotion",
      subgroup: "face-smiling",
      unicodeVersion: "6.1",
      sortOrder: 1,
      skinToneSupport: .none,
      skinToneVariants: []
    )
  ]
  let resources: [String: Data] = [
    "metadata.json": try encoder.encode(metadata),
    "emojis.json": try JSONEncoder().encode(emojis),
    "localizations/index.json": try JSONEncoder()
      .encode(
        BundledLocalizationIndex(defaultLocaleIdentifier: "en", availableLocaleIdentifiers: ["en"])
      ),
    "localizations/en.json": try JSONEncoder()
      .encode(
        BundledLocalizationFile(localeIdentifier: "en", entries: [:])
      )
  ]
  let catalog = EmojiCatalog(loader: InMemoryResourceLoader(resources: resources))

  #expect(throws: EmojisError.missingLocalization(locale: "en", emojiID: "1F600")) {
    try catalog.fetch(locale: Locale(identifier: "en"), filter: .none)
  }
}

@Test func customFilterRunsAfterLocalization() throws {
  let catalog = try testCatalog()

  let emojis = try catalog.fetch(
    locale: Locale(identifier: "cs"),
    filter: .custom { $0.localization.name.contains("hvězda") }
  )

  #expect(emojis.count == 1)
  #expect(emojis.first?.value == "⭐")
}

@Test func fetchCollapsesSkinToneVariantsIntoLogicalEmoji() throws {
  let catalog = try testCatalog()

  let emojis = try catalog.fetch(locale: Locale(identifier: "en"), filter: .none)
  let thumbsUp = try #require(emojis.first(where: { $0.id.rawValue == "1F44D" }))
  let handshake = try #require(emojis.first(where: { $0.id.rawValue == "1F91D" }))

  #expect(thumbsUp.skinToneSupport == .single)
  #expect(thumbsUp.skinToneVariants.map(\.tones) == [[.light], [.dark]])
  #expect(handshake.skinToneSupport == .multiple)
  #expect(handshake.skinToneVariants.map(\.tones) == [[.light, .light], [.medium, .dark]])
}

@Test func searchIndexLoadsAllLocalizations() throws {
  let catalog = try testCatalog()

  let index = try catalog.searchIndex(locales: .all)

  #expect(index.availableLocaleIdentifiers == ["cs", "de", "en"])
  #expect(index.entries.count == 4)
  #expect(index.entries.first?.localizations.map(\.localeIdentifier) == ["cs", "de", "en"])
}

@Test func searchIndexResolvesExplicitLocalesAndDeduplicatesMatches() throws {
  let catalog = try testCatalog()

  let index = try catalog.searchIndex(
    locales: .explicit([
      Locale(identifier: "en-GB"),
      Locale(identifier: "en"),
      Locale(identifier: "de-AT")
    ])
  )

  #expect(index.availableLocaleIdentifiers == ["en", "de"])
  #expect(index.entries.first?.localizations.map(\.localeIdentifier) == ["en", "de"])
}

@Test func searchIndexCarriesSkinToneVariantsOnLogicalEntries() throws {
  let catalog = try testCatalog()

  let index = try catalog.searchIndex(locales: .all)
  let thumbsUp = try #require(index.entries.first(where: { $0.id.rawValue == "1F44D" }))
  let handshake = try #require(index.entries.first(where: { $0.id.rawValue == "1F91D" }))

  #expect(thumbsUp.skinToneSupport == .single)
  #expect(thumbsUp.skinToneVariants.map(\.tones) == [[.light], [.dark]])
  #expect(handshake.skinToneSupport == .multiple)
  #expect(handshake.skinToneVariants.map(\.tones) == [[.light, .light], [.medium, .dark]])
}

@Test func knownGroupsAndUnknownGroupsRoundTrip() throws {
  let known = try JSONDecoder().decode(Emoji.Group.self, from: Data(#""Smileys & Emotion""#.utf8))
  let unknown = try JSONDecoder().decode(Emoji.Group.self, from: Data(#""Custom Group""#.utf8))
  let subgroup = try JSONDecoder().decode(Emoji.Subgroup.self, from: Data(#""face-smiling""#.utf8))
  let tone = try JSONDecoder().decode(Emoji.SkinTone.self, from: Data(#""mediumDark""#.utf8))

  #expect(known == .smileysEmotion)
  #expect(unknown.rawValue == "Custom Group")
  #expect(subgroup.rawValue == "face-smiling")
  #expect(tone == .mediumDark)
}

private func testCatalog(systemLocale: Locale = Locale(identifier: "en")) throws -> EmojiCatalog {
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601

  let metadata = Metadata(
    schemaVersion: 2,
    unicodeEmojiVersion: "17.0",
    cldrVersion: "47",
    generatedAt: Date(timeIntervalSince1970: 0),
    defaultLocaleIdentifier: "en",
    availableLocaleIdentifiers: ["cs", "de", "en"],
    sourceFiles: []
  )
  let emojis = [
    BundledEmojiRecord(
      id: "1F600",
      value: "😀",
      group: "Smileys & Emotion",
      subgroup: "face-smiling",
      unicodeVersion: "6.1",
      sortOrder: 1,
      skinToneSupport: .none,
      skinToneVariants: []
    ),
    BundledEmojiRecord(
      id: "2B50",
      value: "⭐",
      group: "Objects",
      subgroup: "light & video",
      unicodeVersion: "5.1",
      sortOrder: 2,
      skinToneSupport: .none,
      skinToneVariants: []
    ),
    BundledEmojiRecord(
      id: "1F44D",
      value: "👍",
      group: "People & Body",
      subgroup: "hand-fingers-closed",
      unicodeVersion: "0.6",
      sortOrder: 3,
      skinToneSupport: .single,
      skinToneVariants: [
        .init(id: .init(rawValue: "1F44D-1F3FB"), value: "👍🏻", tones: [.light]),
        .init(id: .init(rawValue: "1F44D-1F3FF"), value: "👍🏿", tones: [.dark])
      ]
    ),
    BundledEmojiRecord(
      id: "1F91D",
      value: "🤝",
      group: "People & Body",
      subgroup: "handshake",
      unicodeVersion: "3.0",
      sortOrder: 4,
      skinToneSupport: .multiple,
      skinToneVariants: [
        .init(
          id: .init(rawValue: "1FAF1-1F3FB-200D-1FAF2-1F3FB"),
          value: "🫱🏻‍🫲🏻",
          tones: [.light, .light]
        ),
        .init(
          id: .init(rawValue: "1FAF1-1F3FD-200D-1FAF2-1F3FF"),
          value: "🫱🏽‍🫲🏿",
          tones: [.medium, .dark]
        )
      ]
    )
  ]

  func localization(_ locale: String, _ values: [String: (String, [String])]) throws -> Data {
    try JSONEncoder()
      .encode(
        BundledLocalizationFile(
          localeIdentifier: locale,
          entries: values.reduce(into: [:]) { result, pair in
            result[pair.key] = BundledLocalizationEntry(
              name: pair.value.0, searchTokens: pair.value.1)
          }
        )
      )
  }

  let resources: [String: Data] = [
    "metadata.json": try encoder.encode(metadata),
    "emojis.json": try JSONEncoder().encode(emojis),
    "localizations/index.json": try JSONEncoder()
      .encode(
        BundledLocalizationIndex(
          defaultLocaleIdentifier: "en", availableLocaleIdentifiers: ["cs", "de", "en"])
      ),
    "localizations/en.json": try localization(
      "en",
      [
        "1F600": ("grinning face", ["face", "grin"]),
        "2B50": ("star", ["star"]),
        "1F44D": ("thumbs up", ["thumbs", "up"]),
        "1F91D": ("handshake", ["handshake"])
      ]
    ),
    "localizations/de.json": try localization(
      "de",
      [
        "1F600": ("grinsendes gesicht", ["gesicht"]),
        "2B50": ("stern", ["stern"]),
        "1F44D": ("daumen hoch", ["daumen", "hoch"]),
        "1F91D": ("handschlag", ["handschlag"])
      ]
    ),
    "localizations/cs.json": try localization(
      "cs",
      [
        "1F600": ("šklebící se obličej", ["obličej"]),
        "2B50": ("hvězda", ["hvězda"]),
        "1F44D": ("palec nahoru", ["palec", "nahoru"]),
        "1F91D": ("podání ruky", ["podání", "ruky"])
      ]
    )
  ]

  return EmojiCatalog(
    loader: InMemoryResourceLoader(resources: resources),
    systemLocale: { systemLocale }
  )
}

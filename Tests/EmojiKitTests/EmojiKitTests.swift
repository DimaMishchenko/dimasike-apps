import Foundation
import Testing

@testable import EmojiKit

@Suite struct EmojiKitTests {
  @Test func localeSelectionParsesAll() throws {
    #expect(try LocaleSelection(argument: nil) == .explicit(["en"]))
    #expect(try LocaleSelection(argument: "all") == .all)
  }

  @Test func localeSelectionParsesExplicitList() throws {
    #expect(try LocaleSelection(argument: "cs,de") == .explicit(["en", "cs", "de"]))
  }

  @Test func outputPathsUseRootAndOverrides() throws {
    let derived = try CLIOutputPaths(
      outputRoot: "/tmp/out",
      metadataPath: nil,
      emojisPath: nil,
      localizationsPath: nil
    )
    let overridden = try CLIOutputPaths(
      outputRoot: "/tmp/out",
      metadataPath: "/tmp/custom/meta.json",
      emojisPath: "/tmp/custom/emojis.json",
      localizationsPath: "/tmp/custom/localizations"
    )

    #expect(derived.metadataPath == "/tmp/out/metadata.json")
    #expect(derived.emojisPath == "/tmp/out/emojis.json")
    #expect(derived.localizationsPath == "/tmp/out/localizations")
    #expect(overridden.metadataPath == "/tmp/custom/meta.json")
    #expect(overridden.emojisPath == "/tmp/custom/emojis.json")
    #expect(overridden.localizationsPath == "/tmp/custom/localizations")
  }

  @Test func normalizeIDsFromScalars() {
    #expect(UnicodeEmojiParser.normalizeID(from: ["1f469", "200d", "1f4bb"]) == "1F469-200D-1F4BB")
  }

  @Test func parseEmojiTestFixture() throws {
    let fixture = """
      # group: Smileys & Emotion
      # subgroup: face-smiling
      1F600                                                  ; fully-qualified     # 😀 E6.1 grinning face
      # group: Objects
      # subgroup: light & video
      2B50                                                   ; fully-qualified     # ⭐ E5.1 star
      """

    let emojis = try UnicodeEmojiParser.parseEmojiTest(Data(fixture.utf8))

    #expect(emojis.map(\.id) == ["1F600", "2B50"])
    #expect(emojis.map(\.sortOrder) == [1, 2])
    #expect(emojis.last?.group == "Objects")
    #expect(emojis.first?.fallbackName == "grinning face")
  }

  @Test func parseEmojiTestCollapsesSkinToneVariantsIntoLogicalEntries() throws {
    let fixture = """
      # group: People & Body
      # subgroup: hand-fingers-closed
      1F44D                                                  ; fully-qualified     # 👍 E0.6 thumbs up
      1F44D 1F3FB                                            ; fully-qualified     # 👍🏻 E1.0 thumbs up: light skin tone
      1F44D 1F3FF                                            ; fully-qualified     # 👍🏿 E1.0 thumbs up: dark skin tone
      # subgroup: handshake
      1F91D                                                  ; fully-qualified     # 🤝 E3.0 handshake
      1FAF1 1F3FB 200D 1FAF2 1F3FB                           ; fully-qualified     # 🫱🏻‍🫲🏻 E14.0 handshake: light skin tone, light skin tone
      1FAF1 1F3FD 200D 1FAF2 1F3FF                           ; fully-qualified     # 🫱🏽‍🫲🏿 E14.0 handshake: medium skin tone, dark skin tone
      """

    let emojis = try UnicodeEmojiParser.parseEmojiTest(Data(fixture.utf8))
    let thumbsUp = try #require(emojis.first(where: { $0.id == "1F44D" }))
    let handshake = try #require(emojis.first(where: { $0.id == "1F91D" }))

    #expect(emojis.count == 2)
    #expect(thumbsUp.skinToneSupport == .single)
    #expect(thumbsUp.skinToneVariants.map(\.tones) == [[.light], [.dark]])
    #expect(handshake.skinToneSupport == .multiple)
    #expect(handshake.skinToneVariants.map(\.tones) == [[.light, .light], [.medium, .dark]])
  }

  @Test func generatedSkinToneVariantEncodesRawValueShape() throws {
    let data = try JSONEncoder()
      .encode(
        GeneratedSkinToneVariant(
          id: .init(rawValue: "1F44D-1F3FB"),
          value: "👍🏻",
          tones: [.light]
        )
      )

    #expect(String(decoding: data, as: UTF8.self).contains(#""id":"1F44D-1F3FB""#))
  }

  @Test func parseAvailableLocalesFixture() throws {
    let fixture = """
      {
        "availableLocales": {
          "full": ["de", "en", "cs"]
        }
      }
      """

    let locales = try CLDRParser.availableLocales(from: Data(fixture.utf8))

    #expect(locales == ["cs", "de", "en"])
  }

  @Test func parseLocalizationFixture() throws {
    let fixture = #"""
      {
        "annotations": {
          "annotations": {
            "😀": {
              "default": ["face", "grin"],
              "tts": "grinning face"
            }
          }
        }
      }
      """#

    let localization = try CLDRParser.parseLocalization(data: Data(fixture.utf8), locale: "en")

    #expect(localization["1F600"]?.name == "grinning face")
    #expect(localization["1F600"]?.searchTokens == ["face", "grin"])
  }

  @Test func unicodeReleaseResolverFindsLatestVersionFromDirectoryListing() throws {
    let html = """
      <html>
        <a href="15.1/">15.1/</a>
        <a href="16.0/">16.0/</a>
        <a href="14.0/">14.0/</a>
      </html>
      """

    let version = try UnicodeReleaseResolver.latestVersion(fromDirectoryListingHTML: html)

    #expect(version == "16.0")
  }

  @Test func cldrReleaseResolverFindsLatestTagFromTagsJSON() throws {
    let json = """
      [
        { "name": "46.1.0" },
        { "name": "47.0.0" },
        { "name": "45.0.0" }
      ]
      """

    let tag = try CLDRReleaseResolver.latestTag(fromTagsJSON: Data(json.utf8))

    #expect(tag == "47.0.0")
    #expect(CLDRReleaseResolver.version(fromTag: tag) == "47")
  }

  @Test func fetchUnicodeSourceFilesIgnoresMissingOptionalValidationFiles() async throws {
    let release = EmojiDataRelease(
      unicodeEmojiVersion: "16.0",
      cldrVersion: "47",
      cldrTag: "47.0.0"
    )
    let fetcher = EmojiDataLoader(
      httpClient: StubHTTPClient(
        responses: [
          release.unicodeBaseURL.appending(path: "emoji-test.txt").absoluteString: .success("test"),
          release.unicodeBaseURL.appending(path: "emoji-sequences.txt").absoluteString: .failure(
            404),
          release.unicodeBaseURL.appending(path: "emoji-zwj-sequences.txt").absoluteString:
            .success(
              "zwj"
            ),
          release.unicodeBaseURL.appending(path: "emoji-variation-sequences.txt").absoluteString:
            .failure(404),
          release.unicodeBaseURL.appending(path: "emoji-data.txt").absoluteString: .failure(404)
        ]
      )
    )

    let files = try await fetcher.fetchUnicodeSourceFiles(release: release)

    #expect(files.map(\.name) == ["emoji-test.txt", "emoji-zwj-sequences.txt"])
  }

  @Test func fetchAvailableLocalesUsesAnnotationLocaleCoverage() async throws {
    let release = EmojiDataRelease(
      unicodeEmojiVersion: "16.0",
      cldrVersion: "47",
      cldrTag: "47.0.0"
    )
    let fetcher = EmojiDataLoader(
      httpClient: StubHTTPClient(
        responses: [
          EmojiDataSource.cldrContentsURL(
            package: "cldr-annotations-full",
            directory: "annotations",
            tag: release.cldrTag
          )
          .absoluteString: .success(
            """
            [
              { "name": "en", "type": "dir" },
              { "name": "de", "type": "dir" }
            ]
            """
          ),
          EmojiDataSource.cldrContentsURL(
            package: "cldr-annotations-derived-full",
            directory: "annotationsDerived",
            tag: release.cldrTag
          )
          .absoluteString: .success(
            """
            [
              { "name": "en", "type": "dir" },
              { "name": "cs", "type": "dir" }
            ]
            """
          )
        ]
      )
    )

    let locales = try await fetcher.fetchAvailableLocales(release: release)

    #expect(locales == ["cs", "de", "en"])
  }

  @Test func fetchLocalizationSourcesAllowsDerivedOnlyLocale() async throws {
    let release = EmojiDataRelease(
      unicodeEmojiVersion: "16.0",
      cldrVersion: "47",
      cldrTag: "47.0.0"
    )
    let fetcher = EmojiDataLoader(
      httpClient: StubHTTPClient(
        responses: [
          release.cldrBaseURL
            .appending(path: "cldr-annotations-full/annotations/aa/annotations.json")
            .absoluteString: .failure(404),
          release.cldrBaseURL
            .appending(path: "cldr-annotations-derived-full/annotationsDerived/aa/annotations.json")
            .absoluteString: .success(
              """
              { "annotations": { "annotations": {} } }
              """
            )
        ]
      )
    )

    let files = try await fetcher.fetchLocalizationSources(locale: "aa", release: release)

    #expect(files.count == 1)
    #expect(files.first?.url.absoluteString.contains("cldr-annotations-derived-full") == true)
  }

  @Test func keycapEmojiUsesBaseCharacterLocalizationFallback() throws {
    let generator = EmojiGenerator()
    let direct = [
      "0023": GeneratedLocalizationEntry(name: "hash sign", searchTokens: ["hash", "sign"])
    ]

    let merged = try generator.mergeLocalizations(
      direct: direct,
      derived: [:],
      locale: "en",
      emojiIDs: ["0023-FE0F-20E3"]
    )

    #expect(merged["0023-FE0F-20E3"]?.name == "hash sign")
  }

  @Test func effectiveLocalizationFallsBackToEnglish() throws {
    let generator = EmojiGenerator()
    let emoji = GeneratedBaseEmoji(
      id: "1F600",
      value: "😀",
      group: "Smileys & Emotion",
      subgroup: "face-smiling",
      unicodeVersion: "6.1",
      sortOrder: 1,
      fallbackName: "grinning face"
    )

    let effective = try generator.effectiveLocalization(
      for: emoji,
      locale: "de",
      direct: [:],
      derived: [:],
      english: GeneratedLocalizationEntry(name: "grinning face", searchTokens: ["face", "grin"])
    )

    #expect(effective.name == "grinning face")
    #expect(effective.searchTokens == ["face", "grin", "grinning face"])
  }

  @Test func effectiveLocalizationSynthesizesFallbackWhenEnglishIsMissing() throws {
    let generator = EmojiGenerator()
    let emoji = GeneratedBaseEmoji(
      id: "1F600",
      value: "😀",
      group: "Smileys & Emotion",
      subgroup: "face-smiling",
      unicodeVersion: "6.1",
      sortOrder: 1,
      fallbackName: "grinning face"
    )

    let effective = try generator.effectiveLocalization(
      for: emoji,
      locale: "en",
      direct: [:],
      derived: [:],
      english: nil
    )

    #expect(effective.name == "grinning face")
    #expect(effective.searchTokens.contains("grinning face"))
    #expect(effective.searchTokens.contains("face"))
  }

  @Test func writerSkipsUnchangedBytesAndForcesRewrite() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let paths = try CLIOutputPaths(
      outputRoot: directory.path,
      metadataPath: nil,
      emojisPath: nil,
      localizationsPath: nil
    )
    let bundle = GeneratedBundle(
      metadata: GeneratedMetadata(
        schemaVersion: 2,
        unicodeEmojiVersion: "17.0",
        cldrVersion: "47",
        generatedAt: Date(timeIntervalSince1970: 0),
        defaultLocaleIdentifier: "en",
        availableLocaleIdentifiers: ["en"],
        sourceFiles: []
      ),
      emojis: [
        GeneratedBaseEmoji(
          id: "1F600",
          value: "😀",
          group: "Smileys & Emotion",
          subgroup: "face-smiling",
          unicodeVersion: "6.1",
          sortOrder: 1,
          skinToneSupport: .none,
          skinToneVariants: []
        )
      ],
      localizations: [
        "en": GeneratedLocalizationFile(
          localeIdentifier: "en",
          entries: [
            "1F600": GeneratedLocalizationEntry(
              name: "grinning face", searchTokens: ["face", "grin"])
          ]
        )
      ]
    )
    let writer = BundleWriter()

    let first = try writer.write(bundle: bundle, paths: paths, force: false, dryRun: false)
    let second = try writer.write(bundle: bundle, paths: paths, force: false, dryRun: false)
    let forced = try writer.write(bundle: bundle, paths: paths, force: true, dryRun: false)

    #expect(first.changedFiles.count == 4)
    #expect(second.changedFiles.isEmpty)
    #expect(forced.changedFiles.count == 4)
  }

  @Test func fetchLatestCommandParsesLocalesOption() throws {
    let command = try #require(
      try FetchLatestCommand.parseAsRoot(["--locales", "en,cs", "--dry-run"])
        as? FetchLatestCommand
    )

    #expect(command.locales == "en,cs")
    #expect(command.dryRun)
  }
}

private struct StubHTTPClient: HTTPDataLoading {
  enum Response {
    case success(String)
    case failure(Int)
  }

  let responses: [String: Response]

  func get(_ url: URL) async throws -> (Data, URLResponse) {
    guard let response = responses[url.absoluteString] else {
      throw NSError(
        domain: "StubHTTPClient",
        code: 1,
        userInfo: [
          NSLocalizedDescriptionKey: "Missing stub response for \(url.absoluteString)"
        ]
      )
    }

    switch response {
    case .success(let body):
      return (
        Data(body.utf8),
        try #require(
          HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
          )
        )
      )
    case .failure(let statusCode):
      return (
        Data(),
        try #require(
          HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
          )
        )
      )
    }
  }
}

import ArgumentParser
import Crypto
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

private struct HTTPStatusError: Error, Sendable {
  let statusCode: Int
  let url: URL
}

internal protocol HTTPDataLoading: Sendable {
  func get(_ url: URL) async throws -> (Data, URLResponse)
}

internal struct URLSessionHTTPClient: HTTPDataLoading {
  internal func get(_ url: URL) async throws -> (Data, URLResponse) {
    try await URLSession.shared.data(from: url)
  }
}

internal struct EmojiDataLoader {
  private let httpClient: any HTTPDataLoading

  internal init(httpClient: any HTTPDataLoading = URLSessionHTTPClient()) {
    self.httpClient = httpClient
  }

  internal func fetchLatestRelease() async throws -> EmojiDataRelease {
    let unicodeListing = try await fetch(url: EmojiDataSource.unicodeDirectoryURL)
    let unicodeVersion = try UnicodeReleaseResolver.latestVersion(
      fromDirectoryListingHTML: String(decoding: unicodeListing.data, as: UTF8.self)
    )
    let cldrTags = try await fetch(url: EmojiDataSource.cldrTagsURL)
    let cldrTag = try CLDRReleaseResolver.latestTag(fromTagsJSON: cldrTags.data)
    return EmojiDataRelease(
      unicodeEmojiVersion: unicodeVersion,
      cldrVersion: CLDRReleaseResolver.version(fromTag: cldrTag),
      cldrTag: cldrTag
    )
  }

  internal func fetchAvailableLocales(release: EmojiDataRelease) async throws -> [String] {
    let direct = try await optionalFile(
      at: EmojiDataSource.cldrContentsURL(
        package: "cldr-annotations-full",
        directory: "annotations",
        tag: release.cldrTag
      )
    )
    let derived = try await optionalFile(
      at: EmojiDataSource.cldrContentsURL(
        package: "cldr-annotations-derived-full",
        directory: "annotationsDerived",
        tag: release.cldrTag
      )
    )

    let directLocales =
      try direct.map { try CLDRReleaseResolver.localeIdentifiers(fromContentsJSON: $0.data) } ?? []
    let derivedLocales =
      try derived.map { try CLDRReleaseResolver.localeIdentifiers(fromContentsJSON: $0.data) } ?? []
    let locales = Set(directLocales).union(derivedLocales)
    guard !locales.isEmpty else {
      throw ValidationError("Unable to resolve available CLDR annotation locales.")
    }
    return locales.sorted()
  }

  internal func fetchUnicodeSourceFiles(release: EmojiDataRelease) async throws -> [EmojiDataFile] {
    let required = try await fetch(url: release.unicodeBaseURL.appending(path: "emoji-test.txt"))
    let optionalNames = [
      "emoji-sequences.txt",
      "emoji-zwj-sequences.txt",
      "emoji-variation-sequences.txt",
      "emoji-data.txt"
    ]

    var optionalFiles: [EmojiDataFile] = []
    for name in optionalNames {
      if let file = try await optionalFile(at: release.unicodeBaseURL.appending(path: name)) {
        optionalFiles.append(file)
      }
    }

    return [required] + optionalFiles
  }

  internal func fetchLocalizationSources(
    locale: String,
    release: EmojiDataRelease
  ) async throws -> [EmojiDataFile] {
    let annotationPaths = [
      "cldr-annotations-full/annotations/\(locale)/annotations.json",
      "cldr-annotations-derived-full/annotationsDerived/\(locale)/annotations.json"
    ]

    var files: [EmojiDataFile] = []
    for relativePath in annotationPaths {
      if let file = try await optionalFile(at: release.cldrBaseURL.appending(path: relativePath)) {
        files.append(file)
      }
    }

    guard !files.isEmpty else {
      throw ValidationError(
        "No localization annotation files were found for locale \(locale)."
      )
    }

    return files
  }

  internal func fetch(url: URL) async throws -> EmojiDataFile {
    let payload = try await httpClient.get(url)

    if let response = payload.1 as? HTTPURLResponse, response.statusCode == 404 {
      throw HTTPStatusError(statusCode: response.statusCode, url: url)
    }

    if let response = payload.1 as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
      throw ValidationError(
        "Request failed with status \(response.statusCode): \(url.absoluteString)"
      )
    }

    return EmojiDataFile(
      name: url.lastPathComponent,
      url: url,
      data: payload.0,
      sha256: payload.0.sha256HexString
    )
  }

  internal func optionalFile(at url: URL) async throws -> EmojiDataFile? {
    do {
      return try await fetch(url: url)
    } catch let error as HTTPStatusError where error.statusCode == 404 {
      return nil
    } catch {
      throw error
    }
  }
}

private extension Data {
  var sha256HexString: String {
    SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined()
  }
}

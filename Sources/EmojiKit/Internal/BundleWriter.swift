import ArgumentParser
import Foundation

internal struct BundleWriter {
  private let fileManager: FileManager

  internal init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  internal func write(
    bundle: GeneratedBundle,
    paths: CLIOutputPaths,
    force: Bool,
    dryRun: Bool
  ) throws -> WriteSummary {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let metadataData = try encoded(bundle.metadata, encoder: encoder)
    let emojisData = try encoded(bundle.emojis, encoder: encoder)
    let indexData = try encoded(
      GeneratedLocalizationIndex(
        defaultLocaleIdentifier: bundle.metadata.defaultLocaleIdentifier,
        availableLocaleIdentifiers: bundle.metadata.availableLocaleIdentifiers
      ),
      encoder: encoder
    )

    var payloads: [(String, Data)] = [
      (paths.metadataPath, metadataData),
      (paths.emojisPath, emojisData),
      ("\(paths.localizationsPath)/index.json", indexData)
    ]

    payloads.append(
      contentsOf: try bundle.localizations.keys.sorted()
        .map { locale in
          let path = "\(paths.localizationsPath)/\(locale).json"
          return (path, try encoded(bundle.localizations[locale], encoder: encoder))
        }
    )

    var changedFiles: [String] = []
    for (path, data) in payloads where try shouldWrite(path: path, data: data, force: force) {
      changedFiles.append(path)
      if !dryRun {
        try writeAtomically(data: data, to: path)
      }
    }

    return WriteSummary(
      unicodeVersion: bundle.metadata.unicodeEmojiVersion,
      cldrVersion: bundle.metadata.cldrVersion,
      localeCount: bundle.metadata.availableLocaleIdentifiers.count,
      emojiCount: bundle.emojis.count,
      changedFiles: changedFiles,
      dryRun: dryRun
    )
  }

  private func shouldWrite(path: String, data: Data, force: Bool) throws -> Bool {
    if force {
      return true
    }

    guard fileManager.fileExists(atPath: path) else {
      return true
    }

    return try Data(contentsOf: URL(fileURLWithPath: path)) != data
  }

  private func writeAtomically(data: Data, to path: String) throws {
    let url = URL(fileURLWithPath: path)
    try fileManager.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: url, options: .atomic)
  }

  private func encoded<T: Encodable>(_ value: T?, encoder: JSONEncoder) throws -> Data {
    guard let value else {
      throw ValidationError("Missing generated value during encoding.")
    }

    var data = try encoder.encode(value)
    // Keep generated JSON newline-terminated so diffs stay stable and git-friendly.
    if data.last != 0x0A {
      data.append(0x0A)
    }
    return data
  }
}

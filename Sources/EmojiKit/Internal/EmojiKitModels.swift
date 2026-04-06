import ArgumentParser
import Foundation

internal struct CLIOutputPaths: Equatable {
  static let defaultOutputRoot = "Sources/Emojis/Resources"

  internal let metadataPath: String
  internal let emojisPath: String
  internal let localizationsPath: String

  internal init(
    outputRoot: String?,
    metadataPath: String?,
    emojisPath: String?,
    localizationsPath: String?
  ) throws {
    let root = outputRoot ?? Self.defaultOutputRoot
    self.metadataPath = metadataPath ?? "\(root)/metadata.json"
    self.emojisPath = emojisPath ?? "\(root)/emojis.json"
    self.localizationsPath = localizationsPath ?? "\(root)/localizations"
  }
}

internal enum LocaleSelection: Equatable {
  case all
  case explicit([String])

  internal init(argument: String?) throws {
    guard let argument, !argument.isEmpty else {
      self = .explicit(["en"])
      return
    }

    if argument == "all" {
      self = .all
      return
    }

    let locales =
      argument
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    guard !locales.isEmpty else {
      throw ValidationError("`--locales` must be `all` or a comma-separated locale list.")
    }

    self = .explicit(locales.contains("en") ? locales : ["en"] + locales)
  }
}

internal struct GeneratedMetadata: Codable, Equatable, Sendable {
  internal struct SourceFile: Codable, Equatable, Sendable {
    let name: String
    let url: String
    let sha256: String
  }

  let schemaVersion: Int
  let unicodeEmojiVersion: String
  let cldrVersion: String
  let generatedAt: Date
  let defaultLocaleIdentifier: String
  let availableLocaleIdentifiers: [String]
  let sourceFiles: [SourceFile]
}

internal struct GeneratedEmojiID: RawRepresentable, Codable, Hashable, Sendable {
  let rawValue: String

  internal init(rawValue: String) {
    self.rawValue = rawValue
  }
}

internal enum GeneratedSkinTone: String, Codable, Sendable, Hashable, CaseIterable {
  case light
  case mediumLight
  case medium
  case mediumDark
  case dark
}

internal enum GeneratedSkinToneSupport: String, Codable, Sendable, Hashable {
  case none
  case single
  case multiple
}

internal struct GeneratedSkinToneVariant: Codable, Equatable, Sendable, Hashable {
  let id: GeneratedEmojiID
  let value: String
  let tones: [GeneratedSkinTone]
}

internal struct GeneratedBaseEmoji: Codable, Equatable, Sendable {
  let id: String
  let value: String
  let group: String
  let subgroup: String
  let unicodeVersion: String
  let sortOrder: Int
  let skinToneSupport: GeneratedSkinToneSupport
  let skinToneVariants: [GeneratedSkinToneVariant]
  let fallbackName: String

  internal init(
    id: String,
    value: String,
    group: String,
    subgroup: String,
    unicodeVersion: String,
    sortOrder: Int,
    skinToneSupport: GeneratedSkinToneSupport = .none,
    skinToneVariants: [GeneratedSkinToneVariant] = [],
    fallbackName: String = ""
  ) {
    self.id = id
    self.value = value
    self.group = group
    self.subgroup = subgroup
    self.unicodeVersion = unicodeVersion
    self.sortOrder = sortOrder
    self.skinToneSupport = skinToneSupport
    self.skinToneVariants = skinToneVariants
    self.fallbackName = fallbackName
  }
}

internal struct GeneratedLocalizationFile: Codable, Equatable, Sendable {
  let localeIdentifier: String
  let entries: [String: GeneratedLocalizationEntry]
}

internal struct GeneratedLocalizationIndex: Codable, Equatable, Sendable {
  let defaultLocaleIdentifier: String
  let availableLocaleIdentifiers: [String]
}

internal struct GeneratedLocalizationEntry: Codable, Equatable, Sendable {
  let name: String
  let searchTokens: [String]
}

internal struct GeneratedBundle: Equatable, Sendable {
  let metadata: GeneratedMetadata
  let emojis: [GeneratedBaseEmoji]
  let localizations: [String: GeneratedLocalizationFile]
}

internal struct WriteSummary: Equatable, Sendable {
  let unicodeVersion: String
  let cldrVersion: String
  let localeCount: Int
  let emojiCount: Int
  let changedFiles: [String]
  let dryRun: Bool

  var rendered: String {
    let changed = changedFiles.isEmpty ? "none" : changedFiles.joined(separator: ", ")
    let prefix = dryRun ? "Dry run:" : "Generated:"
    return
      "\(prefix) Unicode \(unicodeVersion), CLDR \(cldrVersion), locales \(localeCount), emojis \(emojiCount), changed files: \(changed)"
  }
}

internal struct EmojiDataFile: Sendable {
  let name: String
  let url: URL
  let data: Data
  let sha256: String
}

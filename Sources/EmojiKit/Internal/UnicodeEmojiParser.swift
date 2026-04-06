import ArgumentParser
import Foundation

internal struct UnicodeEmojiParser {
  private struct RawEmojiRecord: Sendable {
    let id: String
    let value: String
    let group: String
    let subgroup: String
    let unicodeVersion: String
    let sortOrder: Int
    let fallbackName: String
  }

  private static let componentGroup = "Component"

  private static let skinToneByScalar: [String: GeneratedSkinTone] = [
    "1F3FB": .light,
    "1F3FC": .mediumLight,
    "1F3FD": .medium,
    "1F3FE": .mediumDark,
    "1F3FF": .dark
  ]

  internal static func parseEmojiTest(_ data: Data) throws -> [GeneratedBaseEmoji] {
    guard let text = String(data: data, encoding: .utf8) else {
      throw ValidationError("Unable to decode emoji-test.txt as UTF-8.")
    }

    return try collapseSkinToneVariants(in: parseRawEmojiRecords(from: text))
  }

  private static func parseRawEmojiRecords(from text: String) throws -> [RawEmojiRecord] {
    var emojis: [RawEmojiRecord] = []
    var currentGroup = ""
    var currentSubgroup = ""
    var sortOrder = 0

    for line in text.split(whereSeparator: \.isNewline) {
      let rawLine = String(line)

      if rawLine.hasPrefix("# group: ") {
        currentGroup = String(rawLine.dropFirst("# group: ".count))
        continue
      }

      if rawLine.hasPrefix("# subgroup: ") {
        currentSubgroup = String(rawLine.dropFirst("# subgroup: ".count))
        continue
      }

      guard rawLine.contains("; fully-qualified"), let hashIndex = rawLine.firstIndex(of: "#")
      else {
        continue
      }

      let left = rawLine[..<hashIndex]
      let right = rawLine[rawLine.index(after: hashIndex)...]
      let scalars = left.split(separator: ";")[0]
        .split(separator: " ")
        .map(String.init)
        .filter { !$0.isEmpty }

      let rightParts = right.split(separator: " ", omittingEmptySubsequences: true)
      guard rightParts.count >= 3 else {
        throw ValidationError("Unsupported emoji-test.txt format.")
      }

      let value = String(rightParts[0])
      guard let versionIndex = rightParts.firstIndex(where: { $0.hasPrefix("E") }) else {
        throw ValidationError("Missing Unicode version in emoji-test.txt.")
      }
      let versionToken = rightParts[versionIndex]
      let fallbackName = rightParts[(versionIndex + 1)...].joined(separator: " ")

      sortOrder += 1
      emojis.append(
        RawEmojiRecord(
          id: normalizeID(from: scalars),
          value: value,
          group: currentGroup,
          subgroup: currentSubgroup,
          unicodeVersion: String(versionToken.dropFirst()),
          sortOrder: sortOrder,
          fallbackName: fallbackName
        )
      )
    }

    return emojis
  }

  private static func collapseSkinToneVariants(
    in rawRecords: [RawEmojiRecord]
  ) throws -> [GeneratedBaseEmoji] {
    var logicalByID: [String: GeneratedBaseEmoji] = [:]
    var idsByFallbackName: [String: String] = [:]
    var orderedLogicalIDs: [String] = []
    var seenLogicalIDs: Set<String> = []

    for record in rawRecords where !isSkinToneVariant(record) {
      logicalByID[record.id] = GeneratedBaseEmoji(
        id: record.id,
        value: record.value,
        group: record.group,
        subgroup: record.subgroup,
        unicodeVersion: record.unicodeVersion,
        sortOrder: record.sortOrder,
        fallbackName: record.fallbackName
      )
      if seenLogicalIDs.insert(record.id).inserted {
        orderedLogicalIDs.append(record.id)
      }
      if idsByFallbackName[record.fallbackName] == nil {
        idsByFallbackName[record.fallbackName] = record.id
      }
    }

    for record in rawRecords where isSkinToneVariant(record) {
      let logicalID = resolveLogicalBaseID(for: record, idsByFallbackName: idsByFallbackName)

      if logicalByID[logicalID] == nil {
        logicalByID[logicalID] = GeneratedBaseEmoji(
          id: logicalID,
          value: strippedSkinToneValue(from: record.value),
          group: record.group,
          subgroup: record.subgroup,
          unicodeVersion: record.unicodeVersion,
          sortOrder: record.sortOrder,
          fallbackName: baseFallbackName(from: record.fallbackName) ?? record.fallbackName
        )
      }

      if seenLogicalIDs.insert(logicalID).inserted {
        orderedLogicalIDs.append(logicalID)
      }

      let variant = GeneratedSkinToneVariant(
        id: .init(rawValue: record.id),
        value: record.value,
        tones: skinTones(in: record.id)
      )
      guard var logical = logicalByID[logicalID] else {
        throw ValidationError("Unable to create logical emoji entry for \(record.id)")
      }

      logical = GeneratedBaseEmoji(
        id: logical.id,
        value: logical.value,
        group: logical.group,
        subgroup: logical.subgroup,
        unicodeVersion: logical.unicodeVersion,
        sortOrder: logical.sortOrder,
        skinToneSupport: skinToneSupport(for: logical.skinToneVariants + [variant]),
        skinToneVariants: logical.skinToneVariants + [variant],
        fallbackName: logical.fallbackName
      )
      logicalByID[logicalID] = logical
    }

    return orderedLogicalIDs.compactMap { logicalByID[$0] }.sorted { $0.sortOrder < $1.sortOrder }
  }

  private static func isSkinToneVariant(_ record: RawEmojiRecord) -> Bool {
    record.group != componentGroup && !skinTones(in: record.id).isEmpty
  }

  private static func resolveLogicalBaseID(
    for record: RawEmojiRecord,
    idsByFallbackName: [String: String]
  ) -> String {
    if let baseName = baseFallbackName(from: record.fallbackName),
      let baseID = idsByFallbackName[baseName]
    {
      return baseID
    }

    return strippedSkinToneID(from: record.id)
  }

  private static func baseFallbackName(from fallbackName: String) -> String? {
    guard fallbackName.contains("skin tone"), let separator = fallbackName.firstIndex(of: ":")
    else {
      return nil
    }

    return String(fallbackName[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func strippedSkinToneID(from id: String) -> String {
    id.split(separator: "-")
      .map(String.init)
      .filter { skinToneByScalar[$0] == nil }
      .joined(separator: "-")
  }

  private static func strippedSkinToneValue(from value: String) -> String {
    String(
      String.UnicodeScalarView(
        value.unicodeScalars.filter { scalar in
          let identifier = String(format: "%04X", scalar.value)
          return skinToneByScalar[identifier] == nil
        }
      )
    )
  }

  private static func skinTones(in emojiID: String) -> [GeneratedSkinTone] {
    emojiID.split(separator: "-")
      .map(String.init)
      .compactMap { skinToneByScalar[$0] }
  }

  private static func skinToneSupport(
    for variants: [GeneratedSkinToneVariant]
  ) -> GeneratedSkinToneSupport {
    let maximumToneCount = variants.map { $0.tones.count }.max() ?? 0
    if maximumToneCount == 0 {
      return .none
    }
    return maximumToneCount == 1 ? .single : .multiple
  }

  internal static func normalizeID(from scalars: [String]) -> String {
    scalars.map { $0.uppercased() }.joined(separator: "-")
  }
}

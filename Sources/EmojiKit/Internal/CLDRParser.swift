import ArgumentParser
import Foundation

internal struct CLDRParser {
  internal static func availableLocales(from data: Data) throws -> [String] {
    let object = try JSONSerialization.jsonObject(with: data)
    guard
      let dictionary = object as? [String: Any],
      let availableLocales = dictionary["availableLocales"] as? [String: Any],
      let full = availableLocales["full"] as? [String]
    else {
      throw ValidationError("Unsupported availableLocales.json format.")
    }

    return full.sorted()
  }

  internal static func parseLocalization(
    data: Data,
    locale: String
  ) throws -> [String: GeneratedLocalizationEntry] {
    let object = try JSONSerialization.jsonObject(with: data)
    guard
      let dictionary = object as? [String: Any],
      let annotationsRoot =
        (dictionary["annotations"] as? [String: Any])
          ?? (dictionary["annotationsDerived"] as? [String: Any]),
      let annotations = annotationsRoot["annotations"] as? [String: Any]
    else {
      throw ValidationError("Unsupported CLDR annotations format for locale \(locale).")
    }

    var result: [String: GeneratedLocalizationEntry] = [:]

    for (emojiValue, value) in annotations {
      let identifier = UnicodeEmojiParser.normalizeID(
        from: emojiValue.unicodeScalars.map { String(format: "%04X", $0.value) }
      )

      if let entry = value as? [String: Any] {
        let name =
          ((entry["tts"] as? [String])?.first ?? entry["tts"] as? String ?? "")
          .trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = (entry["default"] as? [String] ?? [])
        result[identifier] = GeneratedLocalizationEntry(
          name: name,
          searchTokens: tokens
        )
      }
    }

    return result
  }
}

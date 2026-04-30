import Emojis

enum MockRandomEmojiSource {
  private enum Constants {
    static let fallbackEmojis = ["😀", "😂", "🥹", "😎", "🤝", "🔥", "✨", "🚀", "🌸", "✅"]
  }

  private static let availableEmojis = loadAvailableEmojis()

  static func randomEmoji() -> String? {
    availableEmojis.randomElement()
  }
}

private extension MockRandomEmojiSource {
  static func loadAvailableEmojis() -> [String] {
    let filter: Emojis.Filter

    #if canImport(CoreText)
      filter = .apple
    #else
      filter = .none
    #endif

    let values =
      (try? Emojis.fetch(filter: filter))?
      .filter { $0.group != .component }
      .map(\.value)
      ?? []

    return values.isEmpty ? Constants.fallbackEmojis : values
  }
}

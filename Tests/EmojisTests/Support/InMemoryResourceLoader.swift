import Foundation

@testable import Emojis

internal struct InMemoryResourceLoader: EmojiResourceLoading {
  let resources: [String: Data]

  func data(for relativePath: String) throws -> Data {
    guard let data = resources[relativePath] else {
      throw EmojisError.missingBundledResource(relativePath)
    }
    return data
  }
}

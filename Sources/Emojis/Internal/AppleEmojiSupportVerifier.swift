#if canImport(CoreText)
  import CoreText
  import Foundation

  internal protocol AppleEmojiSupportBackend: Sendable {
    func supports(_ emoji: String) throws -> Bool
  }

  internal protocol AppleEmojiOSVersionProviding: Sendable {
    var cacheKey: String { get }
  }

  internal struct ProcessAppleEmojiOSVersionProvider: AppleEmojiOSVersionProviding {
    internal var cacheKey: String {
      let version = ProcessInfo.processInfo.operatingSystemVersion
      return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
  }

  internal struct CoreTextAppleEmojiSupportBackend: AppleEmojiSupportBackend {
    internal func supports(_ emoji: String) throws -> Bool {
      let font = CTFontCreateWithName("AppleColorEmoji" as CFString, 16, nil)
      let attributes: [NSAttributedString.Key: Any] = [
        kCTFontAttributeName as NSAttributedString.Key: font
      ]
      let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: emoji, attributes: attributes)
      )
      let runs = CTLineGetGlyphRuns(line) as NSArray

      guard runs.count > 0 else {
        throw EmojisError.appleVerificationUnavailable
      }

      var sawDrawableGlyph = false

      for case let run as CTRun in runs {
        let glyphCount = CTRunGetGlyphCount(run)
        guard glyphCount > 0 else {
          continue
        }

        sawDrawableGlyph = true

        let attributes = CTRunGetAttributes(run) as NSDictionary
        if let runFontValue = attributes[kCTFontAttributeName] {
          let runFont = unsafeDowncast(runFontValue as AnyObject, to: CTFont.self)
          let postScriptName = CTFontCopyPostScriptName(runFont) as String
          if postScriptName.contains("LastResort") {
            return false
          }
        }
      }

      return sawDrawableGlyph
    }
  }

  /// Heuristic support filter used by `Filter.apple` on Apple platforms.
  internal final class AppleEmojiSupportVerifier: @unchecked Sendable {
    internal static let shared = AppleEmojiSupportVerifier()

    private let backend: any AppleEmojiSupportBackend
    private let osVersionProvider: any AppleEmojiOSVersionProviding
    private let cacheVersion = "1"
    private var cache: [String: Bool] = [:]
    private let lock = NSLock()

    internal init(
      backend: any AppleEmojiSupportBackend = CoreTextAppleEmojiSupportBackend(),
      osVersionProvider: any AppleEmojiOSVersionProviding =
        ProcessAppleEmojiOSVersionProvider()
    ) {
      self.backend = backend
      self.osVersionProvider = osVersionProvider
    }

    internal func filter(_ emojis: [Emoji], metadata: Metadata) throws -> [Emoji] {
      var filtered: [Emoji] = []
      filtered.reserveCapacity(emojis.count)

      for emoji in emojis where try isSupported(emoji.value, metadata: metadata) {
        filtered.append(emoji)
      }

      return filtered
    }

    internal func isSupported(_ emoji: String, metadata: Metadata) throws -> Bool {
      let key = [
        metadata.unicodeEmojiVersion,
        metadata.cldrVersion,
        osVersionProvider.cacheKey,
        cacheVersion,
        emoji
      ]
      .joined(separator: "|")

      lock.lock()
      if let cached = cache[key] {
        lock.unlock()
        return cached
      }
      lock.unlock()

      let supported = try backend.supports(emoji)

      lock.lock()
      cache[key] = supported
      lock.unlock()

      return supported
    }
  }
#endif

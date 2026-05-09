import CoreFoundation
import CoreGraphics
import Foundation

enum FocusedTextAnchorHeuristics {
  nonisolated static let defaultEstimatedLineHeight: CGFloat = 22
  nonisolated static let defaultEstimatedCharacterWidth: CGFloat = 8
  nonisolated static let estimatedTextHorizontalInset: CGFloat = 12
  nonisolated static let estimatedSearchFieldHorizontalInset: CGFloat = 44
  nonisolated static let estimatedAccessoryTextSpacing: CGFloat = 8
  nonisolated static let maximumEstimatedAccessoryTextInset: CGFloat = 80
  nonisolated static let estimatedTextVerticalInset: CGFloat = 8
  nonisolated static let maximumPlausibleInsertionPointLine = 100_000

  nonisolated static func isPlausibleInsertionPointLine(_ insertionPointLine: Int) -> Bool {
    insertionPointLine >= 0 && insertionPointLine <= maximumPlausibleInsertionPointLine
  }

  nonisolated static func insertionIndex(in text: NSString, for selectedTextRange: CFRange) -> Int?
  {
    guard selectedTextRange.location != kCFNotFound else {
      return nil
    }

    return min(max(selectedTextRange.location + selectedTextRange.length, 0), text.length)
  }

  nonisolated static func candidateCharacterRanges(for selectedTextRange: CFRange) -> [CFRange] {
    guard selectedTextRange.location != kCFNotFound else {
      return []
    }

    var ranges: [CFRange] = []

    if selectedTextRange.location > 0 {
      ranges.append(CFRange(location: selectedTextRange.location - 1, length: 1))
    }

    ranges.append(CFRange(location: selectedTextRange.location, length: 1))
    return ranges
  }

  nonisolated static func isAtLineStart(in text: NSString, selectedTextRange: CFRange) -> Bool {
    guard let insertionIndex = insertionIndex(in: text, for: selectedTextRange) else {
      return false
    }

    if insertionIndex == 0 {
      return true
    }

    return text.substring(with: NSRange(location: insertionIndex - 1, length: 1)) == "\n"
  }

  nonisolated static func newlineCount(in string: String) -> Int {
    string.reduce(into: 0) { result, character in
      if character == "\n" {
        result += 1
      }
    }
  }

  nonisolated static func visualLineIndex(in prefix: String) -> Int {
    let newlineCount = newlineCount(in: prefix)
    let trailingNewlineCount = prefix.reversed().prefix { $0 == "\n" }.count
    return max(newlineCount - max(trailingNewlineCount - 2, 0), 0)
  }

  nonisolated static func horizontalInset(
    baseInset: CGFloat,
    elementMinX: CGFloat,
    leadingAccessoryTrailingEdge: CGFloat?
  ) -> CGFloat {
    guard let leadingAccessoryTrailingEdge else {
      return baseInset
    }

    let accessoryInset = leadingAccessoryTrailingEdge - elementMinX + estimatedAccessoryTextSpacing
    return min(max(baseInset, accessoryInset), maximumEstimatedAccessoryTextInset)
  }
}

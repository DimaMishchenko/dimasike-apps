import CoreFoundation
import Foundation
import Testing

@testable import AccessibilitySupport

@Suite struct TextAnchorHeuristicsTests {
  @Test func plausibleInsertionPointLineAcceptsReasonableValues() {
    #expect(FocusedTextAnchorHeuristics.isPlausibleInsertionPointLine(0))
    #expect(FocusedTextAnchorHeuristics.isPlausibleInsertionPointLine(42))
    #expect(
      FocusedTextAnchorHeuristics.isPlausibleInsertionPointLine(
        FocusedTextAnchorHeuristics.maximumPlausibleInsertionPointLine
      )
    )
  }

  @Test func plausibleInsertionPointLineRejectsBogusSentinels() {
    #expect(!FocusedTextAnchorHeuristics.isPlausibleInsertionPointLine(-1))
    #expect(!FocusedTextAnchorHeuristics.isPlausibleInsertionPointLine(.max))
  }

  @Test func candidateCharacterRangesIncludePreviousCharacterWhenPossible() {
    let ranges = FocusedTextAnchorHeuristics.candidateCharacterRanges(
      for: CFRange(location: 4, length: 0)
    )

    #expect(rangeDescriptions(ranges) == ["3:1", "4:1"])
  }

  @Test func candidateCharacterRangesAtDocumentStartSkipNegativeRange() {
    let ranges = FocusedTextAnchorHeuristics.candidateCharacterRanges(
      for: CFRange(location: 0, length: 0)
    )

    #expect(rangeDescriptions(ranges) == ["0:1"])
  }

  @Test func insertionIndexClampsToStringBounds() {
    let text = NSString(string: "hello")

    #expect(
      FocusedTextAnchorHeuristics.insertionIndex(
        in: text,
        for: CFRange(location: 99, length: 0)
      ) == 5
    )
    #expect(
      FocusedTextAnchorHeuristics.insertionIndex(
        in: text,
        for: CFRange(location: 2, length: 2)
      ) == 4
    )
  }

  @Test func insertionIndexRejectsUnknownSelection() {
    let text = NSString(string: "hello")

    #expect(
      FocusedTextAnchorHeuristics.insertionIndex(
        in: text,
        for: CFRange(location: kCFNotFound, length: 0)
      ) == nil
    )
  }
}

private func rangeDescriptions(_ ranges: [CFRange]) -> [String] {
  ranges.map { "\($0.location):\($0.length)" }
}

import AppKit
import ApplicationServices

// The public API stays intentionally small; this type owns the messy AX lookup and fallback logic.
struct TextAnchorLocator {
  private enum Constants {
    static let manualAccessibilityWarmupDelay: CFTimeInterval = 0.15
    static let maximumAncestorDepth = 8
    static let maximumDescendantDepth = 4
    static let maximumCandidateCount = 64
  }

  private let elements = AccessibilityElementReader()
  private var manualAccessibilityWarmup = ManualAccessibilityWarmup()

  mutating func anchorRect() -> CGRect? {
    guard AXIsProcessTrusted() else {
      return nil
    }

    let didWarmUpManualAccessibility = manualAccessibilityWarmup.prepareFrontmostApplication()
    if didWarmUpManualAccessibility {
      pauseForManualAccessibilityWarmup()
    }

    if let anchorRect = anchorRectForCurrentFocus() {
      return anchorRect
    }

    // Wrapper apps sometimes expose the accessibility tree a beat after AXManualAccessibility.
    guard didWarmUpManualAccessibility else {
      return nil
    }

    pauseForManualAccessibilityWarmup()
    return anchorRectForCurrentFocus()
  }
}

private extension TextAnchorLocator {
  func pauseForManualAccessibilityWarmup() {
    CFRunLoopRunInMode(.defaultMode, Constants.manualAccessibilityWarmupDelay, false)
  }

  func anchorRectForCurrentFocus() -> CGRect? {
    guard let focusedElement = elements.refreshedFocusedElement(after: elements.focusedElement())
    else {
      return nil
    }

    guard let textContext = textContext(startingFrom: focusedElement) else {
      return nil
    }

    return anchorRect(for: textContext)
  }

  func textContext(startingFrom focusedElement: AXUIElement) -> TextAnchorContext? {
    guard !elements.isWindowElement(focusedElement) else {
      return nil
    }

    let lineage =
      [focusedElement]
      + elements.ancestorElements(
        of: focusedElement,
        maxDepth: Constants.maximumAncestorDepth
      )

    // If the focused chain has no text signal at all, centering is safer than guessing.
    guard hasTextFocusSignal(in: lineage) else {
      return nil
    }

    let candidates = candidateElements(from: lineage)

    for element in candidates where isTextInputCandidate(element) {
      let inputElementRect = editableElementRect(for: element)

      if let selectedTextMarkerRange = elements.selectedTextMarkerRange(for: element),
        let bounds = elements.textMarkerSelectionBounds(
          for: selectedTextMarkerRange,
          in: element
        ),
        isPlausibleCaretRect(
          bounds,
          for: elements.selectedTextRange(for: element) ?? CFRange(location: 0, length: 0),
          in: element,
          elementRect: inputElementRect
        )
      {
        return TextAnchorContext(
          element: element,
          selectedTextRange: elements.selectedTextRange(for: element)
            ?? CFRange(location: 0, length: 0),
          selectedTextMarkerRange: selectedTextMarkerRange
        )
      }

      if let selectedTextRange = elements.selectedTextRange(for: element),
        selectionBounds(
          for: selectedTextRange,
          in: element,
          elementRect: inputElementRect
        ) != nil
          || adjacentCharacterRect(for: selectedTextRange, in: element) != nil
          || estimatedCaretRect(
            for: element,
            selectedTextRange: selectedTextRange,
            elementRect: inputElementRect
          ) != nil
      {
        return TextAnchorContext(
          element: element,
          selectedTextRange: selectedTextRange,
          selectedTextMarkerRange: nil
        )
      }
    }

    return nil
  }

  func candidateElements(from lineage: [AXUIElement]) -> [AXUIElement] {
    var candidates: [AXUIElement] = []
    candidates.reserveCapacity(Constants.maximumCandidateCount)

    var seen = Set(lineage.map(elements.elementIdentifier(for:)))
    candidates.append(contentsOf: lineage)

    var queue = lineage.map { (element: $0, depth: 0) }
    var queueIndex = 0

    while queueIndex < queue.count, candidates.count < Constants.maximumCandidateCount {
      let current = queue[queueIndex]
      queueIndex += 1

      guard current.depth < Constants.maximumDescendantDepth else {
        continue
      }

      for child in elements.childElements(of: current.element) {
        let childIdentifier = elements.elementIdentifier(for: child)
        guard seen.insert(childIdentifier).inserted else {
          continue
        }

        candidates.append(child)
        queue.append((child, current.depth + 1))

        guard candidates.count < Constants.maximumCandidateCount else {
          break
        }
      }
    }

    return candidates
  }
}

private extension TextAnchorLocator {
  func anchorRect(for textContext: TextAnchorContext) -> CGRect? {
    let inputElementRect = editableElementRect(for: textContext.element)

    if let selectedTextMarkerRange = textContext.selectedTextMarkerRange,
      let bounds = elements.textMarkerSelectionBounds(
        for: selectedTextMarkerRange,
        in: textContext.element
      ),
      isPlausibleCaretRect(
        bounds,
        for: textContext.selectedTextRange,
        in: textContext.element,
        elementRect: inputElementRect
      )
    {
      return bounds
    }

    if let bounds = selectionBounds(
      for: textContext.selectedTextRange,
      in: textContext.element,
      elementRect: inputElementRect
    ) {
      return bounds
    }

    if let bounds = adjacentCharacterRect(
      for: textContext.selectedTextRange,
      in: textContext.element
    ) {
      return bounds
    }

    // Final text-aware fallback when AX exposes selection but not caret geometry.
    if let bounds = estimatedCaretRect(
      for: textContext.element,
      selectedTextRange: textContext.selectedTextRange,
      elementRect: inputElementRect
    ) {
      return bounds
    }

    return inputElementRect
  }

  func editableElementRect(for element: AXUIElement) -> CGRect? {
    guard isEditableTextElement(element) else {
      return nil
    }

    return elements.elementRect(for: element)
  }

  func adjacentCharacterRect(
    for selectedTextRange: CFRange,
    in element: AXUIElement
  ) -> CGRect? {
    for range in FocusedTextAnchorHeuristics.candidateCharacterRanges(for: selectedTextRange) {
      var mutableRange = range
      guard let rangeValue = AXValueCreate(.cfRange, &mutableRange),
        let bounds = elements.boundsForRangeValue(rangeValue, in: element)
      else {
        continue
      }

      // Newline bounds tend to point at the previous line edge, which is worse than estimating.
      let string = elements.stringForRangeValue(rangeValue, in: element)
      if string?.contains(where: \.isNewline) == true {
        continue
      }

      if range.location < selectedTextRange.location {
        return CGRect(x: bounds.maxX, y: bounds.minY, width: 1, height: bounds.height)
      }

      return CGRect(x: bounds.minX, y: bounds.minY, width: 1, height: bounds.height)
    }

    return nil
  }

  func estimatedCaretRect(
    for element: AXUIElement,
    selectedTextRange: CFRange,
    elementRect: CGRect?
  ) -> CGRect? {
    guard let elementRect else {
      return nil
    }

    let lineHeight = min(FocusedTextAnchorHeuristics.defaultEstimatedLineHeight, elementRect.height)
    let y: CGFloat

    if isSingleLineTextElement(element) {
      y = min(
        max(elementRect.midY - (lineHeight / 2), elementRect.minY),
        elementRect.maxY - lineHeight
      )
    } else {
      let lineIndex = estimatedLineIndex(for: element, selectedTextRange: selectedTextRange)
      y = min(
        max(
          elementRect.minY + FocusedTextAnchorHeuristics.estimatedTextVerticalInset
            + (CGFloat(lineIndex) * lineHeight),
          elementRect.minY
        ),
        elementRect.maxY - lineHeight
      )
    }

    return CGRect(
      x: estimatedCaretX(for: element, selectedTextRange: selectedTextRange, in: elementRect),
      y: y,
      width: 1,
      height: lineHeight
    )
  }

  func estimatedLineIndex(for element: AXUIElement, selectedTextRange: CFRange) -> Int {
    if let text = elements.stringValue(of: element).map(NSString.init),
      let insertionIndex = FocusedTextAnchorHeuristics.insertionIndex(
        in: text,
        for: selectedTextRange
      )
    {
      return FocusedTextAnchorHeuristics.newlineCount(in: text.substring(to: insertionIndex))
    }

    return max(elements.insertionPointLine(of: element).map { $0 - 1 } ?? 0, 0)
  }

  func estimatedCaretX(
    for element: AXUIElement,
    selectedTextRange: CFRange,
    in elementRect: CGRect
  ) -> CGFloat {
    let minX = elementRect.minX + FocusedTextAnchorHeuristics.estimatedTextHorizontalInset
    let maxX = max(
      minX,
      elementRect.maxX - FocusedTextAnchorHeuristics.estimatedTextHorizontalInset
    )

    guard
      let text = elements.stringValue(of: element).map(NSString.init),
      let insertionIndex = FocusedTextAnchorHeuristics.insertionIndex(
        in: text,
        for: selectedTextRange
      )
    else {
      return minX
    }

    let prefix = text.substring(to: insertionIndex)
    let column = prefix.components(separatedBy: "\n").last?.count ?? 0
    return min(
      minX + (CGFloat(column) * FocusedTextAnchorHeuristics.defaultEstimatedCharacterWidth),
      maxX
    )
  }

  func selectionBounds(
    for selectedTextRange: CFRange,
    in element: AXUIElement,
    elementRect: CGRect?
  ) -> CGRect? {
    var range = selectedTextRange
    guard let rangeValue = AXValueCreate(.cfRange, &range),
      let bounds = elements.boundsForRangeValue(rangeValue, in: element)
    else {
      return nil
    }

    guard
      isPlausibleCaretRect(
        bounds,
        for: selectedTextRange,
        in: element,
        elementRect: elementRect
      )
    else {
      return nil
    }

    return bounds
  }

  func isPlausibleCaretRect(
    _ bounds: CGRect,
    for selectedTextRange: CFRange,
    in element: AXUIElement,
    elementRect: CGRect?
  ) -> Bool {
    guard selectedTextRange.length == 0, let elementRect else {
      return true
    }

    let maxExpectedWidth = max(
      FocusedTextAnchorHeuristics.defaultEstimatedCharacterWidth * 2,
      elementRect.width * 0.1
    )
    guard
      bounds.width <= maxExpectedWidth,
      bounds.height <= max(elementRect.height * 1.5, 44)
    else {
      return false
    }

    // Some multiline editors report a previous-line caret rect for empty lines. Compare the
    // AX-provided rect against the text-derived line position and reject only clearly off-line
    // results so we can fall back to the estimated caret instead.
    guard
      !isSingleLineTextElement(element),
      let estimatedBounds = estimatedCaretRect(
        for: element,
        selectedTextRange: selectedTextRange,
        elementRect: elementRect
      )
    else {
      return true
    }

    let allowedVerticalDelta = max(8, min(bounds.height, estimatedBounds.height) * 0.75)
    return abs(bounds.midY - estimatedBounds.midY) <= allowedVerticalDelta
  }
}

private extension TextAnchorLocator {
  func hasTextFocusSignal(in elementsToCheck: [AXUIElement]) -> Bool {
    elementsToCheck.contains { isTextInputCandidate($0) }
  }

  func isTextInputCandidate(_ element: AXUIElement) -> Bool {
    isEditableTextElement(element)
      || elements.insertionPointLine(of: element)
        .map(FocusedTextAnchorHeuristics.isPlausibleInsertionPointLine)
        ?? false
  }

  func isEditableTextElement(_ element: AXUIElement) -> Bool {
    guard !hasBogusInsertionPointLine(element) else {
      return false
    }

    if elements.isExplicitlyEditable(element) {
      return true
    }

    return elements.isEditableTextRole(elements.role(of: element))
  }

  func isSingleLineTextElement(_ element: AXUIElement) -> Bool {
    elements.isSingleLineTextRole(elements.role(of: element))
  }

  func hasBogusInsertionPointLine(_ element: AXUIElement) -> Bool {
    guard let insertionPointLine = elements.insertionPointLine(of: element) else {
      return false
    }

    return !FocusedTextAnchorHeuristics.isPlausibleInsertionPointLine(insertionPointLine)
  }
}

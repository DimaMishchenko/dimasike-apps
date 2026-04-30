import AppKit
import ApplicationServices

struct AccessibilityElementReader {
  private enum Constants {
    static let editableAttribute = "AXEditable" as CFString
    static let selectedTextMarkerRangeAttribute = "AXSelectedTextMarkerRange" as CFString
    static let boundsForTextMarkerRangeParameterizedAttribute =
      "AXBoundsForTextMarkerRange" as CFString
    static let comboBoxRole = "AXComboBox"
    static let searchFieldRole = "AXSearchField"
  }

  func focusedElement() -> AXUIElement? {
    let systemWideElement = AXUIElementCreateSystemWide()
    if let focusedElement = copyElementAttribute(
      kAXFocusedUIElementAttribute as CFString,
      from: systemWideElement
    ) {
      return focusedElement
    }

    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      return nil
    }

    let applicationElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
    if let focusedElement = copyElementAttribute(
      kAXFocusedUIElementAttribute as CFString,
      from: applicationElement
    ) {
      return focusedElement
    }

    return copyElementAttribute(kAXFocusedWindowAttribute as CFString, from: applicationElement)
  }

  func refreshedFocusedElement(after element: AXUIElement?) -> AXUIElement? {
    guard element == nil || isWindowElement(element) else {
      return element
    }

    CFRunLoopRunInMode(.defaultMode, 0.05, false)
    return focusedElement() ?? element
  }

  func ancestorElements(of element: AXUIElement, maxDepth: Int) -> [AXUIElement] {
    var ancestors: [AXUIElement] = []
    var currentElement = element

    for _ in 0..<maxDepth {
      guard let parent = copyElementAttribute(kAXParentAttribute as CFString, from: currentElement)
      else {
        break
      }

      ancestors.append(parent)
      currentElement = parent
    }

    return ancestors
  }

  func childElements(of element: AXUIElement) -> [AXUIElement] {
    let attributes = [
      kAXChildrenAttribute as CFString,
      kAXVisibleChildrenAttribute as CFString,
      kAXRowsAttribute as CFString,
      kAXContentsAttribute as CFString
    ]

    for attribute in attributes {
      if let children = copyElementArrayAttribute(attribute, from: element), !children.isEmpty {
        return children
      }
    }

    return []
  }

  func elementIdentifier(for element: AXUIElement) -> UInt {
    UInt(bitPattern: Unmanaged.passUnretained(element).toOpaque())
  }

  func role(of element: AXUIElement) -> String? {
    stringAttribute(kAXRoleAttribute as CFString, from: element)
  }

  func stringValue(of element: AXUIElement) -> String? {
    stringAttribute(kAXValueAttribute as CFString, from: element)
  }

  func isExplicitlyEditable(_ element: AXUIElement) -> Bool {
    boolAttribute(Constants.editableAttribute, from: element) == true
  }

  func insertionPointLine(of element: AXUIElement) -> Int? {
    intAttribute(kAXInsertionPointLineNumberAttribute as CFString, from: element)
  }

  func isWindowElement(_ element: AXUIElement?) -> Bool {
    guard let element else {
      return false
    }

    return role(of: element) == kAXWindowRole
  }

  func isEditableTextRole(_ role: String?) -> Bool {
    role == kAXTextAreaRole
      || role == kAXTextFieldRole
      || role == Constants.searchFieldRole
      || role == Constants.comboBoxRole
  }

  func isSingleLineTextRole(_ role: String?) -> Bool {
    role == kAXTextFieldRole
      || role == Constants.searchFieldRole
      || role == Constants.comboBoxRole
  }

  func elementRect(for element: AXUIElement) -> CGRect? {
    guard
      let positionValue = valueAttribute(kAXPositionAttribute as CFString, from: element),
      let sizeValue = valueAttribute(kAXSizeAttribute as CFString, from: element)
    else {
      return nil
    }

    var position = CGPoint.zero
    var size = CGSize.zero
    guard AXValueGetValue(positionValue, .cgPoint, &position),
      AXValueGetValue(sizeValue, .cgSize, &size)
    else {
      return nil
    }

    let rect = CGRect(origin: position, size: size)
    return rect.isEmpty ? nil : rect
  }

  func selectedTextRange(for element: AXUIElement) -> CFRange? {
    guard
      let selectedTextRangeValue = valueAttribute(
        kAXSelectedTextRangeAttribute as CFString,
        from: element
      )
    else {
      return nil
    }

    var selectedTextRange = CFRange()
    guard AXValueGetValue(selectedTextRangeValue, .cfRange, &selectedTextRange) else {
      return nil
    }

    return selectedTextRange
  }

  func selectedTextMarkerRange(for element: AXUIElement) -> AXTextMarkerRange? {
    guard
      let value = copyAttribute(Constants.selectedTextMarkerRangeAttribute, from: element),
      CFGetTypeID(value) == AXTextMarkerRangeGetTypeID()
    else {
      return nil
    }

    return unsafeBitCast(value, to: AXTextMarkerRange.self)
  }

  func boundsForRangeValue(_ rangeValue: AXValue, in element: AXUIElement) -> CGRect? {
    guard
      let boundsValue = parameterizedValueAttribute(
        kAXBoundsForRangeParameterizedAttribute as CFString,
        parameter: rangeValue,
        from: element
      )
    else {
      return nil
    }

    var bounds = CGRect.zero
    guard AXValueGetValue(boundsValue, .cgRect, &bounds), !bounds.isEmpty else {
      return nil
    }

    return bounds
  }

  func stringForRangeValue(_ rangeValue: AXValue, in element: AXUIElement) -> String? {
    parameterizedAttribute(
      kAXStringForRangeParameterizedAttribute as CFString,
      parameter: rangeValue,
      from: element
    ) as? String
  }

  func textMarkerSelectionBounds(
    for selectedTextMarkerRange: AXTextMarkerRange,
    in element: AXUIElement
  ) -> CGRect? {
    guard
      let value = parameterizedAttribute(
        Constants.boundsForTextMarkerRangeParameterizedAttribute,
        parameter: selectedTextMarkerRange,
        from: element
      ),
      CFGetTypeID(value) == AXValueGetTypeID()
    else {
      return nil
    }

    let boundsValue = unsafeBitCast(value, to: AXValue.self)
    var bounds = CGRect.zero
    guard AXValueGetValue(boundsValue, .cgRect, &bounds), !bounds.isEmpty else {
      return nil
    }

    return bounds
  }
}

private extension AccessibilityElementReader {
  func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> CFTypeRef? {
    var value: CFTypeRef?
    let status = AXUIElementCopyAttributeValue(element, attribute, &value)
    guard status == .success else {
      return nil
    }

    return value
  }

  func copyElementAttribute(
    _ attribute: CFString,
    from element: AXUIElement
  ) -> AXUIElement? {
    guard let value = copyAttribute(attribute, from: element),
      CFGetTypeID(value) == AXUIElementGetTypeID()
    else {
      return nil
    }

    return unsafeBitCast(value, to: AXUIElement.self)
  }

  func copyElementArrayAttribute(
    _ attribute: CFString,
    from element: AXUIElement
  ) -> [AXUIElement]? {
    guard let value = copyAttribute(attribute, from: element),
      CFGetTypeID(value) == CFArrayGetTypeID()
    else {
      return nil
    }

    let array = unsafeBitCast(value, to: CFArray.self)
    let count = CFArrayGetCount(array)
    guard count > 0 else {
      return nil
    }

    var elements: [AXUIElement] = []
    elements.reserveCapacity(count)

    for index in 0..<count {
      let item = CFArrayGetValueAtIndex(array, index)
      let cfItem = unsafeBitCast(item, to: CFTypeRef.self)
      guard CFGetTypeID(cfItem) == AXUIElementGetTypeID() else {
        continue
      }

      elements.append(unsafeBitCast(cfItem, to: AXUIElement.self))
    }

    return elements.isEmpty ? nil : elements
  }

  func valueAttribute(_ attribute: CFString, from element: AXUIElement) -> AXValue? {
    guard let value = copyAttribute(attribute, from: element),
      CFGetTypeID(value) == AXValueGetTypeID()
    else {
      return nil
    }

    return unsafeBitCast(value, to: AXValue.self)
  }

  func stringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
    copyAttribute(attribute, from: element) as? String
  }

  func boolAttribute(_ attribute: CFString, from element: AXUIElement) -> Bool? {
    copyAttribute(attribute, from: element) as? Bool
  }

  func intAttribute(_ attribute: CFString, from element: AXUIElement) -> Int? {
    (copyAttribute(attribute, from: element) as? NSNumber)?.intValue
  }

  func parameterizedAttribute(
    _ attribute: CFString,
    parameter: CFTypeRef,
    from element: AXUIElement
  ) -> CFTypeRef? {
    var value: CFTypeRef?
    let status = AXUIElementCopyParameterizedAttributeValue(
      element,
      attribute,
      parameter,
      &value
    )
    guard status == .success else {
      return nil
    }

    return value
  }

  func parameterizedValueAttribute(
    _ attribute: CFString,
    parameter: CFTypeRef,
    from element: AXUIElement
  ) -> AXValue? {
    guard let value = parameterizedAttribute(attribute, parameter: parameter, from: element),
      CFGetTypeID(value) == AXValueGetTypeID()
    else {
      return nil
    }

    return unsafeBitCast(value, to: AXValue.self)
  }
}

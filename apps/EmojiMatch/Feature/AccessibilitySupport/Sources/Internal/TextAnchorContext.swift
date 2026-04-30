import ApplicationServices

struct TextAnchorContext {
  let element: AXUIElement
  let selectedTextRange: CFRange
  let selectedTextMarkerRange: AXTextMarkerRange?
}

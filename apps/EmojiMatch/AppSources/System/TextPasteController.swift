import AppKit
import Carbon.HIToolbox

enum TextPasteController {
  private enum Constants {
    static let clipboardRestoreDelay: TimeInterval = 0.15
  }

  static func paste(_ text: String) {
    // We could try AX-driven text insertion before falling back, but clipboard-backed paste is
    // the simpler and more reliable baseline across native, Electron, and WebView apps for now.
    let pasteboard = NSPasteboard.general
    let snapshot = PasteboardSnapshot.capture(from: pasteboard)

    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    postPasteShortcut()

    // The target app reads the temporary clipboard contents during paste, so restore the user's
    // previous clipboard after that event has had a chance to complete.
    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.clipboardRestoreDelay) {
      snapshot.restore(to: pasteboard)
    }
  }
}

private extension TextPasteController {
  static func postPasteShortcut() {
    let source = CGEventSource(stateID: .combinedSessionState)
    let keyCode = CGKeyCode(kVK_ANSI_V)

    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    keyDown?.flags = .maskCommand
    keyDown?.post(tap: .cghidEventTap)

    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    keyUp?.flags = .maskCommand
    keyUp?.post(tap: .cghidEventTap)
  }
}

private struct PasteboardSnapshot {
  let items: [NSPasteboardItem]

  static func capture(from pasteboard: NSPasteboard) -> Self {
    let items = (pasteboard.pasteboardItems ?? []).map { clone(item: $0) }
    return Self(items: items)
  }

  func restore(to pasteboard: NSPasteboard) {
    pasteboard.clearContents()

    guard !items.isEmpty else {
      return
    }

    pasteboard.writeObjects(items)
  }
}

private extension PasteboardSnapshot {
  static func clone(item: NSPasteboardItem) -> NSPasteboardItem {
    let clone = NSPasteboardItem()

    for type in item.types {
      if let data = item.data(forType: type) {
        clone.setData(data, forType: type)
      }
    }

    return clone
  }
}

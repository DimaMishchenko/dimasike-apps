import AppKit
import SwiftUI

extension View {
  func hideWindowButtons() -> some View {
    background(WindowButtonsHidden())
  }
}

private struct WindowButtonsHidden: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    WindowButtonsHiderView()
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    hideButtons(from: nsView.window)
  }

  private func hideButtons(from window: NSWindow?) {
    window?.standardWindowButton(.closeButton)?.isHidden = true
    window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window?.standardWindowButton(.zoomButton)?.isHidden = true
  }
}

private final class WindowButtonsHiderView: NSView {
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()

    window?.standardWindowButton(.closeButton)?.isHidden = true
    window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window?.standardWindowButton(.zoomButton)?.isHidden = true
  }
}

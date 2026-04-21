import AppKit
import SwiftUI

final class EmojiMatchPanel<Content: View>: NSPanel {
  init(
    initialSize: CGSize,
    @ViewBuilder content: @escaping (@escaping () -> Void) -> Content
  ) {
    let frame = CGRect(origin: .zero, size: initialSize)
    super
      .init(
        contentRect: frame,
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
      )

    isFloatingPanel = true
    hidesOnDeactivate = false
    level = .statusBar
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    isOpaque = false
    backgroundColor = .clear
    hasShadow = true
    animationBehavior = .utilityWindow
    contentView = NSHostingView(
      rootView: content { [weak self] in
        self?.close()
      }
    )
  }

  func show() {
    center(on: activeScreen())
    orderFrontRegardless()
    makeKeyAndOrderFront(nil)
    focusFirstTextField()
  }

  private func activeScreen() -> NSScreen? {
    NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
  }

  private func center(on screen: NSScreen?) {
    guard let screen else {
      center()
      return
    }

    let frame = screen.visibleFrame
    let size = self.frame.size
    let origin = CGPoint(
      x: frame.midX - (size.width / 2),
      y: frame.midY - (size.height / 2)
    )

    setFrame(CGRect(origin: origin, size: size), display: false)
  }

  private func focusFirstTextField() {
    DispatchQueue.main.async { [weak self] in
      guard let self,
        let textField = firstTextField(in: contentView)
      else {
        return
      }

      makeFirstResponder(textField)
    }
  }

  private func firstTextField(in view: NSView?) -> NSTextField? {
    guard let view else {
      return nil
    }

    if let textField = view as? NSTextField {
      return textField
    }

    for subview in view.subviews {
      if let textField = firstTextField(in: subview) {
        return textField
      }
    }

    return nil
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func resignKey() {
    super.resignKey()
    close()
  }
}

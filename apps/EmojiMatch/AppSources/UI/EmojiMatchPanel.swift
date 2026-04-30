import AppKit
import SwiftUI

private let emojiMatchPanelAnchorSpacing: CGFloat = 8

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

  func show(anchorRect: CGRect?) {
    position(using: anchorRect)
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

  private func position(using anchorRect: CGRect?) {
    guard let anchorRect else {
      center(on: activeScreen())
      return
    }

    let screenRect = rectInScreenCoordinates(anchorRect)

    guard let screen = screen(containing: screenRect)
    else {
      center(on: activeScreen())
      return
    }

    let visibleFrame = screen.visibleFrame
    let size = frame.size
    let x = min(
      max(screenRect.midX - (size.width / 2), visibleFrame.minX),
      visibleFrame.maxX - size.width
    )

    let preferredAboveY = screenRect.maxY + emojiMatchPanelAnchorSpacing
    let preferredBelowY = screenRect.minY - size.height - emojiMatchPanelAnchorSpacing
    let y: CGFloat

    if preferredAboveY + size.height <= visibleFrame.maxY {
      y = preferredAboveY
    } else if preferredBelowY >= visibleFrame.minY {
      y = preferredBelowY
    } else {
      y = min(
        max(preferredAboveY, visibleFrame.minY),
        visibleFrame.maxY - size.height
      )
    }

    setFrame(CGRect(x: x, y: y, width: size.width, height: size.height), display: false)
  }

  private func screen(containing rect: CGRect) -> NSScreen? {
    NSScreen.screens.first { $0.frame.intersects(rect) }
  }

  private func rectInScreenCoordinates(_ rect: CGRect) -> CGRect {
    let desktopFrame = NSScreen.screens.reduce(into: CGRect.null) { partialResult, screen in
      partialResult = partialResult.union(screen.frame)
    }

    // Accessibility bounds use a top-left desktop origin; AppKit window placement uses bottom-left.
    return CGRect(
      x: rect.minX,
      y: desktopFrame.maxY - rect.maxY,
      width: rect.width,
      height: rect.height
    )
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

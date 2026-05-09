import AppKit
import SwiftUI

private enum EmojiMatchPanelChrome {
  static let anchorSpacing: CGFloat = 8
  static let contentPadding: CGFloat = 16
  static let cornerRadius: CGFloat = 40
}

@MainActor
final class EmojiMatchPanel<Content: View>: NSPanel {
  init(
    initialContentSize: CGSize,
    @ViewBuilder content: @escaping (@escaping () -> Void) -> Content
  ) {
    let frame = CGRect(origin: .zero, size: Self.defaultPanelSize(for: initialContentSize))
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
      rootView: EmojiMatchPanelSurface(contentWidth: initialContentSize.width) {
        content { [weak self] in
          self?.close()
        }
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

    guard let screen = screen(containing: screenRect) else {
      center(on: activeScreen())
      return
    }

    let visibleFrame = screen.visibleFrame
    let size = frame.size
    let x = min(
      max(screenRect.midX - (size.width / 2), visibleFrame.minX),
      visibleFrame.maxX - size.width
    )

    let preferredAboveY = screenRect.maxY + EmojiMatchPanelChrome.anchorSpacing
    let preferredBelowY = screenRect.minY - size.height - EmojiMatchPanelChrome.anchorSpacing
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

  private func focusFirstTextField() {
    DispatchQueue.main.async { [weak self] in
      guard let self, let textField = firstTextField(in: contentView) else {
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

  private func rectInScreenCoordinates(_ rect: CGRect) -> CGRect {
    AccessibilityCoordinateConverter.appKitRect(fromTopLeftRect: rect)
  }

  private static func defaultPanelSize(for contentSize: CGSize) -> CGSize {
    CGSize(
      width: contentSize.width + (EmojiMatchPanelChrome.contentPadding * 2),
      height: contentSize.height + (EmojiMatchPanelChrome.contentPadding * 2)
    )
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func resignKey() {
    super.resignKey()
    close()
  }
}

private enum AccessibilityCoordinateConverter {
  static func appKitRect(fromTopLeftRect rect: CGRect) -> CGRect {
    let baselineY = primaryScreenFrame().maxY

    // AX-style bounds use a top-left origin anchored to the primary display, not the union of every
    // attached display. Using the union breaks whenever an external screen sits above the built-in.
    return CGRect(
      x: rect.minX,
      y: baselineY - rect.maxY,
      width: rect.width,
      height: rect.height
    )
  }

  private static func primaryScreenFrame() -> CGRect {
    NSScreen.screens.first { $0.frame.origin == .zero }?.frame
      ?? NSScreen.main?.frame
      ?? NSScreen.screens.first?.frame
      ?? .zero
  }
}

private struct EmojiMatchPanelSurface<Content: View>: View {
  let contentWidth: CGFloat
  @ViewBuilder let content: () -> Content

  var body: some View {
    content()
      .frame(width: contentWidth, alignment: .leading)
      .padding(EmojiMatchPanelChrome.contentPadding)
      .background(panelBackground)
      .overlay(panelBorder)
      .fixedSize()
  }

  @ViewBuilder
  private var panelBackground: some View {
    EmojiMatchPanelMaterialView()
      .clipShape(
        RoundedRectangle(
          cornerRadius: EmojiMatchPanelChrome.cornerRadius,
          style: .continuous
        )
      )
  }

  @ViewBuilder
  private var panelBorder: some View {
    RoundedRectangle(cornerRadius: EmojiMatchPanelChrome.cornerRadius, style: .continuous)
      .stroke(Color.white.opacity(0.14), lineWidth: 1)
  }
}

private struct EmojiMatchPanelMaterialView: NSViewRepresentable {
  func makeNSView(context: Context) -> NSGlassEffectView {
    let view = NSGlassEffectView()
    view.style = .regular
    view.cornerRadius = EmojiMatchPanelChrome.cornerRadius
    return view
  }

  func updateNSView(_ nsView: NSGlassEffectView, context: Context) {
    nsView.style = .regular
    nsView.cornerRadius = EmojiMatchPanelChrome.cornerRadius
  }
}

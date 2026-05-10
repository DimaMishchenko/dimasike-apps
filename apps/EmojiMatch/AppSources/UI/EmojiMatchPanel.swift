import AppKit
import DesignSystem
import SwiftUI

private enum EmojiMatchPanelMetrics {
  static let panelInset: CGFloat = .ds.spacing.xxs
}

@MainActor
final class EmojiMatchPanel<Content: View>: NSPanel {
  private enum ResizeAnchor {
    case top
    case bottom
  }

  private let initialContentSize: CGSize
  private let maximumContentSize: CGSize
  private let onClose: () -> Void
  // Keeps the caret-facing edge fixed when the launcher expands into the emoji library.
  private var resizeAnchor = ResizeAnchor.bottom

  init(
    initialContentSize: CGSize,
    maximumContentSize: CGSize? = nil,
    onClose: @escaping () -> Void = {},
    @ViewBuilder content:
      @escaping (
        _ close: @escaping () -> Void,
        _ setExpanded: @escaping (Bool) -> Void
      ) -> Content
  ) {
    self.initialContentSize = initialContentSize
    self.maximumContentSize = maximumContentSize ?? initialContentSize
    self.onClose = onClose

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
    contentView = NSHostingView(
      rootView: EmojiMatchPanelSurface(
        contentWidth: initialContentSize.width,
        minimumContentHeight: initialContentSize.height,
        panelInset: EmojiMatchPanelMetrics.panelInset
      ) {
        content(
          { [weak self] in
            self?.close()
          },
          { [weak self] isExpanded in
            self?.setExpanded(isExpanded)
          }
        )
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
    let maximumSize = Self.defaultPanelSize(for: maximumContentSize)
    let x = min(
      max(screenRect.midX - (size.width / 2), visibleFrame.minX),
      visibleFrame.maxX - size.width
    )

    let spacing = CGFloat.ds.spacing.xs
    let preferredAboveY = screenRect.maxY + spacing
    let preferredBelowY = screenRect.minY - size.height - spacing
    let maximumBelowY = screenRect.minY - maximumSize.height - spacing
    let maximumAboveY = preferredAboveY + maximumSize.height
    let availableAbove = visibleFrame.maxY - screenRect.maxY
    let availableBelow = screenRect.minY - visibleFrame.minY
    let y: CGFloat

    if maximumBelowY >= visibleFrame.minY {
      y = preferredBelowY
      resizeAnchor = .top
    } else if maximumAboveY <= visibleFrame.maxY {
      y = preferredAboveY
      resizeAnchor = .bottom
    } else if availableAbove >= availableBelow {
      y = min(max(preferredAboveY, visibleFrame.minY), visibleFrame.maxY - size.height)
      resizeAnchor = .bottom
    } else {
      y = min(max(preferredBelowY, visibleFrame.minY), visibleFrame.maxY - size.height)
      resizeAnchor = .top
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
      width: contentSize.width + (EmojiMatchPanelMetrics.panelInset * 2),
      height: contentSize.height + (EmojiMatchPanelMetrics.panelInset * 2)
    )
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func resignKey() {
    super.resignKey()
    close()
  }

  override func close() {
    super.close()
    onClose()
  }

  private func resize(toContentSize contentSize: CGSize) {
    let normalizedContentSize = CGSize(
      width: initialContentSize.width,
      height: max(contentSize.height, initialContentSize.height)
    )
    let nextSize = Self.defaultPanelSize(for: normalizedContentSize)

    guard abs(frame.width - nextSize.width) > 0.5 || abs(frame.height - nextSize.height) > 0.5
    else {
      return
    }

    let nextY =
      switch resizeAnchor {
      case .top:
        frame.maxY - nextSize.height
      case .bottom:
        frame.minY
      }
    let nextFrame = CGRect(x: frame.minX, y: nextY, width: nextSize.width, height: nextSize.height)
    setFrame(nextFrame, display: true, animate: true)
  }

  private func setExpanded(_ isExpanded: Bool) {
    resize(toContentSize: isExpanded ? maximumContentSize : initialContentSize)
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
  let minimumContentHeight: CGFloat
  let panelInset: CGFloat
  @ViewBuilder let content: () -> Content

  private func panelCornerRadius(for size: CGSize) -> CGFloat {
    size.height > minimumContentHeight + (panelInset * 2) + 1 ? .ds.radius.xl : .ds.radius.full
  }

  var body: some View {
    contentView
      .background(panelBackground)
      .overlay(panelBorder)
      .fixedSize()
  }

  @ViewBuilder
  private var contentView: some View {
    content()
      .frame(width: contentWidth, alignment: .topLeading)
      .frame(minHeight: minimumContentHeight, alignment: .topLeading)
      .padding(panelInset)
      .clipShape(
        RoundedRectangle(
          cornerRadius: .ds.radius.xl,
          style: .continuous
        )
      )
  }

  @ViewBuilder
  private var panelBackground: some View {
    GeometryReader { proxy in
      let radius = panelCornerRadius(for: proxy.size)
      let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

      shape
        .fill(.clear)
        .glassEffect(.regular, in: shape)
        .compositingGroup()
        .clipShape(shape)
    }
  }

  @ViewBuilder
  private var panelBorder: some View {
    GeometryReader { proxy in
      let radius = panelCornerRadius(for: proxy.size)
      let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

      shape.stroke(Color.ds.separator, lineWidth: .ds.stroke.thin)
    }
  }
}

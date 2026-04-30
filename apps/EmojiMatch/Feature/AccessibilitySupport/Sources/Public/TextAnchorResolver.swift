import CoreGraphics

/// Resolves the best available accessibility anchor for the currently focused text input.
public enum TextAnchorResolver {
  private static var locator = TextAnchorLocator()

  /// Returns `nil` when no reliable text anchor is available or Accessibility access is missing.
  public static func anchorRect() -> CGRect? {
    locator.anchorRect()
  }
}

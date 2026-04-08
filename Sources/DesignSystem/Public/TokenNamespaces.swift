import SwiftUI

extension Color {
  /// Shared semantic color tokens.
  public static var ds: Colors { Colors.shared }
}

extension Font {
  /// Shared semantic typography tokens.
  public static var ds: Typography { Typography.shared }
}

extension CGFloat {
  /// Namespace for scalar design-system tokens backed by `CGFloat`.
  public struct DesignSystemNamespace {
    /// Shared semantic spacing tokens.
    public var spacing: Spacing { Spacing.shared }
    /// Shared semantic corner radius tokens.
    public var radius: Radius { Radius.shared }
    /// Shared semantic stroke tokens.
    public var stroke: Stroke { Stroke.shared }

    /// Creates the scalar token namespace.
    public init() {}
  }

  /// Shared scalar design-system tokens backed by `CGFloat`.
  public static var ds: DesignSystemNamespace { .init() }
}

extension Double {
  /// Namespace for scalar design-system tokens backed by `Double`.
  public struct DesignSystemNamespace {
    /// Shared semantic motion tokens.
    public var motion: Motion { Motion.shared }

    /// Creates the scalar token namespace.
    public init() {}
  }

  /// Shared scalar design-system tokens backed by `Double`.
  public static var ds: DesignSystemNamespace { .init() }
}

extension Shadow {
  /// Shared semantic elevation tokens.
  public static var ds: Elevation { Elevation.shared }
}

extension View {
  /// Applies a semantic elevation shadow token.
  public func shadow(_ token: Shadow) -> some View {
    shadow(
      color: token.color,
      radius: token.radius,
      x: token.x,
      y: token.y
    )
  }
}

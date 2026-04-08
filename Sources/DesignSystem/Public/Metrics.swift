import SwiftUI

/// Shared spacing values for layout and content rhythm.
public struct Spacing: Sendable, Equatable {
  /// Extra-extra-small spacing.
  public let xxs: CGFloat
  /// Extra-small spacing.
  public let xs: CGFloat
  /// Small spacing.
  public let sm: CGFloat
  /// Medium spacing.
  public let md: CGFloat
  /// Large spacing.
  public let lg: CGFloat
  /// Extra-large spacing.
  public let xl: CGFloat
  /// Extra-extra-large spacing.
  public let xxl: CGFloat
}

/// Shared corner radius values.
public struct Radius: Sendable, Equatable {
  /// Small radius.
  public let sm: CGFloat
  /// Medium radius.
  public let md: CGFloat
  /// Large radius.
  public let lg: CGFloat
  /// Extra-large radius.
  public let xl: CGFloat
  /// Fully rounded radius.
  public let full: CGFloat
}

/// Shared border and rule widths.
public struct Stroke: Sendable, Equatable {
  /// Hairline stroke width.
  public let hairline: CGFloat
  /// Thin stroke width.
  public let thin: CGFloat
  /// Standard stroke width.
  public let regular: CGFloat
  /// Thick stroke width.
  public let thick: CGFloat
}

/// Shared semantic shadow tokens.
public struct Elevation: Sendable, Equatable {
  /// No visible elevation.
  public let flat: Shadow
  /// Subtle lifted elevation.
  public let raised: Shadow
  /// Highest standard elevation.
  public let floating: Shadow
}

/// A single shadow definition used by elevation tokens.
public struct Shadow: Sendable, Equatable {
  /// Shadow color.
  public let color: Color
  /// Blur radius.
  public let radius: CGFloat
  /// Horizontal offset.
  public let x: CGFloat
  /// Vertical offset.
  public let y: CGFloat
}

/// Shared animation timing values.
public struct Motion: Sendable, Equatable {
  /// Fast transition duration.
  public let quick: Double
  /// Default transition duration.
  public let standard: Double
  /// Emphasized transition duration.
  public let emphasis: Double
}

extension Spacing {
  /// Shared spacing tokens.
  static let shared = Spacing.default

  static let `default` = Self(
    xxs: 4,
    xs: 8,
    sm: 12,
    md: 16,
    lg: 20,
    xl: 24,
    xxl: 32
  )
}

extension Radius {
  /// Shared radius tokens.
  static let shared = Radius.default

  static let `default` = Self(
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    full: 999
  )
}

extension Stroke {
  /// Shared stroke tokens.
  static let shared = Stroke.default

  static let `default` = Self(
    hairline: 0.5,
    thin: 1,
    regular: 1.5,
    thick: 2
  )
}

extension Elevation {
  /// Shared elevation tokens.
  static let shared = Elevation.default

  static let `default` = Self(
    flat: .init(color: .clear, radius: .zero, x: .zero, y: .zero),
    raised: .init(color: .black.opacity(0.08), radius: 8, x: .zero, y: 2),
    floating: .init(color: .black.opacity(0.14), radius: 16, x: .zero, y: 6)
  )
}

extension Motion {
  /// Shared motion tokens.
  static let shared = Motion.default

  static let `default` = Self(
    quick: 0.16,
    standard: 0.24,
    emphasis: 0.36
  )
}

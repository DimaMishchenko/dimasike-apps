import Observation
import SwiftUI
import Synchronization

/// Semantic colors used across native controls and app surfaces.
@Observable
public final class Colors: Sendable {
  @ObservationIgnored
  private let primaryStorage: Mutex<PrimaryColors>

  /// Primary interactive brand color.
  public var primary: Color {
    get {
      access(keyPath: \.primary)
      return primaryStorage.withLock(\.primary)
    }
    set {
      withMutation(keyPath: \.primary) {
        withMutation(keyPath: \.onPrimary) {
          let onPrimary = newValue.dsAccessibleForeground
          primaryStorage.withLock {
            $0.primary = newValue
            $0.onPrimary = onPrimary
          }
        }
      }
    }
  }
  /// Readable foreground color for content on top of the primary color.
  public var onPrimary: Color {
    access(keyPath: \.onPrimary)
    return primaryStorage.withLock(\.onPrimary)
  }
  /// Positive feedback color.
  public let success: Color
  /// Caution feedback color.
  public let warning: Color
  /// Destructive feedback color.
  public let danger: Color
  /// Informational feedback color.
  public let info: Color
  /// Root app background color.
  public let background: Color
  /// Default container surface color.
  public let surface: Color
  /// Elevated container surface color.
  public let surfaceElevated: Color
  /// Divider and border color.
  public let separator: Color
  /// Overlay scrim color.
  public let overlay: Color
  /// Primary readable text color.
  public let textPrimary: Color
  /// Secondary readable text color.
  public let textSecondary: Color
  /// Tertiary readable text color.
  public let textTertiary: Color
  /// Default color for tappable links.
  public let link: Color
  /// Disabled content and control color.
  public let disabled: Color
  /// Placeholder content color.
  public let placeholder: Color
  /// Raw palette colors for decorative use.
  public let raw: RawColors

  init(
    primary: Color,
    success: Color,
    warning: Color,
    danger: Color,
    info: Color,
    background: Color,
    surface: Color,
    surfaceElevated: Color,
    separator: Color,
    overlay: Color,
    textPrimary: Color,
    textSecondary: Color,
    textTertiary: Color,
    link: Color,
    disabled: Color,
    placeholder: Color,
    raw: RawColors = .shared
  ) {
    self.primaryStorage = Mutex(.init(primary: primary, onPrimary: primary.dsAccessibleForeground))
    self.success = success
    self.warning = warning
    self.danger = danger
    self.info = info
    self.background = background
    self.surface = surface
    self.surfaceElevated = surfaceElevated
    self.separator = separator
    self.overlay = overlay
    self.textPrimary = textPrimary
    self.textSecondary = textSecondary
    self.textTertiary = textTertiary
    self.link = link
    self.disabled = disabled
    self.placeholder = placeholder
    self.raw = raw
  }
}

private struct PrimaryColors: Sendable {
  var primary: Color
  var onPrimary: Color
}

/// Raw palette colors that intentionally bypass semantic meaning.
public struct RawColors: Sendable {
  /// Raw red palette color.
  public let red: Color = .red
  /// Raw orange palette color.
  public let orange: Color = .orange
  /// Raw yellow palette color.
  public let yellow: Color = .yellow
  /// Raw green palette color.
  public let green: Color = .green
  /// Raw mint palette color.
  public let mint: Color = .mint
  /// Raw teal palette color.
  public let teal: Color = .teal
  /// Raw cyan palette color.
  public let cyan: Color = .cyan
  /// Raw blue palette color.
  public let blue: Color = .blue
  /// Raw indigo palette color.
  public let indigo: Color = .indigo
  /// Raw purple palette color.
  public let purple: Color = .purple
  /// Raw pink palette color.
  public let pink: Color = .pink
  /// Raw brown palette color.
  public let brown: Color = .brown
  /// Raw gray palette color.
  public let gray: Color = .gray
  /// Raw white palette color.
  public let white: Color = .white
  /// Raw black palette color.
  public let black: Color = .black
}

extension Colors {
  /// Shared semantic color tokens.
  public static let shared = Colors.default

  /// Creates the default semantic color set.
  static var `default`: Self {
    Self(
      primary: .blue,
      success: .green,
      warning: .orange,
      danger: .red,
      info: .blue,
      background: .dsSystemBackground,
      surface: .dsSecondarySystemBackground,
      surfaceElevated: .dsTertiarySystemBackground,
      separator: .dsSeparator,
      overlay: .black.opacity(0.16),
      textPrimary: .dsPrimaryText,
      textSecondary: .dsSecondaryText,
      textTertiary: .dsTertiaryText,
      link: .dsLink,
      disabled: .dsDisabled,
      placeholder: .dsPlaceholder
    )
  }
}

extension RawColors {
  static let shared = Self()
}

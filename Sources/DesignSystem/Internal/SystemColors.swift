import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

extension Color {
  static var dsSystemBackground: Self {
    #if os(watchOS)
      dsDarkSystemBackground
    #elseif os(tvOS)
      dsDarkSystemBackground
    #elseif canImport(UIKit)
      Color(uiColor: .systemBackground)
    #elseif canImport(AppKit)
      Color(nsColor: .windowBackgroundColor)
    #else
      .white
    #endif
  }

  static var dsSecondarySystemBackground: Self {
    #if os(watchOS)
      dsDarkSecondarySystemBackground
    #elseif os(tvOS)
      dsDarkSecondarySystemBackground
    #elseif canImport(UIKit)
      Color(uiColor: .secondarySystemBackground)
    #elseif canImport(AppKit)
      Color(nsColor: .controlBackgroundColor)
    #else
      .gray.opacity(0.1)
    #endif
  }

  static var dsTertiarySystemBackground: Self {
    #if os(watchOS)
      dsDarkTertiarySystemBackground
    #elseif os(tvOS)
      dsDarkTertiarySystemBackground
    #elseif canImport(UIKit)
      Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
      Color(nsColor: .underPageBackgroundColor)
    #else
      .gray.opacity(0.08)
    #endif
  }

  static var dsSeparator: Self {
    #if os(watchOS)
      dsDarkSeparator
    #elseif canImport(UIKit)
      Color(uiColor: .separator)
    #elseif canImport(AppKit)
      Color(nsColor: .separatorColor)
    #else
      .gray.opacity(0.3)
    #endif
  }

  static var dsPrimaryText: Self {
    #if os(watchOS)
      dsDarkPrimaryText
    #elseif canImport(UIKit)
      Color(uiColor: .label)
    #elseif canImport(AppKit)
      Color(nsColor: .labelColor)
    #else
      .primary
    #endif
  }

  static var dsSecondaryText: Self {
    #if os(watchOS)
      dsDarkSecondaryText
    #elseif canImport(UIKit)
      Color(uiColor: .secondaryLabel)
    #elseif canImport(AppKit)
      Color(nsColor: .secondaryLabelColor)
    #else
      .secondary
    #endif
  }

  static var dsTertiaryText: Self {
    #if os(watchOS)
      dsDarkTertiaryText
    #elseif canImport(UIKit)
      Color(uiColor: .tertiaryLabel)
    #elseif canImport(AppKit)
      Color(nsColor: .tertiaryLabelColor)
    #else
      .secondary.opacity(0.7)
    #endif
  }

  static var dsLink: Self {
    #if os(watchOS)
      dsDarkLink
    #elseif canImport(UIKit)
      Color(uiColor: .link)
    #elseif canImport(AppKit)
      Color(nsColor: .linkColor)
    #else
      .blue
    #endif
  }

  static var dsDisabled: Self {
    #if os(watchOS)
      dsDarkDisabled
    #elseif canImport(UIKit)
      Color(uiColor: .quaternaryLabel)
    #elseif canImport(AppKit)
      Color(nsColor: .disabledControlTextColor)
    #else
      .secondary.opacity(0.5)
    #endif
  }

  static var dsPlaceholder: Self {
    #if os(watchOS)
      dsDarkPlaceholder
    #elseif canImport(UIKit)
      Color(uiColor: .placeholderText)
    #elseif canImport(AppKit)
      Color(nsColor: .placeholderTextColor)
    #else
      .secondary.opacity(0.7)
    #endif
  }

  var dsAccessibleForeground: Self {
    #if os(watchOS)
      return .white
    #elseif canImport(UIKit)
      let source = UIColor(self)
      return Color(
        uiColor: UIColor { traits in
          source.resolvedColor(with: traits).dsAccessibleForegroundUIColor
        }
      )
    #elseif canImport(AppKit)
      let source = NSColor(self)
      return Color(
        nsColor: NSColor(name: nil) { appearance in
          var foreground = NSColor.white
          appearance.performAsCurrentDrawingAppearance {
            foreground = source.dsAccessibleForegroundNSColor
          }
          return foreground
        }
      )
    #else
      let components = dsSRGBComponents
      return DSColorContrast.isDark(
        red: components.red,
        green: components.green,
        blue: components.blue
      )
        ? .white : .black
    #endif
  }

  private var dsSRGBComponents: (red: Double, green: Double, blue: Double) {
    #if os(watchOS)
      return (1, 1, 1)
    #elseif canImport(UIKit)
      let color = UIColor(self).resolvedColor(with: .current)
      var red: CGFloat = .zero
      var green: CGFloat = .zero
      var blue: CGFloat = .zero
      var alpha: CGFloat = .zero

      if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
        return (Double(red), Double(green), Double(blue))
      }

      let ciColor = CIColor(color: color)
      return (Double(ciColor.red), Double(ciColor.green), Double(ciColor.blue))
    #elseif canImport(AppKit)
      let color = NSColor(self)
      let resolved = color.usingColorSpace(.extendedSRGB) ?? color.usingColorSpace(.deviceRGB)

      guard let resolved else {
        return (1, 1, 1)
      }

      return (
        Double(resolved.redComponent),
        Double(resolved.greenComponent),
        Double(resolved.blueComponent)
      )
    #else
      return (1, 1, 1)
    #endif
  }

  private static let dsDarkSystemBackground = Color(
    red: 0,
    green: 0,
    blue: 0
  )

  private static let dsDarkSecondarySystemBackground = Color(
    red: 28 / 255,
    green: 28 / 255,
    blue: 30 / 255
  )

  private static let dsDarkTertiarySystemBackground = Color(
    red: 44 / 255,
    green: 44 / 255,
    blue: 46 / 255
  )

  private static let dsDarkSeparator = Color(
    red: 84 / 255,
    green: 84 / 255,
    blue: 88 / 255,
    opacity: 0.65
  )

  private static let dsDarkPrimaryText = Color(
    red: 1,
    green: 1,
    blue: 1
  )

  private static let dsDarkSecondaryText = Color(
    red: 235 / 255,
    green: 235 / 255,
    blue: 245 / 255,
    opacity: 0.6
  )

  private static let dsDarkTertiaryText = Color(
    red: 235 / 255,
    green: 235 / 255,
    blue: 245 / 255,
    opacity: 0.3
  )

  private static let dsDarkLink = Color(
    red: 9 / 255,
    green: 132 / 255,
    blue: 255 / 255
  )

  private static let dsDarkDisabled = Color(
    red: 235 / 255,
    green: 235 / 255,
    blue: 245 / 255,
    opacity: 0.18
  )

  private static let dsDarkPlaceholder = Color(
    red: 235 / 255,
    green: 235 / 255,
    blue: 245 / 255,
    opacity: 0.3
  )
}

#if canImport(UIKit)
  private extension UIColor {
    var dsAccessibleForegroundUIColor: UIColor {
      var red: CGFloat = .zero
      var green: CGFloat = .zero
      var blue: CGFloat = .zero
      var alpha: CGFloat = .zero

      if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
        return DSColorContrast.isDark(
          red: Double(red),
          green: Double(green),
          blue: Double(blue)
        )
          ? UIColor.white : UIColor.black
      }

      return UIColor.white
    }
  }
#elseif canImport(AppKit)
  private extension NSColor {
    var dsAccessibleForegroundNSColor: NSColor {
      let resolved = usingColorSpace(.extendedSRGB) ?? usingColorSpace(.deviceRGB)

      guard let resolved else {
        return .black
      }

      return DSColorContrast.isDark(
        red: Double(resolved.redComponent),
        green: Double(resolved.greenComponent),
        blue: Double(resolved.blueComponent)
      )
        ? .white : .black
    }
  }
#endif

private enum DSColorContrast {
  static func isDark(red: Double, green: Double, blue: Double) -> Bool {
    relativeLuminance(red: red, green: green, blue: blue) < 0.45
  }

  static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
    let linearRed = linearizedChannel(red)
    let linearGreen = linearizedChannel(green)
    let linearBlue = linearizedChannel(blue)
    return (0.2126 * linearRed) + (0.7152 * linearGreen) + (0.0722 * linearBlue)
  }

  static func linearizedChannel(_ value: Double) -> Double {
    if value <= 0.039_28 {
      return value / 12.92
    }
    return pow((value + 0.055) / 1.055, 2.4)
  }
}

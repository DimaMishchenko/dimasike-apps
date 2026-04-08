import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

extension Color {
  static var dsSystemBackground: Self {
    #if os(watchOS)
      .black
    #elseif os(tvOS)
      .black
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
      .white.opacity(0.08)
    #elseif os(tvOS)
      .white.opacity(0.08)
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
      .white.opacity(0.12)
    #elseif os(tvOS)
      .white.opacity(0.12)
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
      .white.opacity(0.16)
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
      .primary
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
      .secondary
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
      .secondary.opacity(0.7)
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
      .accentColor
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
      .secondary.opacity(0.5)
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
      .secondary.opacity(0.7)
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

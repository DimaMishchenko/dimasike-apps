import Observation
import SwiftUI
import Synchronization
import Testing

@testable import DesignSystem

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

@Suite struct DesignSystemTests {
  @Test func primaryMutationRecomputesReadableForeground() {
    let colors = makeColors()

    colors.primary = .indigo
    #expect(colorComponents(colors.onPrimary) == whiteComponents)

    colors.primary = .yellow
    #expect(colorComponents(colors.onPrimary) == blackComponents)
  }

  @Test func observingPrimaryInvalidatesWhenPrimaryChanges() {
    let colors = makeColors()
    let changes = Mutex(0)

    withObservationTracking {
      _ = colors.primary
    } onChange: {
      changes.withLock { $0 += 1 }
    }

    colors.primary = .indigo

    #expect(changes.withLock(\.self) == 1)
  }

  @Test func observingOnPrimaryInvalidatesWhenPrimaryChanges() {
    let colors = makeColors()
    let changes = Mutex(0)

    withObservationTracking {
      _ = colors.onPrimary
    } onChange: {
      changes.withLock { $0 += 1 }
    }

    colors.primary = .yellow

    #expect(changes.withLock(\.self) == 1)
  }

  @Test func observingUnrelatedTokenDoesNotInvalidateWhenPrimaryChanges() {
    let colors = makeColors()
    let changes = Mutex(0)

    withObservationTracking {
      _ = colors.success
    } onChange: {
      changes.withLock { $0 += 1 }
    }

    colors.primary = .yellow

    #expect(changes.withLock(\.self) == 0)
  }
}

private func makeColors() -> Colors {
  Colors(
    primary: .blue,
    success: .green,
    warning: .orange,
    danger: .red,
    info: .cyan,
    background: .white,
    surface: .gray.opacity(0.1),
    surfaceElevated: .gray.opacity(0.2),
    separator: .gray.opacity(0.3),
    overlay: .black.opacity(0.16),
    textPrimary: .black,
    textSecondary: .gray,
    textTertiary: .gray.opacity(0.7),
    link: .blue,
    disabled: .gray.opacity(0.5),
    placeholder: .gray.opacity(0.7)
  )
}

private let whiteComponents = ColorComponents(red: 1, green: 1, blue: 1)
private let blackComponents = ColorComponents(red: 0, green: 0, blue: 0)

private struct ColorComponents: Equatable {
  let red: CGFloat
  let green: CGFloat
  let blue: CGFloat
}

private func colorComponents(_ color: Color) -> ColorComponents {
  #if canImport(UIKit)
    let platformColor = UIColor(color).resolvedColor(with: .current)
    var red: CGFloat = .zero
    var green: CGFloat = .zero
    var blue: CGFloat = .zero
    var alpha: CGFloat = .zero
    let converted = platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    #expect(converted)
    return ColorComponents(red: red, green: green, blue: blue)
  #elseif canImport(AppKit)
    let platformColor = NSColor(color).usingColorSpace(.deviceRGB)
    #expect(platformColor != nil)
    return ColorComponents(
      red: platformColor?.redComponent ?? .zero,
      green: platformColor?.greenComponent ?? .zero,
      blue: platformColor?.blueComponent ?? .zero
    )
  #else
    Issue.record("Unsupported platform for color component extraction.")
    return blackComponents
  #endif
}

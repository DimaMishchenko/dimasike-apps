import DesignSystem
import Foundation
import SwiftUI

enum CatalogCategory: String, CaseIterable, Hashable, Identifiable {
  case colors
  case typography
  case gradients
  case spacing
  case radius
  case stroke
  case elevation
  case motion

  var id: Self { self }

  var title: String {
    switch self {
    case .colors:
      "Colors"
    case .typography:
      "Typography"
    case .gradients:
      "Gradients"
    case .spacing:
      "Spacing"
    case .radius:
      "Radius"
    case .stroke:
      "Stroke"
    case .elevation:
      "Elevation"
    case .motion:
      "Motion"
    }
  }

  var summary: String {
    switch self {
    case .colors:
      "Semantic colors, palette colors, and accessibility foregrounds."
    case .typography:
      "Native text styles mapped through design-system tokens."
    case .gradients:
      "Shared decorative gradients for expressive surfaces and headlines."
    case .spacing:
      "Layout rhythm and content spacing scale."
    case .radius:
      "Corner radius values for containers and controls."
    case .stroke:
      "Border widths for separators, outlines, and emphasis."
    case .elevation:
      "Shadow treatments for flat, raised, and floating surfaces."
    case .motion:
      "Shared durations for subtle transitions and feedback."
    }
  }
}

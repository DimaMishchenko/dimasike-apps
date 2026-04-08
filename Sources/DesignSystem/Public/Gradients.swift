import SwiftUI

/// Predefined gradient presets for shared visual treatments.
public struct Gradients {
  /// A soft multi-stop gradient inspired by the Apple Intelligence mark.
  public var intelligence: Gradient {
    .init(
      stops: [
        .init(color: .ds.raw.blue, location: 0.00),
        .init(color: .ds.raw.indigo, location: 0.18),
        .init(color: .ds.raw.purple, location: 0.38),
        .init(color: .ds.raw.pink, location: 0.56),
        .init(color: .ds.raw.red, location: 0.74),
        .init(color: .ds.raw.orange, location: 0.90),
        .init(color: .ds.raw.yellow, location: 1.00)
      ]
    )
  }

  /// Creates the gradient preset collection.
  public init() {}
}

extension Gradient {
  /// Shared predefined design-system gradients.
  public static var ds: Gradients { .init() }
}

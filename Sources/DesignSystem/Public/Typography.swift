import SwiftUI

/// Semantic typography roles mapped to native text styles.
public struct Typography: Sendable {
  /// Largest display title.
  public let largeTitle: Font
  /// Primary title style.
  public let title: Font
  /// Secondary title style.
  public let title2: Font
  /// Tertiary title style.
  public let title3: Font
  /// Emphasized section heading.
  public let headline: Font
  /// Default reading text.
  public let body: Font
  /// Supporting emphasized body text.
  public let callout: Font
  /// Compact supporting text.
  public let subheadline: Font
  /// Fine-print text.
  public let footnote: Font
  /// Small annotation text.
  public let caption: Font
  /// Smallest annotation text.
  public let caption2: Font

  init(
    largeTitle: Font,
    title: Font,
    title2: Font,
    title3: Font,
    headline: Font,
    body: Font,
    callout: Font,
    subheadline: Font,
    footnote: Font,
    caption: Font,
    caption2: Font
  ) {
    self.largeTitle = largeTitle
    self.title = title
    self.title2 = title2
    self.title3 = title3
    self.headline = headline
    self.body = body
    self.callout = callout
    self.subheadline = subheadline
    self.footnote = footnote
    self.caption = caption
    self.caption2 = caption2
  }
}

extension Typography {
  /// Shared semantic typography tokens.
  static let shared = Typography.default

  static let `default` = Self(
    largeTitle: .largeTitle,
    title: .title,
    title2: .title2,
    title3: .title3,
    headline: .headline,
    body: .body,
    callout: .callout,
    subheadline: .subheadline,
    footnote: .footnote,
    caption: .caption,
    caption2: .caption2
  )
}

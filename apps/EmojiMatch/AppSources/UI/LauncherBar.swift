import DesignSystem
import SwiftUI

struct LauncherBar: View {
  private enum Constants {
    static let barHeight: CGFloat = 44
    static let fieldHeight: CGFloat = 24
    static let librarySpacing: CGFloat = .ds.spacing.md
    static let horizontalContentInset: CGFloat = .ds.spacing.xs

    static var expandedHeight: CGFloat {
      barHeight + librarySpacing + EmojiLibraryView.preferredHeight
    }
  }

  static func maximumContentSize(width: CGFloat) -> CGSize {
    CGSize(
      width: width,
      height: Constants.expandedHeight
    )
  }

  let contentWidth: CGFloat
  let onSubmit: () -> Void
  let onSelectEmoji: (String) -> Void
  let onOpenLibrary: () -> Void

  @State private var query = ""
  @State private var isLibraryPresented = false

  var body: some View {
    ZStack(alignment: .top) {
      if isLibraryPresented {
        EmojiLibraryView(
          contentWidth: contentWidth,
          horizontalContentInset: Constants.horizontalContentInset,
          topContentInset: Constants.barHeight + Constants.librarySpacing,
          onSelectEmoji: onSelectEmoji
        )
        .frame(height: Constants.expandedHeight)
      }

      topBar
    }
    .frame(
      width: contentWidth,
      height: isLibraryPresented ? Constants.expandedHeight : Constants.barHeight,
      alignment: .top
    )
  }

  private var topBar: some View {
    GlassEffectContainer(spacing: .ds.spacing.xs) {
      HStack(spacing: .ds.spacing.xs) {
        searchField

        if !isLibraryPresented {
          libraryButton
        }
      }
    }
    .padding(.horizontal, Constants.horizontalContentInset)
    .frame(
      width: contentWidth,
      height: Constants.barHeight,
      alignment: .leading
    )
  }

  private var searchField: some View {
    HStack(spacing: .ds.spacing.xs) {
      Image(systemName: "magnifyingglass")
        .font(.ds.body.weight(.medium))
        .foregroundStyle(Color.ds.textSecondary)

      TextField(String(localized: .launcherSearchPlaceholder), text: $query)
        .textFieldStyle(.plain)
        .font(.ds.body.weight(.medium))
        .foregroundStyle(Color.ds.textPrimary)
        .onSubmit {
          onSubmit()
        }
        .onKeyPress(.tab) {
          openLibrary()
          return .handled
        }
    }
    .padding(.horizontal, .ds.spacing.sm)
    .padding(.vertical, .ds.spacing.xs)
    .frame(
      maxWidth: .infinity,
      minHeight: Constants.fieldHeight,
      alignment: .leading
    )
    .glassEffect(.clear, in: Capsule(style: .continuous))
  }

  private var libraryButton: some View {
    let size = Constants.fieldHeight + .ds.spacing.xs

    return Button {
      openLibrary()
    } label: {
      HStack(spacing: .ds.spacing.xxs) {
        Image(systemName: "arrow.right.to.line")

        Text(String(localized: .launcherLibraryButtonTitle))
      }
      .font(.ds.callout.weight(.medium))
      .foregroundStyle(Color.ds.textSecondary)
      .padding(.horizontal, .ds.spacing.xs)
      .frame(height: size)
      .contentShape(Capsule(style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(String(localized: .launcherLibraryButtonLabel))
    .accessibilityHint(String(localized: .launcherLibraryButtonHint))
    .help(String(localized: .launcherLibraryButtonLabel))
    .glassEffect(.clear.interactive(true), in: Capsule(style: .continuous))
  }

  private func openLibrary() {
    guard !isLibraryPresented else {
      return
    }

    isLibraryPresented = true
    onOpenLibrary()
  }
}

#Preview {
  VStack {
    Spacer()
      .frame(height: .ds.spacing.xs)
    LauncherBar(
      contentWidth: 324,
      onSubmit: {},
      onSelectEmoji: { _ in },
      onOpenLibrary: {}
    )
    .frame(width: 324)
  }
}

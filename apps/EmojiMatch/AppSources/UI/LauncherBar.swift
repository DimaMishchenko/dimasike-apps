import DesignSystem
import SwiftUI

struct LauncherBar: View {
  private enum Constants {
    static let fieldHeight: CGFloat = 24
  }

  let onSubmit: () -> Void
  let onOpenLibrary: () -> Void

  @State private var query = ""

  var body: some View {
    GlassEffectContainer(spacing: .ds.spacing.xs) {
      HStack(spacing: .ds.spacing.xs) {
        searchField
        libraryButton
      }
    }
    .frame(
      maxWidth: .infinity,
      minHeight: Constants.fieldHeight,
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

    return Button(action: onOpenLibrary) {
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
    .keyboardShortcut(.tab, modifiers: [])
    .accessibilityLabel(String(localized: .launcherLibraryButtonLabel))
    .accessibilityHint(String(localized: .launcherLibraryButtonHint))
    .help(String(localized: .launcherLibraryButtonLabel))
    .glassEffect(.clear.interactive(true), in: Capsule(style: .continuous))
  }
}

#Preview {
  VStack {
    Spacer()
      .frame(height: .ds.spacing.xs)
    LauncherBar(onSubmit: {}, onOpenLibrary: {})
      .frame(width: 344)
  }
}

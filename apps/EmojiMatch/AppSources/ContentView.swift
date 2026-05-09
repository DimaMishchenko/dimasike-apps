import DesignSystem
import SwiftUI

struct ContentView: View {
  let onSubmit: () -> Void
  @State private var query = ""
  private let colors = Color.ds

  var body: some View {
    HStack(spacing: .ds.spacing.xs) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(colors.textSecondary)

      TextField(String(localized: .launcherSearchPlaceholder), text: $query)
        .textFieldStyle(.plain)
        .font(.ds.body)
        .foregroundStyle(colors.textPrimary)
        .onSubmit {
          onSubmit()
        }
    }
    .padding(.horizontal, .ds.spacing.md)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    .background(
      Capsule(style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay(
          Capsule(style: .continuous)
            .fill(Color.white.opacity(0.08))
        )
        .overlay(
          Capsule(style: .continuous)
            .stroke(Color.white.opacity(0.14), lineWidth: .ds.stroke.thin)
        )
    )
  }
}

#Preview {
  VStack {
    Spacer()
      .frame(height: 8)
    ContentView(onSubmit: {})
      .frame(width: 344)
  }
}

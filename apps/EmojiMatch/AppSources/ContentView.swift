import DesignSystem
import SwiftUI

struct ContentView: View {
  let onSubmit: () -> Void
  @State private var query = ""
  private let colors = Color.ds

  var body: some View {
    TextField(String(localized: .launcherSearchPlaceholder), text: $query)
      .textFieldStyle(.plain)
      .font(.ds.body)
      .padding(.horizontal, .ds.spacing.sm)
      .padding(.vertical, .ds.spacing.xs)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(
        RoundedRectangle(cornerRadius: .ds.radius.md, style: .continuous)
          .fill(colors.surface)
          .overlay(
            RoundedRectangle(cornerRadius: .ds.radius.md, style: .continuous)
              .stroke(colors.separator, lineWidth: .ds.stroke.thin)
          )
      )
      .padding(.horizontal, .ds.spacing.sm)
      .padding(.vertical, .ds.spacing.xs)
      .onSubmit {
        onSubmit()
      }
      .ignoresSafeArea()
  }
}

#Preview {
  VStack {
    Spacer()
      .frame(height: 8)
    ContentView(onSubmit: {})
      .frame(width: 360, height: 44)
  }
}

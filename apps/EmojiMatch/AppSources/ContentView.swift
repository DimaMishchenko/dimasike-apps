import DesignSystem
import SwiftUI

struct ContentView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  @FocusState private var isSearchFocused: Bool
  private let colors = Color.ds

  var body: some View {
    TextField(String(localized: .launcherSearchPlaceholder), text: $query)
      .textFieldStyle(.plain)
      .font(.ds.body)
      .focused($isSearchFocused)
      .padding(.horizontal, .ds.spacing.sm)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onSubmit {
        dismiss()
      }
      .onAppear {
        isSearchFocused = true
      }
      .ignoresSafeArea()
  }
}

#Preview {
  ContentView()
    .padding(.top, 1)
    .frame(width: 360, height: 44)
    .hideWindowButtons()
}

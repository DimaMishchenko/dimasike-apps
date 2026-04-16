import DesignSystem
import SwiftUI

struct RootView: View {
  @State private var path: [CatalogCategory] = []
  var body: some View {
    NavigationStack(path: $path) {
      rootContent
    }
    .onAppear {
      Colors.shared.primary = .blue
    }
  }

  private var rootContent: some View {
    catalogList
      .navigationTitle("Design System")
      .navigationDestination(for: CatalogCategory.self) { category in
        CategoryView(category: category)
      }
  }

  private var catalogList: some View {
    let list = List(CatalogCategory.allCases) { category in
      NavigationLink(value: category) {
        CategoryRow(category: category)
      }
      .listRowBackground(Color.ds.surface)
    }
    .background(Color.ds.background.ignoresSafeArea())

    #if os(tvOS)
      return list
    #else
      return list.scrollContentBackground(.hidden)
    #endif
  }
}

private struct CategoryRow: View {
  let category: CatalogCategory

  var body: some View {
    VStack(alignment: .leading, spacing: .ds.spacing.xs) {
      Text(category.title)
        .font(.ds.headline)
        .foregroundStyle(Color.ds.textPrimary)

      Text(category.summary)
        .font(.ds.subheadline)
        .foregroundStyle(Color.ds.textSecondary)
    }
    .padding(.vertical, .ds.spacing.xxs)
  }
}

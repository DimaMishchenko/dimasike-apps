import DesignSystem
import SwiftUI

@main
struct App: SwiftUI.App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .tint(.ds.primary)
    }
  }
}

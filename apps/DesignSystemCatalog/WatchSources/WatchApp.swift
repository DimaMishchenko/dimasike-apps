import DesignSystem
import SwiftUI

@main
struct WatchApp: SwiftUI.App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .tint(.ds.primary)
    }
  }
}

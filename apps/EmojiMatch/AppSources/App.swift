import SwiftUI

@main
struct App: SwiftUI.App {
  private let launcherSize = CGSize(width: 360, height: 24)

  @Environment(\.openWindow) private var openWindow

  var body: some Scene {
    MenuBarExtra("Emoji Match", systemImage: "face.smiling") {
      Button(String(localized: .menuOpen)) {
        openWindow(id: "launcher")
      }

      Divider()

      Button(String(localized: .menuQuit)) {
        NSApp.terminate(nil)
      }
      .keyboardShortcut("q")
    }
    .menuBarExtraStyle(.menu)

    WindowGroup(id: "launcher") {
      ContentView()
        .hideWindowButtons()
        .frame(width: launcherSize.width, height: launcherSize.height)
    }
    .defaultSize(width: launcherSize.width, height: launcherSize.height)
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
  }
}

import AppKit
import SwiftUI

@main
struct App: SwiftUI.App {
  private enum Constants {
    static let launcherSceneID = "launcher"
    static let launcherSize = CGSize(width: 360, height: 24)
  }

  @State private var settings = AppSettings()
  private let systemShortcutMonitor = SystemShortcutMonitor()

  @Environment(\.openWindow) private var openWindow

  var body: some Scene {
    MenuBarExtra {
      Button(String(localized: .menuOpen)) {
        openLauncher()
      }

      Divider()

      Button(String(localized: .menuQuit)) {
        NSApp.terminate(nil)
      }
      .keyboardShortcut("q")
    } label: {
      Label("Emoji Match", systemImage: "face.smiling")
        .task {
          systemShortcutMonitor.start {
            openLauncher()
          }
        }
        .onChange(of: settings.launcherShortcut, initial: true) { _, shortcut in
          systemShortcutMonitor.shortcut = shortcut
        }
    }
    .menuBarExtraStyle(.menu)

    WindowGroup(id: Constants.launcherSceneID) {
      ContentView()
        .hideWindowButtons()
        .frame(width: Constants.launcherSize.width, height: Constants.launcherSize.height)
    }
    .defaultSize(width: Constants.launcherSize.width, height: Constants.launcherSize.height)
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
  }

  private func openLauncher() {
    NSApp.activate(ignoringOtherApps: true)
    openWindow(id: Constants.launcherSceneID)
  }
}

import AccessibilitySupport
import AppKit
import SwiftUI

@main
struct App: SwiftUI.App {
  private enum Constants {
    static let launcherInitialContentSize = CGSize(width: 344, height: 44)
  }

  @State private var settings = AppSettings()
  private let systemShortcutMonitor = SystemShortcutMonitor()

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
  }

  private func openLauncher() {
    AccessibilityPermission.requestIfNeeded()
    let panel = EmojiMatchPanel(initialContentSize: Constants.launcherInitialContentSize) { close in
      LauncherBar(
        onSubmit: {
          close()
          DispatchQueue.main.async {
            guard let emoji = MockRandomEmojiSource.randomEmoji() else {
              return
            }

            TextPasteController.paste(emoji)
          }
        },
        onOpenLibrary: {}
      )
    }
    panel.show(anchorRect: TextAnchorResolver.anchorRect())
  }
}

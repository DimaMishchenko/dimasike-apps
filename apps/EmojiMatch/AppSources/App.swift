import AccessibilitySupport
import AppKit
import SwiftUI

@main
struct App: SwiftUI.App {
  private enum Constants {
    static let launcherInitialContentSize = CGSize(width: 324, height: 44)
    static let launcherMaximumContentSize = LauncherBar.maximumContentSize(
      width: launcherInitialContentSize.width
    )
  }

  @State private var settings = AppSettings()
  @State private var launcherPanel: NSPanel?
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
      Label(String(localized: .appName), systemImage: "face.smiling")
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
    closeExistingLauncher()

    let panel = EmojiMatchPanel(
      initialContentSize: Constants.launcherInitialContentSize,
      maximumContentSize: Constants.launcherMaximumContentSize,
      onClose: {
        launcherPanel = nil
      }
    ) { close, setExpanded in
      LauncherBar(
        contentWidth: Constants.launcherInitialContentSize.width,
        onSubmit: {
          guard let emoji = MockRandomEmojiSource.randomEmoji() else {
            return
          }

          closeAndPaste(emoji, close: close)
        },
        onSelectEmoji: { emoji in
          closeAndPaste(emoji, close: close)
        },
        onOpenLibrary: {
          setExpanded(true)
        }
      )
    }
    launcherPanel = panel
    panel.show(anchorRect: TextAnchorResolver.anchorRect())
  }

  private func closeExistingLauncher() {
    guard let launcherPanel else {
      return
    }

    // `onClose` clears the stored panel after it closes. This handles the separate case where the
    // launcher shortcut is triggered again while the previous panel is still open.
    launcherPanel.close()
  }

  private func closeAndPaste(_ emoji: String, close: () -> Void) {
    close()
    DispatchQueue.main.async {
      TextPasteController.paste(emoji)
    }
  }
}

import Carbon.HIToolbox
import Observation

@MainActor
@Observable
final class AppSettings {
  struct Shortcut: Equatable {
    let keyCode: UInt32
    let carbonModifiers: UInt32

    static let defaultLauncher = Shortcut(
      keyCode: UInt32(kVK_ANSI_E),
      carbonModifiers: UInt32(cmdKey | shiftKey)
    )
  }

  var launcherShortcut = Shortcut.defaultLauncher
}

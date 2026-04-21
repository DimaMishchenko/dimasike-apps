import Carbon.HIToolbox
import Foundation

final class SystemShortcutMonitor {
  private var eventHandler: EventHandlerRef?
  private var hotKey: EventHotKeyRef?
  private var isStarted = false
  private var onKeyDown: (() -> Void)?
  var shortcut = AppSettings.Shortcut.defaultLauncher {
    didSet {
      guard shortcut != oldValue, isStarted else {
        return
      }

      unregisterHotKey()
      registerHotKey()
    }
  }

  func start(onKeyDown: @escaping () -> Void) {
    guard !isStarted else {
      self.onKeyDown = onKeyDown
      return
    }

    isStarted = true
    self.onKeyDown = onKeyDown

    var eventSpec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)
    )

    let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

    InstallEventHandler(
      GetApplicationEventTarget(),
      systemShortcutEventHandler,
      1,
      &eventSpec,
      userData,
      &eventHandler
    )

    registerHotKey()
  }

  fileprivate func handleHotKey() {
    onKeyDown?()
  }

  private func registerHotKey() {
    let hotKeyID = EventHotKeyID(
      signature: emojiMatchShortcutSignature,
      id: systemShortcutIdentifier
    )

    RegisterEventHotKey(
      shortcut.keyCode,
      shortcut.carbonModifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKey
    )
  }

  private func unregisterHotKey() {
    guard let hotKey else {
      return
    }

    UnregisterEventHotKey(hotKey)
    self.hotKey = nil
  }

  deinit {
    if let hotKey {
      UnregisterEventHotKey(hotKey)
    }

    if let eventHandler {
      RemoveEventHandler(eventHandler)
    }
  }
}

private let systemShortcutIdentifier: UInt32 = 1
// Carbon uses a four-char signature; "EMAT" is short for Emoji Match.
private let emojiMatchShortcutSignature = fourCharCode("EMAT")

private let systemShortcutEventHandler: EventHandlerUPP = { _, event, userData in
  guard let event else {
    return noErr
  }

  var hotKeyID = EventHotKeyID()
  let status = GetEventParameter(
    event,
    EventParamName(kEventParamDirectObject),
    EventParamType(typeEventHotKeyID),
    nil,
    MemoryLayout<EventHotKeyID>.size,
    nil,
    &hotKeyID
  )

  guard status == noErr,
    hotKeyID.signature == emojiMatchShortcutSignature,
    hotKeyID.id == systemShortcutIdentifier
  else {
    return noErr
  }

  guard let userData else {
    return noErr
  }

  let monitor = Unmanaged<SystemShortcutMonitor>.fromOpaque(userData).takeUnretainedValue()
  Task { @MainActor in
    monitor.handleHotKey()
  }

  return noErr
}

private func fourCharCode(_ string: StaticString) -> OSType {
  string.withUTF8Buffer { buffer in
    buffer.reduce(into: OSType(0)) { result, byte in
      result = (result << 8) | OSType(byte)
    }
  }
}

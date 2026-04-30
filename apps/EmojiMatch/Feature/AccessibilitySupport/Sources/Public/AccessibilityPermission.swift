import ApplicationServices

/// Handles macOS Accessibility permission checks for launcher features that depend on AX.
public enum AccessibilityPermission {
  /// The current Accessibility trust state for this app process.
  public enum Status: Equatable {
    case granted
    case notGranted
  }

  /// Returns the current Accessibility permission state for this app process.
  public static var status: Status {
    AXIsProcessTrusted() ? .granted : .notGranted
  }

  /// Returns `true` when the app already has Accessibility access.
  public static var isGranted: Bool {
    status == .granted
  }

  /// Prompts for Accessibility access when it is not granted yet.
  @discardableResult
  public static func requestIfNeeded() -> Status {
    guard !isGranted else {
      return .granted
    }

    let options =
      [
        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
      ] as CFDictionary
    AXIsProcessTrustedWithOptions(options)

    return status
  }
}

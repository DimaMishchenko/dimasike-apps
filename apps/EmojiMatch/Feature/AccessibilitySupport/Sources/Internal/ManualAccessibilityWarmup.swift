import AppKit
import ApplicationServices
import Darwin

struct ManualAccessibilityWarmup {
  private enum Constants {
    static let manualAccessibilityAttribute = "AXManualAccessibility" as CFString
  }

  private var warmedProcessIdentifiers: Set<pid_t> = []

  mutating func prepareFrontmostApplication() -> Bool {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      return false
    }

    pruneTerminatedProcesses()

    let processIdentifier = frontmostApplication.processIdentifier
    guard warmedProcessIdentifiers.insert(processIdentifier).inserted else {
      return false
    }

    let applicationElement = AXUIElementCreateApplication(processIdentifier)
    AXUIElementSetAttributeValue(
      applicationElement,
      Constants.manualAccessibilityAttribute,
      kCFBooleanTrue
    )

    return true
  }

  mutating func pruneTerminatedProcesses() {
    warmedProcessIdentifiers = warmedProcessIdentifiers.filter(Self.isRunningProcess)
  }

  nonisolated static func isRunningProcess(_ processIdentifier: pid_t) -> Bool {
    let status = Darwin.kill(processIdentifier, 0)
    return status == 0 || errno == EPERM
  }
}

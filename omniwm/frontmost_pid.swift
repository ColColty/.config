import AppKit
// Prints "<pid> <bundle-id>" of the frontmost application (lsappinfo is unreliable from agents).
if let a = NSWorkspace.shared.frontmostApplication { print("\(a.processIdentifier) \(a.bundleIdentifier ?? "-")") } else { exit(1) }

import Cocoa
import ApplicationServices
// usage: place_window <pct>
// Reads "app-pid|window-id" lines from stdin and, for each, sizes that window to
// pct% of the visible area of the screen under the mouse and centres it there.
// Started before the caller's own work so the AppKit startup and screen lookup
// overlap with it; the first line arriving is what triggers the placement.
// Windows are matched by CGWindowID (AeroSpace's window-id) via the same private
// symbol AeroSpace and yabai use, so title changes do not matter.

@_silgen_name("_AXUIElementGetWindow") @discardableResult
func _AXUIElementGetWindow(_ element: AXUIElement, _ wid: UnsafeMutablePointer<CGWindowID>) -> AXError

let a = CommandLine.arguments
guard a.count >= 2, let pct = Double(a[1]) else { exit(2) }

let mouse = NSEvent.mouseLocation
let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main!
let full = NSScreen.screens[0].frame
let v = screen.visibleFrame
let X = v.origin.x, Y = full.height - (v.origin.y + v.height), W = v.width, H = v.height
let w = (W * pct / 100).rounded(), h = (H * pct / 100).rounded()

func attr(_ e: AXUIElement, _ k: String) -> CFTypeRef? { var r: CFTypeRef?; AXUIElementCopyAttributeValue(e, k as CFString, &r); return r }
func element(_ r: CFTypeRef?) -> AXUIElement? {
  guard let r = r, CFGetTypeID(r) == AXUIElementGetTypeID() else { return nil }
  return unsafeBitCast(r, to: AXUIElement.self)
}
func windowID(_ e: AXUIElement) -> CGWindowID { var id: CGWindowID = 0; _AXUIElementGetWindow(e, &id); return id }

func find(pid: Int32, wid: CGWindowID) -> AXUIElement? {
  let app = AXUIElementCreateApplication(pid)
  // Usual case: the caller just focused this window, one round trip.
  if let f = element(attr(app, kAXFocusedWindowAttribute)), windowID(f) == wid { return f }
  guard let wins = attr(app, kAXWindowsAttribute) as? [AXUIElement] else { return nil }
  return wins.first { windowID($0) == wid }
}

func axSize(_ win: AXUIElement) -> CGSize? {
  guard let v = attr(win, kAXSizeAttribute), CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
  var s = CGSize.zero; AXValueGetValue(unsafeBitCast(v, to: AXValue.self), .cgSize, &s); return s
}
func axPos(_ win: AXUIElement) -> CGPoint? {
  guard let v = attr(win, kAXPositionAttribute), CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
  var p = CGPoint.zero; AXValueGetValue(unsafeBitCast(v, to: AXValue.self), .cgPoint, &p); return p
}
func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) <= 2 }

// AeroSpace restores a freshly un-hidden window's frame asynchronously, shortly
// after the move command has returned, and would overwrite a single set. So set,
// then keep checking for a moment and re-apply until the frame has stayed put.
func place(_ win: AXUIElement) {
  let deadline = Date().addingTimeInterval(0.3)
  var stable = 0
  repeat {
    var size = CGSize(width: w, height: h)
    if let val = AXValueCreate(.cgSize, &size) { AXUIElementSetAttributeValue(win, kAXSizeAttribute as CFString, val) }
    // apps with a minimum size may refuse; centre using the size they actually took
    let real = axSize(win) ?? size
    var pos = CGPoint(x: (X + (W - real.width) / 2).rounded(), y: (Y + (H - real.height) / 2).rounded())
    if let val = AXValueCreate(.cgPoint, &pos) { AXUIElementSetAttributeValue(win, kAXPositionAttribute as CFString, val) }
    usleep(20_000)
    if let s = axSize(win), let p = axPos(win),
       near(s.width, real.width), near(s.height, real.height), near(p.x, pos.x), near(p.y, pos.y) { stable += 1 } else { stable = 0 }
  } while stable < 2 && Date() < deadline
}

while let line = readLine() {
  let p = line.split(separator: "|")
  guard p.count == 2, let pid = Int32(p[0]), let wid = CGWindowID(p[1]) else { continue }
  if let win = find(pid: pid, wid: wid) { place(win) }
}

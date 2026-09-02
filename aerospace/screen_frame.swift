import Cocoa
// Prints "x y w h" of the visible area of the screen under the mouse, top-left origin (System Events coordinates).
let mouse = NSEvent.mouseLocation
let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main!
let full = NSScreen.screens[0].frame  // primary screen defines the flipped coordinate space
let v = screen.visibleFrame
let topY = full.height - (v.origin.y + v.height)
print("\(Int(v.origin.x)) \(Int(topY)) \(Int(v.width)) \(Int(v.height))")

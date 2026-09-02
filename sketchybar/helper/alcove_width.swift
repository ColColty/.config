import Cocoa
// Prints the widest on-screen window owned by Alcove (the notch companion), or 0.
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
var w: Double = 0
for win in list where (win[kCGWindowOwnerName as String] as? String) == "Alcove" {
  let b = win[kCGWindowBounds as String] as! [String: Any]
  if (b["Y"] as! Double) < 60 { w = max(w, b["Width"] as! Double) }
}
print(Int(w))

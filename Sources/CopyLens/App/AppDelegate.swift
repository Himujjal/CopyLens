import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    // LSUIElement (set in Info.plist) already hides the dock icon; this is
    // belt-and-suspenders for the bare-`swift run` dev path.
    NSApp.setActivationPolicy(.accessory)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep the menu-bar app alive when the settings window closes.
    false
  }
}

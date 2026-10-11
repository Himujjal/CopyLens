import AppKit
import Foundation

/// Writes recognized text to the general pasteboard.
final class ClipboardService {
  func copy(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
  }
}

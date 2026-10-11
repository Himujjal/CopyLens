import AppKit
import CoreGraphics
import Foundation

/// Orchestrates the capture flow: request screen-recording permission, show the
/// selection overlay, capture the chosen region, and run OCR on it.
final class CaptureService {
  private let ocrService: OCRService
  private let onCapture: (String, [String], Data?, String?) -> Void
  private var overlayWindow: OverlayWindow?

  init(
    ocrService: OCRService,
    onCapture: @escaping (String, [String], Data?, String?) -> Void
  ) {
    self.ocrService = ocrService
    self.onCapture = onCapture
  }

  /// Entry point from the global hotkey (main thread).
  func startCapture() {
    let frontmostApp = NSWorkspace.shared.frontmostApplication?.localizedName

    guard CGPreflightScreenCaptureAccess() else {
      _ = CGRequestScreenCaptureAccess()
      showPermissionAlert()
      return
    }

    presentOverlay(frontmostApp: frontmostApp)
  }

  private func presentOverlay(frontmostApp: String?) {
    guard overlayWindow == nil else { return }

    let overlay = OverlayWindow()
    overlay.onSelect = { [weak self] rect in
      self?.handleSelection(rect, frontmostApp: frontmostApp)
    }
    overlay.onCancel = { [weak self] in
      self?.dismissOverlay()
    }
    overlayWindow = overlay
    overlay.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func handleSelection(_ rect: CGRect, frontmostApp: String?) {
    guard let overlay = overlayWindow else { return }

    let windowID = CGWindowID(overlay.windowNumber)
    let cgRect = Self.appKitRectToCG(rect)

    // Capture only windows below our overlay so the dim + selection box are
    // never fed into OCR.
    //
    // NOTE: CGWindowListCreateImage is soft-deprecated in favor of
    // ScreenCaptureKit, but it remains the simplest way to capture an
    // arbitrary multi-display region *excluding* our own overlay window.
    // TODO(m2): migrate to SCScreenshotManager.captureImage(in:).
    guard
      let image = CGWindowListCreateImage(
        cgRect,
        .optionOnScreenBelowWindow,
        windowID,
        [.bestResolution]
      )
    else {
      dismissOverlay()
      return
    }

    dismissOverlay()

    let service = ocrService
    let callback = onCapture
    DispatchQueue.global(qos: .userInitiated).async {
      let text = (try? service.recognize(image)) ?? ""
      DispatchQueue.main.async {
        callback(text, [], nil, frontmostApp)
      }
    }
  }

  private func dismissOverlay() {
    overlayWindow?.orderOut(nil)
    overlayWindow = nil
  }

  /// Converts an AppKit screen-space rect (origin bottom-left) to the Core
  /// Graphics global display space (origin top-left) used by
  /// `CGWindowListCreateImage`.
  private static func appKitRectToCG(_ rect: CGRect) -> CGRect {
    guard let main = NSScreen.main else { return rect }
    return CGRect(
      x: rect.minX,
      y: main.frame.height - rect.maxY,
      width: rect.width,
      height: rect.height
    )
  }

  private func showPermissionAlert() {
    let alert = NSAlert()
    alert.messageText = "Screen Recording permission required"
    alert.informativeText =
      "CopyLens needs Screen Recording permission to capture and recognize text on screen. "
      + "Grant it in System Settings, then try again."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Open System Settings")
    alert.addButton(withTitle: "Cancel")

    if alert.runModal() == .alertFirstButtonReturn {
      if let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
      ) {
        NSWorkspace.shared.open(url)
      }
    }
  }
}

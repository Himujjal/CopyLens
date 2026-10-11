import AppKit
import CoreGraphics
import Foundation

/// A transparent, full-screen, borderless window used to select a screen region.
final class OverlayWindow: NSWindow {
  var onSelect: ((CGRect) -> Void)?
  var onCancel: (() -> Void)?

  convenience init() {
    let frame = NSScreen.screens.map(\.frame).reduce(CGRect.zero) { $0.union($1) }
    self.init(
      contentRect: frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    isOpaque = false
    backgroundColor = .clear
    level = .screenSaver
    hasShadow = false
    ignoresMouseEvents = false
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

    let selectionView = SelectionView(frame: frame)
    selectionView.onSelect = { [weak self] rect in self?.onSelect?(rect) }
    selectionView.onCancel = { [weak self] in self?.onCancel?() }
    contentView = selectionView
    makeFirstResponder(selectionView)
  }
}

/// Draws the dim + selection rectangle and tracks the drag gesture.
private final class SelectionView: NSView {
  var onSelect: ((CGRect) -> Void)?
  var onCancel: (() -> Void)?

  private var startPoint: NSPoint?
  private var currentPoint: NSPoint?

  override var acceptsFirstResponder: Bool { true }

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: .crosshair)
  }

  override func mouseDown(with event: NSEvent) {
    NSCursor.crosshair.set()
    startPoint = convert(event.locationInWindow, from: nil)
    currentPoint = startPoint
  }

  override func mouseDragged(with event: NSEvent) {
    currentPoint = convert(event.locationInWindow, from: nil)
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    currentPoint = convert(event.locationInWindow, from: nil)
    if let rect = selectionScreenRect() {
      reset()
      onSelect?(rect)
    } else {
      reset()
      onCancel?()
    }
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 {  // Escape
      reset()
      onCancel?()
    } else {
      super.keyDown(with: event)
    }
  }

  override func cancelOperation(_ sender: Any?) {
    reset()
    onCancel?()
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let dim = NSBezierPath(rect: bounds)
    if let selectionRect {
      dim.appendRect(selectionRect)
    }
    dim.windingRule = .evenOdd
    NSColor.black.withAlphaComponent(0.35).setFill()
    dim.fill()

    if let selectionRect {
      let border = NSBezierPath(rect: selectionRect)
      border.lineWidth = 1
      NSColor.white.withAlphaComponent(0.9).setStroke()
      border.stroke()
    }
  }

  private var selectionRect: CGRect? {
    guard let startPoint, let currentPoint else { return nil }
    return CGRect(
      x: min(startPoint.x, currentPoint.x),
      y: min(startPoint.y, currentPoint.y),
      width: abs(currentPoint.x - startPoint.x),
      height: abs(currentPoint.y - startPoint.y)
    )
  }

  private func selectionScreenRect() -> CGRect? {
    guard let rect = selectionRect, rect.width > 4, rect.height > 4, let window else {
      return nil
    }
    let originInWindow = convert(rect.origin, to: nil)
    let originInScreen = window.convertPoint(toScreen: originInWindow)
    return CGRect(origin: originInScreen, size: rect.size)
  }

  private func reset() {
    startPoint = nil
    currentPoint = nil
    needsDisplay = true
  }
}

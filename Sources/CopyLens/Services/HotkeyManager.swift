import Carbon
import Foundation

/// Registers a system-wide hotkey via Carbon's `RegisterEventHotKey`.
///
/// Unlike `NSEvent` global monitors, Carbon hotkeys do not require
/// Accessibility/Input-Monitoring permission.
final class HotkeyManager {
  private var hotKeyRef: EventHotKeyRef?
  private var eventHandlerRef: EventHandlerRef?
  private let onTrigger: () -> Void

  private static let signature: OSType = 0x434C_4C4E  // 'CLLN'
  private static let hotKeyID: UInt32 = 1

  init(onTrigger: @escaping () -> Void) {
    self.onTrigger = onTrigger
  }

  deinit {
    unregister()
  }

  /// Registers ⇧⌘2 as the global capture hotkey.
  func register() {
    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)
    )

    InstallEventHandler(
      GetApplicationEventTarget(),
      hotKeyPressedHandler,
      1,
      &eventType,
      Unmanaged.passUnretained(self).toOpaque(),
      &eventHandlerRef
    )

    let hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.hotKeyID)
    let modifiers = UInt32(cmdKey | shiftKey)
    RegisterEventHotKey(
      UInt32(kVK_ANSI_2),
      modifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )
  }

  func unregister() {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }
    if let eventHandlerRef {
      RemoveEventHandler(eventHandlerRef)
      self.eventHandlerRef = nil
    }
  }

  func handleTrigger() {
    // Carbon delivers hotkey events on the main run loop, but hop to main
    // explicitly so the callback always runs on the main thread.
    DispatchQueue.main.async { [onTrigger] in
      onTrigger()
    }
  }
}

/// Carbon event-handler callback. A top-level function (not a closure) so it
/// can be passed as a C function pointer.
private func hotKeyPressedHandler(
  _ callRef: EventHandlerCallRef?,
  _ event: EventRef?,
  _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
  guard let userData else { return noErr }
  let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
  manager.handleTrigger()
  return noErr
}

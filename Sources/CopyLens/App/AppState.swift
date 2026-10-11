import Foundation
import SwiftUI

/// Shared application state, owned by the App and injected as an environment
/// object into views.
@MainActor
final class AppState: ObservableObject {
  @Published private(set) var items: [CaptureItem] = []
  @Published var toastMessage: String?

  let settings: AppSettings
  let historyStore: HistoryStore
  let clipboardService = ClipboardService()
  let ocrService: OCRService

  private var hotkeyManager: HotkeyManager?
  private var captureService: CaptureService?

  init(historyStore: HistoryStore? = nil, settings: AppSettings = AppSettings()) {
    self.settings = settings
    self.ocrService = OCRService(recognitionLanguages: settings.ocrLanguages)
    self.historyStore = historyStore ?? HistoryStore(limit: settings.historyLimit)
    self.items = self.historyStore.items

    let captureService = CaptureService(ocrService: ocrService) {
      [weak self] text, languages, thumbnail, appSource in
      self?.recordCapture(text, languages: languages, thumbnail: thumbnail, appSource: appSource)
    }
    self.captureService = captureService

    let hotkeyManager = HotkeyManager { [weak self] in
      self?.captureService?.startCapture()
    }
    self.hotkeyManager = hotkeyManager
    hotkeyManager.register()
  }

  /// Records a successful capture: writes to the clipboard and appends to history.
  func recordCapture(
    _ text: String,
    languages: [String] = [],
    thumbnail: Data? = nil,
    appSource: String? = nil
  ) {
    clipboardService.copy(text)
    historyStore.add(
      text: text,
      languages: languages,
      imageThumbnail: thumbnail,
      appSource: appSource
    )
    items = historyStore.items
    toastMessage = "Copied"
  }

  func reCopy(_ item: CaptureItem) {
    clipboardService.copy(item.text)
    toastMessage = "Copied"
  }

  func delete(_ item: CaptureItem) {
    historyStore.delete(item.id)
    items = historyStore.items
  }

  func clearAll() {
    historyStore.clear()
    items = historyStore.items
  }
}

import Foundation

/// User-configurable settings. Persisted to `UserDefaults` in a later milestone;
/// in-memory defaults are fine for M0.
struct AppSettings: Equatable {
  var ocrLanguages: [String]
  var historyLimit: Int
  var launchAtLogin: Bool
  var autoPaste: Bool

  init(
    ocrLanguages: [String] = ["en-US", "ja-JP"],
    historyLimit: Int = 100,
    launchAtLogin: Bool = false,
    autoPaste: Bool = false
  ) {
    self.ocrLanguages = ocrLanguages
    self.historyLimit = historyLimit
    self.launchAtLogin = launchAtLogin
    self.autoPaste = autoPaste
  }
}

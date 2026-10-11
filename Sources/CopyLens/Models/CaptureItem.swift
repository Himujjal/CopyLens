import Foundation

/// A single captured-and-recognized text item in the history.
struct CaptureItem: Identifiable, Codable, Hashable {
  let id: UUID
  var text: String
  var createdAt: Date
  var languages: [String]
  var imageThumbnail: Data?
  var appSource: String?

  init(
    id: UUID = UUID(),
    text: String,
    createdAt: Date = Date(),
    languages: [String] = [],
    imageThumbnail: Data? = nil,
    appSource: String? = nil
  ) {
    self.id = id
    self.text = text
    self.createdAt = createdAt
    self.languages = languages
    self.imageThumbnail = imageThumbnail
    self.appSource = appSource
  }
}

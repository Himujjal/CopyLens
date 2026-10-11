import Foundation

/// Stores captured items as a JSON array on disk.
///
/// Newest items are at the front of `items`. The store is not thread-safe by
/// itself; callers are expected to use it from the main actor (the app does).
final class HistoryStore {
  private(set) var items: [CaptureItem]

  let limit: Int
  private let fileURL: URL

  init(limit: Int = 100, fileURL: URL = HistoryStore.defaultFileURL()) {
    self.limit = limit
    self.fileURL = fileURL
    self.items = []
    load()
  }

  func add(
    text: String,
    languages: [String] = [],
    imageThumbnail: Data? = nil,
    appSource: String? = nil
  ) {
    let item = CaptureItem(
      text: text,
      languages: languages,
      imageThumbnail: imageThumbnail,
      appSource: appSource
    )
    items.insert(item, at: 0)
    if items.count > limit {
      items = Array(items.prefix(limit))
    }
    persist()
  }

  func delete(_ id: UUID) {
    items.removeAll { $0.id == id }
    persist()
  }

  func clear() {
    items.removeAll()
    persist()
  }

  // MARK: - Persistence

  static func defaultFileURL() -> URL {
    let base =
      FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first ?? FileManager.default.temporaryDirectory
    let directory = base.appendingPathComponent("CopyLens", isDirectory: true)
    return directory.appendingPathComponent("history.json")
  }

  private func load() {
    do {
      let data = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      items = try decoder.decode([CaptureItem].self, from: data)
    } catch {
      items = []
    }
  }

  private func persist() {
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(items)
      try data.write(to: fileURL, options: .atomic)
    } catch {
      // History persistence is best-effort; failures are non-fatal.
    }
  }
}

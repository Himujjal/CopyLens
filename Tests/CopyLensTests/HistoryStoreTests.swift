import XCTest

@testable import CopyLens

final class HistoryStoreTests: XCTestCase {
  private var store: HistoryStore!
  private var directory: URL!

  override func setUp() {
    super.setUp()
    directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    let fileURL = directory.appendingPathComponent("history.json")
    store = HistoryStore(limit: 3, fileURL: fileURL)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: directory)
    super.tearDown()
  }

  func testAddInsertsNewestAtFront() {
    store.add(text: "first")
    store.add(text: "second")
    XCTAssertEqual(store.items.map(\.text), ["second", "first"])
  }

  func testEnforcesLimit() {
    store.add(text: "1")
    store.add(text: "2")
    store.add(text: "3")
    store.add(text: "4")
    XCTAssertEqual(store.items.count, 3)
    XCTAssertEqual(store.items.first?.text, "4")
    XCTAssertEqual(store.items.last?.text, "2")
  }

  func testDeleteRemovesOnlyMatchingItem() {
    store.add(text: "a")
    store.add(text: "b")
    // Newest first: ["b", "a"]. Delete the older item "a".
    let target = store.items[1].id
    store.delete(target)
    XCTAssertEqual(store.items.map(\.text), ["b"])
  }

  func testClearRemovesAll() {
    store.add(text: "a")
    store.add(text: "b")
    store.clear()
    XCTAssertTrue(store.items.isEmpty)
  }

  func testPersistsAcrossInstances() {
    store.add(text: "persisted")
    let fileURL = directory.appendingPathComponent("history.json")
    let reloaded = HistoryStore(limit: 3, fileURL: fileURL)
    XCTAssertEqual(reloaded.items.map(\.text), ["persisted"])
  }

  func testEmptyFileLoadsAsEmpty() {
    XCTAssertTrue(store.items.isEmpty)
  }
}

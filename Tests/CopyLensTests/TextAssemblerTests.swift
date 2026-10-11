import CoreGraphics
import XCTest

@testable import CopyLens

final class TextAssemblerTests: XCTestCase {
  func testAssemblesSingleLineLeftToRight() {
    let fragments = [
      RecognizedTextFragment(
        text: "left", boundingBox: CGRect(x: 0.0, y: 0.4, width: 0.2, height: 0.1)),
      RecognizedTextFragment(
        text: "right", boundingBox: CGRect(x: 0.7, y: 0.4, width: 0.2, height: 0.1)),
    ]
    XCTAssertEqual(TextAssembler.assemble(fragments), "left right")
  }

  func testOrdersLinesTopToBottom() {
    let fragments = [
      RecognizedTextFragment(
        text: "bottom", boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.1)),
      RecognizedTextFragment(
        text: "top", boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.1)),
    ]
    XCTAssertEqual(TextAssembler.assemble(fragments), "top\nbottom")
  }

  func testPreservesMultiLineReadingOrder() {
    // Three visual rows (top → bottom) with two words each, fed out of order.
    let fragments = [
      RecognizedTextFragment(
        text: "a2", boundingBox: CGRect(x: 0.5, y: 0.75, width: 0.1, height: 0.1)),
      RecognizedTextFragment(
        text: "c1", boundingBox: CGRect(x: 0.1, y: 0.25, width: 0.1, height: 0.1)),
      RecognizedTextFragment(
        text: "a1", boundingBox: CGRect(x: 0.1, y: 0.75, width: 0.1, height: 0.1)),
      RecognizedTextFragment(
        text: "b1", boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.1, height: 0.1)),
      RecognizedTextFragment(
        text: "c2", boundingBox: CGRect(x: 0.5, y: 0.25, width: 0.1, height: 0.1)),
      RecognizedTextFragment(
        text: "b2", boundingBox: CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)),
    ]
    XCTAssertEqual(TextAssembler.assemble(fragments), "a1 a2\nb1 b2\nc1 c2")
  }

  func testEmptyInputReturnsEmptyString() {
    XCTAssertEqual(TextAssembler.assemble([]), "")
  }
}

import CoreGraphics
import Foundation

/// A single recognized text fragment, carrying the text and its bounding box
/// in Vision's normalized coordinate space (origin at the bottom-left).
struct RecognizedTextFragment {
  let text: String
  let boundingBox: CGRect
}

/// Reassembles the unordered set of fragments returned by Vision into
/// human-ordered multi-line text.
///
/// Vision returns observations in no guaranteed order, so we sort them
/// top-to-bottom, left-to-right, and group observations whose vertical centers
/// are close into the same line.
enum TextAssembler {
  /// Joins `fragments` into multi-line text.
  ///
  /// `lineTolerance` scales the height of the taller of two fragments to
  /// decide whether they belong to the same visual line. Values near 1 are
  /// more permissive; values near 0 require nearly identical baselines.
  static func assemble(
    _ fragments: [RecognizedTextFragment],
    lineTolerance: CGFloat = 0.7
  ) -> String {
    guard !fragments.isEmpty else { return "" }

    let sorted = fragments.sorted { lhs, rhs in
      let lhsMidY = lhs.boundingBox.midY
      let rhsMidY = rhs.boundingBox.midY
      let height = max(lhs.boundingBox.height, rhs.boundingBox.height)
      if abs(lhsMidY - rhsMidY) > lineTolerance * height {
        return lhsMidY > rhsMidY
      }
      return lhs.boundingBox.minX < rhs.boundingBox.minX
    }

    var lines: [[RecognizedTextFragment]] = []
    for fragment in sorted {
      if let anchor = lines.last?.first {
        let height = max(anchor.boundingBox.height, fragment.boundingBox.height)
        if abs(anchor.boundingBox.midY - fragment.boundingBox.midY) <= lineTolerance * height {
          lines[lines.count - 1].append(fragment)
          continue
        }
      }
      lines.append([fragment])
    }

    return lines.map { line in
      line.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
        .map(\.text)
        .joined(separator: " ")
    }.joined(separator: "\n")
  }
}

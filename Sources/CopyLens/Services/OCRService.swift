import CoreGraphics
import Foundation
import Vision

/// Runs on-device OCR via Apple Vision and returns assembled multi-line text.
final class OCRService {
  var recognitionLanguages: [String]

  init(recognitionLanguages: [String] = ["en-US", "ja-JP"]) {
    self.recognitionLanguages = recognitionLanguages
  }

  /// Recognizes text in `image` and returns it in reading order
  /// (top-to-bottom, left-to-right), preserving line breaks.
  func recognize(_ image: CGImage) throws -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = recognitionLanguages
    request.automaticallyDetectsLanguage = true

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try handler.perform([request])

    let fragments = (request.results ?? []).compactMap { observation -> RecognizedTextFragment? in
      guard let candidate = observation.topCandidates(1).first else { return nil }
      return RecognizedTextFragment(
        text: candidate.string,
        boundingBox: observation.boundingBox
      )
    }

    return TextAssembler.assemble(fragments)
  }
}

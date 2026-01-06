//
//  BestFramePickerTest.swift
//  StripeIdentityTests
//
//  Created by Kenneth Ackerson on 1/6/26.
//

import CoreGraphics
import XCTest

// swift-format-ignore
@testable @_spi(STP) import StripeCameraCore

@testable import StripeIdentity

final class BestFramePickerTest: XCTestCase {

    func testBestFramePickerTracksBestScoreAcrossFiveFrames() {
        let picker = BestFramePicker(window: 10_000)

        let cgImage = CapturedImageMock.frontDriversLicense.image.cgImage!
        let output = makeDocumentScannerOutputLegacy(with: .idCardFront)

        let scores: [Float] = [0.2, 0.4, 0.35, 0.9, 0.7]
        var expectedBest: Float = 0

        for score in scores {
            expectedBest = max(expectedBest, score)

            let state = picker.consider(
                cgImage: cgImage,
                output: output,
                exif: nil,
                score: score
            )

            guard case .holding(_, let bestScore) = state else {
                XCTFail("Expected holding state for score \(score), got \(state)")
                return
            }

            XCTAssertEqual(bestScore, expectedBest, accuracy: 0.0001)
        }
    }
}

extension BestFramePickerTest {
    fileprivate func makeDocumentScannerOutputLegacy(
        with classification: IDDetectorOutput.Classification
    ) -> DocumentScannerOutput {
        return .legacy(
            .init(
                classification: classification,
                documentBounds: CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
                allClassificationScores: [
                    classification: 0.9
                ]
            ),
            nil,
            .init(
                hasMotionBlur: false,
                iou: nil,
                frameCount: 0,
                duration: 0
            ),
            nil,
            .init(isBlurry: false, variance: 0.1)
        )
    }
}

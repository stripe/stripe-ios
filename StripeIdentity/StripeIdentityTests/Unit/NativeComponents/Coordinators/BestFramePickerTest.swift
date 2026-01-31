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

    func testBestFramePickerDoesNotDecreaseBestScoreAndUpdatesOnNewHigh() {
        let picker = BestFramePicker(window: 10_000)

        let cgImage = CapturedImageMock.frontDriversLicense.image.cgImage!
        let output = makeDocumentScannerOutputLegacy(with: .idCardFront)

        // Starts high, drops, then exceeds the previous high again.
        let inputsAndExpectedBest: [(score: Float, expectedBest: Float)] = [
            (score: 0.9, expectedBest: 0.9),
            (score: 0.6, expectedBest: 0.9),
            (score: 0.4, expectedBest: 0.9),
            (score: 0.95, expectedBest: 0.95),
            (score: 0.5, expectedBest: 0.95),
        ]

        for (score, expectedBest) in inputsAndExpectedBest {
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

    func testResetClearsBestScore() {
        let picker = BestFramePicker(window: 10_000)

        let cgImage = CapturedImageMock.frontDriversLicense.image.cgImage!
        let output = makeDocumentScannerOutputLegacy(with: .idCardFront)

        let state1 = picker.consider(
            cgImage: cgImage,
            output: output,
            exif: nil,
            score: 0.9
        )
        guard case .holding(_, let bestScore1) = state1 else {
            XCTFail("Expected holding state, got \(state1)")
            return
        }
        XCTAssertEqual(bestScore1, 0.9, accuracy: 0.0001)

        picker.reset()

        let state2 = picker.consider(
            cgImage: cgImage,
            output: output,
            exif: nil,
            score: 0.2
        )
        guard case .holding(_, let bestScore2) = state2 else {
            XCTFail("Expected holding state, got \(state2)")
            return
        }
        XCTAssertEqual(bestScore2, 0.2, accuracy: 0.0001)
    }

    func testZeroWindowPicksImmediatelyAndResets() {
        let picker = BestFramePicker(window: 0)

        let cgImage = CapturedImageMock.frontDriversLicense.image.cgImage!
        let output = makeDocumentScannerOutputLegacy(with: .idCardFront)

        let state1 = picker.consider(
            cgImage: cgImage,
            output: output,
            exif: nil,
            score: 0.2
        )
        guard case .picked(let candidate1) = state1 else {
            XCTFail("Expected picked state, got \(state1)")
            return
        }
        XCTAssertEqual(candidate1.score, 0.2, accuracy: 0.0001)
        XCTAssertTrue(candidate1.cgImage === cgImage)
        XCTAssertEqual(candidate1.output, output)

        // Picker auto-resets after returning .picked, so the next frame should be considered fresh.
        let state2 = picker.consider(
            cgImage: cgImage,
            output: output,
            exif: nil,
            score: 0.9
        )
        guard case .picked(let candidate2) = state2 else {
            XCTFail("Expected picked state, got \(state2)")
            return
        }
        XCTAssertEqual(candidate2.score, 0.9, accuracy: 0.0001)
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

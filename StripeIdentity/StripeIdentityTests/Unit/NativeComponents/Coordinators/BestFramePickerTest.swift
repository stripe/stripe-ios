//
//  BestFramePickerTest.swift
//  StripeIdentityTests
//
//  Created by Kenneth Ackerson on 1/6/26.
//

import CoreGraphics
import ImageIO
import XCTest

// swift-format-ignore
@testable @_spi(InternalOnlyAPI) import StripeCameraCore

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

    func testTimeoutCacheRetainsBestBlurryFrameAndItsMetadata() throws {
        // Given a matching frame that is rejected for blur
        let cache = DocumentFrameCache()
        let image = CapturedImageMock.frontDriversLicense.image.cgImage!
        let output = makeDocumentScannerOutputLegacy(with: .idCardFront, variance: 64, isBlurry: true)
        let exif = CameraExifMetadata(exifDictionary: [kCGImagePropertyExifLensModel: "cached_lens"])
        XCTAssertFalse(output.isHighQuality(side: .front))
        cache.consider(cgImage: image, output: output, exif: exif, side: .front)

        // When a later frame has lower sharpness and ID confidence
        cache.consider(
            cgImage: CapturedImageMock.backDriversLicense.image.cgImage!,
            output: makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.6, variance: 16, isBlurry: true),
            exif: nil,
            side: .front
        )

        // Then the original frame and its metadata remain the fallback
        let candidate = try XCTUnwrap(cache.bestCandidate(for: .front))
        XCTAssertTrue(candidate.cgImage === image)
        XCTAssertEqual(candidate.output, output)
        XCTAssertEqual(candidate.exif, exif)
    }

    func testTimeoutCacheRequiresTwoHundredthsImprovementOverCachedScore() {
        // Given a cached frame with a score of 0.25
        let cache = DocumentFrameCache()
        let image = CapturedImageMock.frontDriversLicense.image.cgImage!
        let bounds = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let initialOutput = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.5, bounds: bounds, variance: 0)
        cache.consider(cgImage: image, output: initialOutput, exif: nil, side: .front)

        // When small improvements remain below 0.02 relative to the cached frame
        for confidence: Float in [0.5, 0.53, 0.559_997] {
            let output = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: confidence, bounds: bounds, variance: 0)
            cache.consider(cgImage: image, output: output, exif: nil, side: .front)
            XCTAssertEqual(cache.bestCandidate(for: .front)?.output, initialOutput)
        }

        // Then an improvement of exactly 0.02 replaces it
        let boundaryOutput = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.56, bounds: bounds, variance: 0)
        cache.consider(cgImage: image, output: boundaryOutput, exif: nil, side: .front)
        XCTAssertEqual(cache.bestCandidate(for: .front)?.output, boundaryOutput)

        // ...and subsequent improvements are compared with the new cached frame
        let smallImprovement = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.59, bounds: bounds, variance: 0)
        cache.consider(cgImage: image, output: smallImprovement, exif: nil, side: .front)
        XCTAssertEqual(cache.bestCandidate(for: .front)?.output, boundaryOutput)
        let largerImprovement = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.65, bounds: bounds, variance: 0)
        cache.consider(cgImage: image, output: largerImprovement, exif: nil, side: .front)
        XCTAssertEqual(cache.bestCandidate(for: .front)?.output, largerImprovement)
    }

    func testTimeoutCacheKeepsDocumentSidesSeparateAndAcceptsPassports() {
        let cache = DocumentFrameCache()
        let image = CapturedImageMock.frontDriversLicense.image.cgImage!
        let front = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.6)
        let passport = makeDocumentScannerOutputLegacy(with: .passport)
        let back = makeDocumentScannerOutputLegacy(with: .idCardBack)

        // Given candidates for the front and back of the document
        cache.consider(cgImage: image, output: front, exif: nil, side: .front)
        XCTAssertNil(cache.bestCandidate(for: .back))
        cache.consider(cgImage: image, output: back, exif: nil, side: .back)

        // When a better passport frame is found while scanning the front
        cache.consider(cgImage: image, output: passport, exif: nil, side: .front)

        // Then only the front candidate changes
        XCTAssertEqual(cache.bestCandidate(for: .front)?.output, passport)
        XCTAssertEqual(cache.bestCandidate(for: .back)?.output, back)
    }

    func testTimeoutCacheRejectsWrongSideAndInvalidDocuments() {
        let cache = DocumentFrameCache()
        let image = CapturedImageMock.frontDriversLicense.image.cgImage!

        for classification: IDDetectorOutput.Classification in [.idCardBack, .invalid] {
            cache.consider(
                cgImage: image,
                output: makeDocumentScannerOutputLegacy(with: classification),
                exif: nil,
                side: .front
            )
        }
        for classification: IDDetectorOutput.Classification in [.idCardFront, .passport, .invalid] {
            cache.consider(
                cgImage: image,
                output: makeDocumentScannerOutputLegacy(with: classification),
                exif: nil,
                side: .back
            )
        }

        XCTAssertNil(cache.bestCandidate(for: .front))
        XCTAssertNil(cache.bestCandidate(for: .back))
    }

    func testTimeoutCacheRejectsInvalidBoundsAndNonfiniteScores() {
        let cache = DocumentFrameCache()
        let image = CapturedImageMock.frontDriversLicense.image.cgImage!
        let invalidBounds: [CGRect] = [
            .zero,
            CGRect(x: 0.1, y: 0.1, width: -0.1, height: 0.2),
            CGRect(x: -0.1, y: 0.1, width: 0.8, height: 0.3),
            CGRect(x: 0.5, y: 0.1, width: 0.8, height: 0.3),
            CGRect(x: CGFloat.nan, y: 0.1, width: 0.8, height: 0.3),
            .infinite,
        ]
        for bounds in invalidBounds {
            cache.consider(
                cgImage: image,
                output: makeDocumentScannerOutputLegacy(with: .idCardFront, bounds: bounds),
                exif: nil,
                side: .front
            )
        }
        for output in [
            makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: .nan),
            makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: .infinity),
            makeDocumentScannerOutputLegacy(with: .idCardFront, variance: .nan),
            makeDocumentScannerOutputLegacy(with: .idCardFront, variance: .infinity),
        ] {
            cache.consider(cgImage: image, output: output, exif: nil, side: .front)
        }

        XCTAssertNil(cache.bestCandidate(for: .front))
    }

    func testTimeoutCacheResetClearsBothSides() {
        // Given cached candidates for both sides
        let cache = DocumentFrameCache()
        let image = CapturedImageMock.frontDriversLicense.image.cgImage!
        cache.consider(cgImage: image, output: makeDocumentScannerOutputLegacy(with: .idCardFront), exif: nil, side: .front)
        cache.consider(cgImage: image, output: makeDocumentScannerOutputLegacy(with: .idCardBack), exif: nil, side: .back)

        // When the capture session resets
        cache.reset()

        // Then neither side can reuse an earlier candidate
        XCTAssertNil(cache.bestCandidate(for: .front))
        XCTAssertNil(cache.bestCandidate(for: .back))
    }

    func testTimeoutQualityScoreUsesSharpnessCoverageAndIDConfidence() {
        let bounds = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let baseline = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.6, bounds: bounds, variance: 51)
        let sharper = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.6, bounds: bounds, variance: 127.5)
        let larger = makeDocumentScannerOutputLegacy(
            with: .idCardFront,
            confidence: 0.6,
            bounds: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.6875),
            variance: 51
        )
        let moreConfident = makeDocumentScannerOutputLegacy(with: .idCardFront, confidence: 0.9, bounds: bounds, variance: 51)

        XCTAssertEqual(baseline.timeoutQualityScore(side: .front), 0.35, accuracy: 0.0001)
        for output in [sharper, larger, moreConfident] {
            XCTAssertEqual(output.timeoutQualityScore(side: .front), 0.45, accuracy: 0.0001)
        }
    }
}

extension BestFramePickerTest {
    fileprivate func makeDocumentScannerOutputLegacy(
        with classification: IDDetectorOutput.Classification,
        confidence: Float = 0.9,
        bounds: CGRect = CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
        variance: Float = 0.1,
        isBlurry: Bool = false
    ) -> DocumentScannerOutput {
        return .legacy(
            .init(
                classification: classification,
                documentBounds: bounds,
                allClassificationScores: [
                    classification: confidence
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
            .init(isBlurry: isBlurry, variance: variance)
        )
    }
}

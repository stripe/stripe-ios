//
//  FaceScannerOutputTest.swift
//  StripeIdentityTests
//
//  Created by Stripe on 8/4/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreGraphics
import CoreMedia
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCore
import XCTest

@testable import StripeIdentity

final class FaceScannerOutputTest: XCTestCase {
    private static let scannerConfiguration = FaceScanner.Configuration(
        faceDetectorMinScore: 0.5,
        faceDetectorMinIOU: 0.5,
        maxCenteredThreshold: CGPoint(x: 0.1, y: 0.1),
        minEdgeThreshold: 0.05,
        minCoverageThreshold: 0.1,
        maxCoverageThreshold: 0.3
    )

    func testMultipleFacesReportsFaceCount() {
        // Given
        let prediction = FaceDetectorPrediction(
            rect: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            score: 0.9
        )

        // When
        let output = FaceScannerOutput(
            faceDetectorOutput: .init(predictions: [prediction, prediction]),
            cameraProperties: nil,
            configuration: Self.scannerConfiguration
        )

        // Then
        XCTAssertEqual(output.validationIssue, .faceCount)
        XCTAssertFalse(output.isValid)
    }

    func testSmallCenteredFaceReportsTooFar() {
        // Given
        let prediction = FaceDetectorPrediction(
            rect: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
            score: 0.9
        )

        // When
        let output = FaceScannerOutput(
            faceDetectorOutput: .init(predictions: [prediction]),
            cameraProperties: nil,
            configuration: Self.scannerConfiguration
        )

        // Then
        XCTAssertEqual(output.validationIssue, .tooFar)
        XCTAssertFalse(output.isValid)
    }

    func testProperlySizedCenteredFaceIsValid() {
        // Given
        let prediction = FaceDetectorPrediction(
            rect: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
            score: 0.9
        )

        // When
        let output = FaceScannerOutput(
            faceDetectorOutput: .init(predictions: [prediction]),
            cameraProperties: nil,
            configuration: Self.scannerConfiguration
        )

        // Then
        XCTAssertNil(output.validationIssue)
        XCTAssertTrue(output.isValid)
        XCTAssertFalse(output.isFromMediaPipe)
    }

    func testMediaPipeSourceIsPreservedWithoutPose() throws {
        // Given a MediaPipe detector result without pose data
        let faceRect = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
        let scanner = FaceScanner(
            faceGeometryDetector: FaceGeometryDetectorMock(
                geometry: .init(
                    faceDetectorOutput: .init(predictions: [.init(rect: faceRect, score: 0.9)]),
                    facePose: nil
                )
            ),
            configuration: Self.scannerConfiguration
        )
        let sampleBuffer = try XCTUnwrap(CapturedImageMock.frontDriversLicense.image.convertToSampleBuffer())
        let pixelBuffer = try XCTUnwrap(CMSampleBufferGetImageBuffer(sampleBuffer))
        let completion = expectation(description: "Face scan completed")
        var scanResult: Result<FaceScannerOutput, Error>?

        // When the scanner processes the frame
        scanner.scanImage(
            pixelBuffer: pixelBuffer,
            sampleBuffer: sampleBuffer,
            cameraProperties: nil
        ).observe { result in
            scanResult = result
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)

        // Then the output preserves its source, original bounds, and first-frame motion blur gate
        let output = try XCTUnwrap(scanResult).get()
        XCTAssertTrue(output.isFromMediaPipe)
        XCTAssertNil(output.facePose)
        XCTAssertEqual(output.faceRect, faceRect)
        XCTAssertEqual(output.validationIssue, .motionBlur)
        XCTAssertFalse(output.isValid)
    }
}

private struct FaceGeometryDetectorMock: FaceGeometryDetector {
    let geometry: FaceGeometry

    func detectFace(pixelBuffer: CVPixelBuffer) throws -> FaceGeometry? {
        return geometry
    }
}

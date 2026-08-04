//
//  MediaPipeFacePoseDetectorTest.swift
//  StripeIdentityTests
//
//  Created by Stripe on 7/6/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreGraphics
import XCTest

@_spi(STP) @testable import StripeIdentity

final class MediaPipeFacePoseDetectorTest: XCTestCase {
    func testDefaultDetectorInitializes() throws {
        XCTAssertNoThrow(try FaceGeometryDetectorFactory.makeDefaultDetector())
    }

    func testFacePoseDirectionUsesYawThresholds() {
        XCTAssertEqual(FacePose(yaw: 0, pitch: 20, roll: 20).direction, .front)
        XCTAssertEqual(FacePose(yaw: 15, pitch: 0, roll: 0).direction, .front)
        XCTAssertEqual(FacePose(yaw: -15, pitch: 0, roll: 0).direction, .front)
        XCTAssertEqual(FacePose(yaw: 15.01, pitch: 0, roll: 0).direction, .right)
        XCTAssertEqual(FacePose(yaw: -15.01, pitch: 0, roll: 0).direction, .left)
    }

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
    }

    private static let scannerConfiguration = FaceScanner.Configuration(
        faceDetectorMinScore: 0.5,
        faceDetectorMinIOU: 0.5,
        maxCenteredThreshold: CGPoint(x: 0.1, y: 0.1),
        minEdgeThreshold: 0.05,
        minCoverageThreshold: 0.1,
        maxCoverageThreshold: 0.3
    )
}

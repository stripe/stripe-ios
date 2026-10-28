//
//  FaceScannerOutputTest.swift
//  StripeIdentityTests
//
//  Created by Stripe on 8/4/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreGraphics
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
    }
}

//
//  IDDetectorOutputTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreGraphics
import XCTest

@testable import StripeIdentity

final class IDDetectorOutputTest: XCTestCase {
    func testZoomLevelIsMeasuredAgainstDetectorSquareInLandscapeFrames() throws {
        // Given a document spanning 70% of the square the model scans
        let prediction = IDDetectorPrediction(
            classification: .idCardFront,
            score: 0.9,
            rect: CGRect(x: 0.15, y: 0.3, width: 0.7, height: 0.4)
        )

        // When it is detected in a landscape frame, as on an unfolded iPhone Duo
        let output = try XCTUnwrap(
            IDDetectorOutput(
                sortedPredictions: [prediction],
                originalImageSize: CGSize(width: 3840, height: 2160)
            )
        )

        // Then its zoom level is acceptable, like the same document in a portrait frame
        XCTAssertEqual(output.computeZoomLevel(), .ok)
    }
}

//
//  MediaPipeFacePoseDetectorTest.swift
//  StripeIdentityTests
//
//  Created by Stripe on 7/6/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@_spi(STP) @testable import StripeIdentity

final class MediaPipeFacePoseDetectorTest: XCTestCase {
    func testDefaultDetectorInitializes() throws {
        XCTAssertNoThrow(try FaceGeometryDetectorFactory.makeDefaultDetector())
    }
}

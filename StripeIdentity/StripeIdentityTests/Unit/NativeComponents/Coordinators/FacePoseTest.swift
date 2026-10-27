//
//  FacePoseTest.swift
//  StripeIdentityTests
//
//  Created by Stripe on 8/4/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import StripeIdentity

final class FacePoseTest: XCTestCase {
    func testDirectionUsesYawThresholds() {
        XCTAssertEqual(FacePose(yaw: 0, pitch: 20, roll: 20).direction, .front)
        XCTAssertEqual(FacePose(yaw: 15, pitch: 0, roll: 0).direction, .front)
        XCTAssertEqual(FacePose(yaw: -15, pitch: 0, roll: 0).direction, .front)
        XCTAssertEqual(FacePose(yaw: 15.01, pitch: 0, roll: 0).direction, .right)
        XCTAssertEqual(FacePose(yaw: -15.01, pitch: 0, roll: 0).direction, .left)
    }
}

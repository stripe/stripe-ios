//
//  SelfieCaptureFeedbackGeneratorTest.swift
//  StripeIdentityTests
//
//  Created by Stripe on 11/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import StripeIdentity

final class SelfieCaptureFeedbackGeneratorTest: XCTestCase {
    func testLoadsConfirmationSoundAsSystemSound() {
        XCTAssertNotNil(SelfieCaptureFeedbackGenerator().confirmationSoundID)
    }
}

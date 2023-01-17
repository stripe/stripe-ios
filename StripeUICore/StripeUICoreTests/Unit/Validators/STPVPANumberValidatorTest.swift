//
//  STPVPANumberValidatorTest.swift
//  StripeUICoreTests
//
//  Created by Nick Porter on 9/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore
import XCTest

class STPVPANumberValidatorTest: XCTestCase {
    func testValidVPAs() {
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("stripe@icici"))
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("stripe@okaxis"))
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("stripe.9897605011@paytm"))
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("payment.pending@stripeupi"))
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("test30c_123@numberofcharacters"))
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("test29c_12@numberofcharacters"))
    }

    func testInvalidVPAs() {
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber(""))
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber("test@stripe.com"))
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber("stripe"))
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber("stripe@gmail.com"))
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber("this-vpa-id-is-too-long-30-chars"))
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber("test31c_1234@numberofcharacters"))
    }
}

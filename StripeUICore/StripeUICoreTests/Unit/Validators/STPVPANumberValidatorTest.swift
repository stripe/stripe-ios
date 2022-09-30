//
//  STPVPANumberValidatorTest.swift
//  StripeUICoreTests
//
//  Created by Nick Porter on 9/15/22.
//

import Foundation
import XCTest
@_spi(STP) import StripeUICore

class STPVPANumberValidatorTest: XCTestCase {
    func testValidVPAs() {
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("stripe@icici"))
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("stripe@okaxis"))
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("stripe.9897605011@paytm"))
        XCTAssert(STPVPANumberValidator.stringIsValidVPANumber("payment.pending@stripeupi"))
    }

    func testInvalidVPAs() {
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber(""))
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber("test@stripe.com"))
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber("stripe"))
        XCTAssertFalse(STPVPANumberValidator.stringIsValidVPANumber("stripe@gmail.com"))
    }
}

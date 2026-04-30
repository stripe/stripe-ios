//
//  IntegrationTesterUICardTests.swift
//  IntegrationTester
//
//  Created by David Estes on 2/11/26.
//

import IntegrationTesterCommon
import Stripe
import XCTest

class IntegrationTesterUICardTests: IntegrationTesterUITests {

    func testStandardCustomCard3DS2() throws {
        testOOBAuthentication(cardNumber: "4000000000003220")
    }

    let alwaysOobCard = "4000582600000094"
    func testOOB3DS2() throws {
        testOOBAuthentication(cardNumber: alwaysOobCard)
    }

    func testDeclinedCard() throws {
        testAuthentication(cardNumber: "4000000000000002", expectedResult: "declined")
    }

    let alwaysOtpCard = "4000582600000045"
    func testOtp3DS2() throws {
        testOtpAuthentication(cardNumber: alwaysOtpCard)
    }

    let alwaysSingleSelectCard = "4000582600000102"
    func testSingleSelect3DS2() throws {
        testSingleSelectAuthentication(cardNumber: alwaysSingleSelectCard)
    }

    let alwaysMultiSelectCard = "4000582600000110"
    func testMultiSelect3DS2() throws {
        testMultiSelectAuthentication(cardNumber: alwaysMultiSelectCard)
    }

    let hsbcCard = "4000582600000292"
    func testHSBCHTMLIssue() throws {
        testHSBCWebViewLinksTrigger(cardNumber: hsbcCard)
    }

    let browserFallbackCard = "4000582600000060"
    func testBrowserFallback() throws {
        testBrowserFallbackAuthentication(cardNumber: browserFallbackCard)
    }
}

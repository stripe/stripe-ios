//
//  ImageCompressionTests.swift
//  StripeCardScanTests
//
//  Created by Sam King on 11/29/21.
//

@testable @_spi(STP) import StripeCore

import CoreServices
import UniformTypeIdentifiers.UTType
import XCTest
import UniformTypeIdentifiers

class StringResourceTests: XCTestCase {

    func testPrivacyLinkText() throws {
        let privacyLinkString = String.Localized.scan_card_privacy_link_text
        let expected = "We use Stripe to verify your card details. Stripe may use and store your" +
        " data according its privacy policy. " +
        "<a href='https://support.stripe.com/questions/stripes-card-image-verification'>" +
        "<u>Learn more</u></a>"

        XCTAssertEqual(expected, privacyLinkString)
    }
}

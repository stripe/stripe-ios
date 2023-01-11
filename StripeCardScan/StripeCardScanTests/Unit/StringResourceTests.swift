//
//  ImageCompressionTests.swift
//  StripeCardScanTests
//
//  Created by Scott Grant on 05/18/22.
//

import CoreServices
import UniformTypeIdentifiers
import XCTest

@testable@_spi(STP) import StripeCore

class StringResourceTests: XCTestCase {
    let privacyLinkExpectedSha = "lv51crZ0rBIUPUOnQm9zFlMPCrUEI+GVsa4QyHifTw0="

    func testPrivacyLinkText() throws {
        STPLocalizationUtils.overrideLanguage(to: "en")

        // This string is expected to go unaltered in the UI for CardScan. Changing it is against
        // the terms of service for Stripe Card Scan.
        let privacyLinkString = String.Localized.scan_card_privacy_link_text
        XCTAssertEqual(privacyLinkString.sha256, privacyLinkExpectedSha)

        STPLocalizationUtils.overrideLanguage(to: nil)
    }
}

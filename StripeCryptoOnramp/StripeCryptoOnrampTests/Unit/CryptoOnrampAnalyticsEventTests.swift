//
//  CryptoOnrampAnalyticsEventTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 8/5/26.
//

@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
import XCTest

final class CryptoOnrampAnalyticsEventTests: XCTestCase {
    func testErrorOccurredIncludesRequestIDWhenAvailable() {
        let parameters = CryptoOnrampAnalyticsEvent.errorOccurred(
            during: .hasLinkAccount,
            errorMessage: "Test error",
            requestID: "req_123"
        ).parameters

        XCTAssertEqual(parameters["operation_name"] as? String, "has_link_account")
        XCTAssertEqual(parameters["error_message"] as? String, "Test error")
        XCTAssertEqual(parameters["request_id"] as? String, "req_123")
    }

    func testErrorOccurredOmitsRequestIDWhenUnavailable() {
        let parameters = CryptoOnrampAnalyticsEvent.errorOccurred(
            during: .hasLinkAccount,
            errorMessage: "Test error"
        ).parameters

        XCTAssertNil(parameters["request_id"])
    }
}

//
//  ConsumerSessionLookupResponseTests.swift
//  StripePaymentSheetTests
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class ConsumerSessionLookupResponseTests: XCTestCase {
    func testDecoding_notFoundResponse_readsLinkBrand() throws {
        let json = """
        {
          "exists": false,
          "error_message": "No consumer found",
          "suggested_email": "user@example.com",
          "link_brand": "notlink"
        }
        """

        let response = try StripeJSONDecoder().decode(
            ConsumerSession.LookupResponse.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(response.linkBrand, .onelink)
        switch response.responseType {
        case .notFound(let errorMessage, let suggestedEmail):
            XCTAssertEqual(errorMessage, "No consumer found")
            XCTAssertEqual(suggestedEmail, "user@example.com")
        case .found, .noAvailableLookupParams:
            XCTFail("Expected notFound response type")
        }
    }
}

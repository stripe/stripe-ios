//
//  ConsumerSessionLookupResponseTests.swift
//  StripePaymentSheetTests
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class ConsumerSessionLookupResponseTests: XCTestCase {
    func testDecoding_displayableLPM_readsDisplayMetadata() throws {
        let json = """
        {
          "default_payment_type": "PIX",
          "display": {
            "label": "Pix",
            "sublabel": "000••••••••",
            "icon": {
              "default": "https://cdn.stripe.com/pix.png"
            }
          }
        }
        """

        let paymentDetails = try StripeJSONDecoder().decode(
            ConsumerSession.DisplayablePaymentDetails.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(paymentDetails.defaultPaymentType, .unparsable)
        XCTAssertEqual(paymentDetails.display?.label, "Pix")
        XCTAssertEqual(paymentDetails.display?.sublabel, "000••••••••")
        XCTAssertEqual(paymentDetails.display?.formattedDisplayText, "Pix 000••••••••")
        XCTAssertEqual(paymentDetails.display?.icon?.main, URL(string: "https://cdn.stripe.com/pix.png"))
    }

    func testDecoding_notFoundResponse_readsLinkBrand() throws {
        let json = """
        {
          "exists": false,
          "error_message": "No consumer found",
          "suggested_email": "user@example.com",
          "link_brand": "onelink"
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

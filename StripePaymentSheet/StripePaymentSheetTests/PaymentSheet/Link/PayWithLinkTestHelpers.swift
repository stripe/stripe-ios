//
//  PayWithLinkTestHelpers.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 5/6/25.
//

import Foundation
@testable import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsTestUtils

enum PayWithLinkTestHelpers {
    static func makeMockElementSession() throws -> STPElementsSession {
        // Link settings don't live in the PaymentIntent object itself, but in the /elements/sessions API response
        // So we construct a minimal response (see STPPaymentIntentTest.testDecodedObjectFromAPIResponseMapping) to parse them
        let paymentIntentJson = try XCTUnwrap(STPTestUtils.jsonNamed(STPTestJSONPaymentIntent))
        let orderedPaymentJson = ["card", "link"]
        let paymentIntentResponse = [
            "payment_intent": paymentIntentJson,
            "ordered_payment_method_types": orderedPaymentJson,
        ] as [String: Any]
        let linkSettingsJson = ["link_funding_sources": ["CARD"]]
        let response = [
            "payment_method_preference": paymentIntentResponse,
            "link_settings": linkSettingsJson,
            "session_id": "abc123",
        ] as [String: Any]
        return try XCTUnwrap(
            STPElementsSession.decodedObject(fromAPIResponse: response)
        )
    }

    static func makeMockPaymentIntent(
        elementsSession: STPElementsSession
    ) throws -> STPPaymentIntent {
        let paymentIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "payment_intent"]
        return STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJSON)!
    }
}

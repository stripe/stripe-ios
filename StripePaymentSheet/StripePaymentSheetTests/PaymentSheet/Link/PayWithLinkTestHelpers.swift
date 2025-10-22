//
//  PayWithLinkTestHelpers.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 5/6/25.
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsTestUtils

enum PayWithLinkTestHelpers {
    static func makePaymentIntentAndElementsSession(
        linkFundingSources: [String] = ["CARD"],
        linkPassthroughModeEnabled: Bool? = nil,
        linkPMOSFU: Bool? = nil
    ) throws -> (Intent, STPElementsSession) {
        // Link settings don't live in the PaymentIntent object itself, but in the /elements/sessions API response
        // So we construct a minimal response (see STPPaymentIntentTest.testDecodedObjectFromAPIResponseMapping) to parse them
        var paymentIntentJson = try XCTUnwrap(STPTestUtils.jsonNamed(STPTestJSONPaymentIntent))
        if linkPMOSFU != nil {
            paymentIntentJson["payment_method_options"] = [(linkPassthroughModeEnabled ?? false ? "card" : "link"): ["setup_future_usage": "off_session"]]
        }
        let orderedPaymentJson = ["card", "link"]
        let paymentIntentResponse = [
            "payment_intent": paymentIntentJson,
            "ordered_payment_method_types": orderedPaymentJson,
        ] as [String: Any]

        var linkSettingsJson: [String: Any] = ["link_funding_sources": linkFundingSources]

        if let linkPassthroughModeEnabled {
            linkSettingsJson["link_passthrough_mode_enabled"] = linkPassthroughModeEnabled
        }

        let response = [
            "payment_method_preference": paymentIntentResponse,
            "link_settings": linkSettingsJson,
            "session_id": "abc123",
            "config_id": "abc123",
        ] as [String: Any]
        let elementsSession = try XCTUnwrap(
            STPElementsSession.decodedObject(fromAPIResponse: response)
        )
        let paymentIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "payment_intent"]
        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJSON)!

        return (Intent.paymentIntent(paymentIntent), elementsSession)
    }

    static func makeSetupIntentAndElementsSession(
        linkFundingSources: [String] = ["CARD"],
        linkPassthroughModeEnabled: Bool? = nil
    ) throws -> (Intent, STPElementsSession) {
        // Link settings don't live in the PaymentIntent object itself, but in the /elements/sessions API response
        // So we construct a minimal response (see STPPaymentIntentTest.testDecodedObjectFromAPIResponseMapping) to parse them
        let setupIntentJson = try XCTUnwrap(STPTestUtils.jsonNamed(STPTestJSONSetupIntent))
        let orderedSetupJson = ["card", "link"]
        let setupIntentResponse = [
            "setup_intent": setupIntentJson,
            "ordered_payment_method_types": orderedSetupJson,
        ] as [String: Any]

        var linkSettingsJson: [String: Any] = ["link_funding_sources": linkFundingSources]

        if let linkPassthroughModeEnabled {
            linkSettingsJson["link_passthrough_mode_enabled"] = linkPassthroughModeEnabled
        }

        let response = [
            "payment_method_preference": setupIntentResponse,
            "link_settings": linkSettingsJson,
            "session_id": "abc123",
            "config_id": "abc123",
        ] as [String: Any]
        let elementsSession = try XCTUnwrap(
            STPElementsSession.decodedObject(fromAPIResponse: response)
        )
        let setupIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "setup_intent"]
        let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: setupIntentJSON)!

        return (Intent.setupIntent(setupIntent), elementsSession)
    }
}

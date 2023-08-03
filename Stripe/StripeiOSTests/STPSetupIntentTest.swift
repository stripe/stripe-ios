//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSetupIntentTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPSetupIntentTest: XCTestCase {
    // MARK: - Description Tests

    func testDescription() {
        let setupIntent = STPFixtures.setupIntent()

        XCTAssertNotNil(Int(setupIntent))
        let desc = setupIntent.description
        XCTAssertTrue(desc.contains(NSStringFromClass(type(of: setupIntent).self)))
        XCTAssertGreaterThan(desc.count, 500, "Custom description should be long")
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let fullJson = STPTestUtils.jsonNamed(STPTestJSONSetupIntent)

        XCTAssertNotNil(STPSetupIntent.decodedObject(fromAPIResponse: fullJson))

        let requiredFields = [
            "id",
            "client_secret",
            "livemode",
            "status",
        ]

        for field in requiredFields {
            var partialJson = fullJson

            XCTAssertNotNil(Int(partialJson?[field] ?? 0))
            partialJson?.removeValue(forKey: field)

            XCTAssertNil(STPSetupIntent.decodedObject(fromAPIResponse: partialJson))
        }
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let setupIntentJson = STPTestUtils.jsonNamed("SetupIntent")
        let orderedPaymentJson = ["card", "ideal", "sepa_debit"]
        var setupIntentResponse: [StringLiteralConvertible : [AnyHashable : Any]?]?
        if let setupIntentJson {
            setupIntentResponse = [
                "setup_intent": setupIntentJson,
                "ordered_payment_method_types": orderedPaymentJson
            ]
        }
        let unactivatedPaymentMethodTypes = ["sepa_debit"]
        var response: [StringLiteralConvertible : [StringLiteralConvertible : [AnyHashable : Any]?]?]?
        if let setupIntentResponse {
            response = [
                "payment_method_preference": setupIntentResponse,
                "unactivated_payment_method_types": unactivatedPaymentMethodTypes
            ]
        }

        let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(setupIntent?.stripeID, "seti_123456789")
        XCTAssertEqual(setupIntent?.clientSecret, "seti_123456789_secret_123456789")
        XCTAssertEqual(setupIntent?.created, Date(timeIntervalSince1970: 123456789))
        XCTAssertEqual(setupIntent?.customerID, "cus_123456")
        XCTAssertEqual(setupIntent?.paymentMethodID, "pm_123456")
        XCTAssertEqual(setupIntent?.stripeDescription, "My Sample SetupIntent")
        XCTAssertFalse(setupIntent?.livemode)
        // nextAction
        XCTAssertNotNil(setupIntent?.nextAction ?? 0)
        XCTAssertEqual(setupIntent?.nextAction.type ?? 0, Int(STPIntentActionTypeRedirectToURL))
        XCTAssertNotNil(setupIntent?.nextAction.redirectToURL ?? 0)
        XCTAssertNotNil(setupIntent?.nextAction.redirectToURL.url ?? 0)
        let returnURL = setupIntent?.nextAction.redirectToURL.returnURL
        XCTAssertNotNil(returnURL)
        XCTAssertEqual(returnURL, URL(string: "payments-example://stripe-redirect"))
        let url = setupIntent?.nextAction.redirectToURL.url
        XCTAssertNotNil(url)

        XCTAssertEqual(url, URL(string: "https://hooks.stripe.com/redirect/authenticate/src_1Cl1AeIl4IdHmuTb1L7x083A?client_secret=src_client_secret_DBNwUe9qHteqJ8qQBwNWiigk"))
        XCTAssertEqual(setupIntent?.paymentMethodID, "pm_123456")
        XCTAssertEqual(setupIntent?.status ?? 0, Int(STPSetupIntentStatusRequiresAction))
        XCTAssertEqual(setupIntent?.usage ?? 0, Int(STPSetupIntentUsageOffSession))

        XCTAssertEqual(setupIntent?.paymentMethodTypes, [NSNumber(value: STPPaymentMethodTypeCard)])

        // lastSetupError

        XCTAssertNotNil(setupIntent?.lastSetupError ?? 0)
        XCTAssertEqual(setupIntent?.lastSetupError.code, "setup_intent_authentication_failure")
        XCTAssertEqual(setupIntent?.lastSetupError.docURL, "https://stripe.com/docs/error-codes#setup-intent-authentication-failure")
        XCTAssertEqual(setupIntent?.lastSetupError.message, "The latest attempt to set up the payment method has failed because authentication failed.")
        XCTAssertNotNil(setupIntent?.lastSetupError.paymentMethod)
        XCTAssertEqual(setupIntent?.lastSetupError.type ?? 0, Int(STPSetupIntentLastSetupErrorTypeInvalidRequest))

        // Hack to test internal variable, should be re-written in Swift with @testable
        XCTAssertTrue(setupIntent?.description.contains("unactivatedPaymentMethodTypes = [sepa_debit]"))

        XCTAssertNotEqual(setupIntent?.allResponseFields, response, "should have own copy of fields")
    }
}
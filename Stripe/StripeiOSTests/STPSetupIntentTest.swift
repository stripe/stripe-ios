//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSetupIntentTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@_spi(STP) @testable import StripePayments

class STPSetupIntentTest: XCTestCase {
    // MARK: - Description Tests

    func testDescription() {
        let setupIntent = STPFixtures.setupIntent()

        XCTAssertNotNil(setupIntent)
        let desc = setupIntent.description
        XCTAssertTrue(desc.contains(NSStringFromClass(type(of: setupIntent).self)))
        XCTAssertGreaterThan(desc.count, 500, "Custom description should be long")
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let fullJson = STPTestUtils.jsonNamed(STPTestJSONSetupIntent)

        XCTAssertNotNil(STPSetupIntent.decodedObject(fromAPIResponse: fullJson), "can decode with full json")

        let requiredFields = [
            "id",
            "client_secret",
            "livemode",
            "status",
        ]

        for field in requiredFields {
            var partialJson = fullJson! as [AnyHashable: Any]

            XCTAssertNotNil(partialJson[field])
            partialJson.removeValue(forKey: field)

            XCTAssertNil(STPSetupIntent.decodedObject(fromAPIResponse: partialJson))
        }
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let setupIntentJson = STPTestUtils.jsonNamed("SetupIntent")!
        guard let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: setupIntentJson) else { XCTFail(); return }

        XCTAssertEqual(setupIntent.stripeID, "seti_123456789")
        XCTAssertEqual(setupIntent.clientSecret, "seti_123456789_secret_123456789")
        XCTAssertEqual(setupIntent.created, Date(timeIntervalSince1970: 123456789))
        XCTAssertEqual(setupIntent.customerID, "cus_123456")
        XCTAssertEqual(setupIntent.paymentMethodID, "pm_123456")
        XCTAssertEqual(setupIntent.stripeDescription, "My Sample SetupIntent")
        XCTAssertFalse(setupIntent.livemode)
        // nextAction
        XCTAssertNotNil(setupIntent.nextAction)
        XCTAssertEqual(setupIntent.nextAction?.type, STPIntentActionType.redirectToURL)
        XCTAssertNotNil(setupIntent.nextAction?.redirectToURL)
        XCTAssertNotNil(setupIntent.nextAction?.redirectToURL?.url)
        let returnURL = setupIntent.nextAction?.redirectToURL?.returnURL
        XCTAssertNotNil(returnURL)
        XCTAssertEqual(returnURL, URL(string: "payments-example://stripe-redirect"))
        let url = setupIntent.nextAction?.redirectToURL?.url
        XCTAssertNotNil(url)

        XCTAssertEqual(url, URL(string: "https://hooks.stripe.com/redirect/authenticate/src_1Cl1AeIl4IdHmuTb1L7x083A?client_secret=src_client_secret_DBNwUe9qHteqJ8qQBwNWiigk"))
        XCTAssertEqual(setupIntent.paymentMethodID, "pm_123456")
        XCTAssertEqual(setupIntent.status, STPSetupIntentStatus.requiresAction)
        XCTAssertEqual(setupIntent.usage, STPSetupIntentUsage.offSession)

        XCTAssertEqual(setupIntent.paymentMethodTypes, [NSNumber(value: STPPaymentMethodType.card.rawValue)])

        // lastSetupError

        XCTAssertNotNil(setupIntent.lastSetupError)
        XCTAssertEqual(setupIntent.lastSetupError?.code, "setup_intent_authentication_failure")
        XCTAssertEqual(setupIntent.lastSetupError?.docURL, "https://stripe.com/docs/error-codes#setup-intent-authentication-failure")
        XCTAssertEqual(setupIntent.lastSetupError?.message, "The latest attempt to set up the payment method has failed because authentication failed.")
        XCTAssertNotNil(setupIntent.lastSetupError?.paymentMethod)
        XCTAssertEqual(setupIntent.lastSetupError?.type, STPSetupIntentLastSetupErrorType.invalidRequest)
    }

    // MARK: STPSetupIntentStatus extension tests

    func testStringFromStatus() {
        let expected: [STPSetupIntentStatus: String] = [
            .requiresPaymentMethod: "requires_payment_method",
            .requiresConfirmation: "requires_confirmation",
            .requiresAction: "requires_action",
            .processing: "processing",
            .succeeded: "succeeded",
            .canceled: "canceled",
            .unknown: "unknown",
        ]

        for (status, expectedString) in expected {
            let resultString = STPSetupIntentStatus.string(from: status)
            XCTAssertEqual(resultString, expectedString, "Expected \(status) to map to string '\(expectedString)', but got '\(resultString)'")
        }
    }
}

//
//  STPIntentActionUseStripeSDKTest.swift
//  StripeiOS Tests
//

@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsUI

class STPIntentActionUseStripeSDKTest: XCTestCase {

    func testDecodedObjectIntentConfirmationChallengeWithStripeJs() {
        let response: [AnyHashable: Any] = [
            "type": "intent_confirmation_challenge",
            "stripe_js": [
                "captcha_vendor_name": "arkose",
            ] as [String: Any],
        ]
        let decoded = STPIntentActionUseStripeSDK.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.type, .intentConfirmationChallenge)
        XCTAssertNotNil(decoded?.stripeJs)
        XCTAssertEqual(decoded?.stripeJs?.captchaVendorName, "arkose")
    }

    func testDecodedObjectIntentConfirmationChallengeWithStripeJsMissingVendorName() {
        let response: [AnyHashable: Any] = [
            "type": "intent_confirmation_challenge",
            "stripe_js": [String: Any](),
        ]
        let decoded = STPIntentActionUseStripeSDK.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.type, .intentConfirmationChallenge)
        XCTAssertNotNil(decoded?.stripeJs)
        XCTAssertNil(decoded?.stripeJs?.captchaVendorName)
    }

    func testDecodedObjectIntentConfirmationChallengeWithoutStripeJs() {
        let response: [AnyHashable: Any] = [
            "type": "intent_confirmation_challenge",
        ]
        let decoded = STPIntentActionUseStripeSDK.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.type, .intentConfirmationChallenge)
        XCTAssertNil(decoded?.stripeJs)
    }
}

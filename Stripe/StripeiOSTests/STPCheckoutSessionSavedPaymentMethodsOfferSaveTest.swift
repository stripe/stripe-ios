//
//  STPCheckoutSessionSavedPaymentMethodsOfferSaveTest.swift
//  StripeiOS Tests
//

@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments

class STPCheckoutSessionSavedPaymentMethodsOfferSaveTest: XCTestCase {

    func testDecodedObjectWithSaveOfferAccepted() {
        let json: [String: Any] = [
            "session_id": "cs_test_save_offer",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": true,
                "status": "accepted",
            ],
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertNotNil(session?.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session!.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session!.savedPaymentMethodsOfferSave!.status, .accepted)
    }

    func testDecodedObjectWithSaveOfferDisabled() {
        let json: [String: Any] = [
            "session_id": "cs_test_save_offer",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": false,
                "status": "not_accepted",
            ],
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertNotNil(session?.savedPaymentMethodsOfferSave)
        XCTAssertFalse(session!.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session!.savedPaymentMethodsOfferSave!.status, .notAccepted)
    }

    func testDecodedObjectWithUnrecognizedStatusDefaultsToNotAccepted() {
        let json: [String: Any] = [
            "session_id": "cs_test_save_offer",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": true,
                "status": "some_future_status",
            ],
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertNotNil(session?.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session!.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session!.savedPaymentMethodsOfferSave!.status, .notAccepted)
    }

    func testDecodedObjectWithoutSaveOffer() {
        let json: [String: Any] = [
            "session_id": "cs_test_no_save_offer",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertNil(session?.savedPaymentMethodsOfferSave)
    }
}

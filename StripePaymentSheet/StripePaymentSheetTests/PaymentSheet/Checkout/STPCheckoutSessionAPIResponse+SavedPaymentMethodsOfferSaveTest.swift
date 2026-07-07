//
//  STPCheckoutSessionAPIResponse+SavedPaymentMethodsOfferSaveTest.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

class STPCheckoutSessionSavedPaymentMethodsOfferSaveTest: XCTestCase {

    func testDecodedObjectWithSaveOfferAccepted() {
        let session = CheckoutTestHelpers.makeSession([
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": true,
                "status": "accepted",
            ],
        ])

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session.savedPaymentMethodsOfferSave!.status, .accepted)
    }

    func testDecodedObjectWithSaveOfferDisabled() {
        let session = CheckoutTestHelpers.makeSession([
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": false,
                "status": "not_accepted",
            ],
        ])

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertFalse(session.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session.savedPaymentMethodsOfferSave!.status, .notAccepted)
    }

    func testDecodedObjectWithUnrecognizedStatusDefaultsToNotAccepted() {
        let session = CheckoutTestHelpers.makeSession([
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": true,
                "status": "some_future_status",
            ],
        ])

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session.savedPaymentMethodsOfferSave!.status, .notAccepted)
    }

    func testDecodedObjectWithoutSaveOffer() {
        let session = CheckoutTestHelpers.makeSession()

        XCTAssertNil(session.savedPaymentMethodsOfferSave)
    }
}

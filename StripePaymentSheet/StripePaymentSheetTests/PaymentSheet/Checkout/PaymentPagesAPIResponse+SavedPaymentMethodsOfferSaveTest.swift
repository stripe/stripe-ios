//
//  PaymentPagesAPIResponse+SavedPaymentMethodsOfferSaveTest.swift
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
        ]).makePublicSession()

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
        ]).makePublicSession()

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertFalse(session.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session.savedPaymentMethodsOfferSave!.status, .notAccepted)
    }

    func testDecodedObjectTreatsUnrecognizedStatusAsNotAccepted() {
        let session = CheckoutTestHelpers.makeSession([
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": true,
                "status": "some_future_status",
            ],
        ]).makePublicSession()

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session.savedPaymentMethodsOfferSave!.status, .notAccepted)
    }

    func testDecodedObjectRequiresEnabledButAllowsMissingStatus() throws {
        let missingEnabled = CheckoutTestHelpers.makeSessionJSON([
            "customer_managed_saved_payment_methods_offer_save": ["status": "not_accepted"],
        ])
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: missingEnabled))

        // CheckoutClient supplies the save offer without a status.
        let missingStatus = CheckoutTestHelpers.makeSessionJSON([
            "customer_managed_saved_payment_methods_offer_save": ["enabled": true],
        ])
        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: missingStatus).makePublicSession()
        XCTAssertTrue(try XCTUnwrap(session.savedPaymentMethodsOfferSave).enabled)
        XCTAssertNil(session.savedPaymentMethodsOfferSave?.status)
    }

    func testDecodedObjectWithoutSaveOffer() {
        let session = CheckoutTestHelpers.makeSession().makePublicSession()

        XCTAssertNil(session.savedPaymentMethodsOfferSave)
    }
}

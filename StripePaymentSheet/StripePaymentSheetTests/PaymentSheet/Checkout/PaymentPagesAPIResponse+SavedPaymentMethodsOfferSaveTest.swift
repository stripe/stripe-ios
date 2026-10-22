//
//  PaymentPagesAPIResponse+SavedPaymentMethodsOfferSaveTest.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

class STPCheckoutSessionSavedPaymentMethodsOfferSaveTest: XCTestCase {

    func testDecodedObjectWithSaveOfferEnabled() {
        let session = CheckoutTestHelpers.makeSession([
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": true,
            ],
        ]).makePublicSession()

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)
    }

    func testDecodedObjectWithSaveOfferDisabled() {
        let session = CheckoutTestHelpers.makeSession([
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": false,
            ],
        ]).makePublicSession()

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertFalse(session.savedPaymentMethodsOfferSave!.enabled)
    }

    func testDecodedObjectIgnoresLegacyStatus() {
        let session = CheckoutTestHelpers.makeSession([
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": true,
                "status": "some_future_status",
            ],
        ]).makePublicSession()

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)
    }

    func testDecodedObjectRequiresEnabled() throws {
        let missingEnabled = CheckoutTestHelpers.makeSessionJSON([
            "customer_managed_saved_payment_methods_offer_save": ["status": "not_accepted"],
        ])
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: missingEnabled))

        // CheckoutClient supplies only whether saving is enabled.
        let missingStatus = CheckoutTestHelpers.makeSessionJSON([
            "customer_managed_saved_payment_methods_offer_save": ["enabled": true],
        ])
        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: missingStatus).makePublicSession()
        XCTAssertTrue(try XCTUnwrap(session.savedPaymentMethodsOfferSave).enabled)
    }

    func testDecodedObjectWithoutSaveOffer() {
        let session = CheckoutTestHelpers.makeSession().makePublicSession()

        XCTAssertNil(session.savedPaymentMethodsOfferSave)
    }
}

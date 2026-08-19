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

    func testDecodedObjectRejectsUnrecognizedStatus() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "customer_managed_saved_payment_methods_offer_save": [
                "enabled": true,
                "status": "some_future_status",
            ],
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testDecodedObjectRejectsMissingRequiredSaveOfferFields() {
        for field in ["enabled", "status"] {
            var offerSave: [String: Any] = [
                "enabled": true,
                "status": "not_accepted",
            ]
            offerSave.removeValue(forKey: field)
            let json = CheckoutTestHelpers.makeSessionJSON([
                "customer_managed_saved_payment_methods_offer_save": offerSave,
            ])

            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing \(field) to fail decoding"
            )
        }
    }

    func testDecodedObjectWithoutSaveOffer() {
        let session = CheckoutTestHelpers.makeSession().makePublicSession()

        XCTAssertNil(session.savedPaymentMethodsOfferSave)
    }
}

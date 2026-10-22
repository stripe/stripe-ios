//
//  CheckoutClientAPIResponse+SavedPaymentMethodsOfferSaveTest.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

class STPCheckoutSessionSavedPaymentMethodsOfferSaveTest: XCTestCase {

    func testDecodedObjectWithSaveOfferEnabled() {
        let session = CheckoutTestHelpers.makeSession([
            "saved_payment_method_options": [
                "payment_method_save": "enabled"
            ],
        ]).makePublicSession()

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)
    }

    func testDecodedObjectWithSaveOfferDisabled() {
        let session = CheckoutTestHelpers.makeSession([
            "saved_payment_method_options": [
                "payment_method_save": "disabled"
            ],
        ]).makePublicSession()

        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertFalse(session.savedPaymentMethodsOfferSave!.enabled)
    }

    func testDecodedObjectWithoutPaymentMethodSave() {
        let session = CheckoutTestHelpers.makeSession([
            "saved_payment_method_options": ["payment_method_remove": "enabled"]
        ]).makePublicSession()

        XCTAssertNil(session.savedPaymentMethodsOfferSave)
    }

    func testDecodedObjectWithoutSaveOffer() {
        let session = CheckoutTestHelpers.makeSession().makePublicSession()

        XCTAssertNil(session.savedPaymentMethodsOfferSave)
    }
}

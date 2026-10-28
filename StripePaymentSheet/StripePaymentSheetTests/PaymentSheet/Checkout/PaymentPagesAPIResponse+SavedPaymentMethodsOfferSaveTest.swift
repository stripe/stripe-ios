//
//  PaymentPagesAPIResponse+SavedPaymentMethodsOfferSaveTest.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
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

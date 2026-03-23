//
//  STPPaymentMethodCardArtTest.swift
//  StripeiOS Tests
//

@testable @_spi(STP) import StripePayments
import XCTest

class STPPaymentMethodCardArtTest: XCTestCase {

    func testDecodedObject_allFields() {
        let response: [AnyHashable: Any] = [
            "payment_method": "pm_123",
            "url": "https://b.stripecdn.com/cardart/assets/abc123",
            "program_name": "My Program",
        ]
        let cardArt = STPPaymentMethodCardArt.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(cardArt)
        XCTAssertEqual(cardArt?.paymentMethod, "pm_123")
        XCTAssertEqual(cardArt?.url?.absoluteString, "https://b.stripecdn.com/cardart/assets/abc123")
        XCTAssertEqual(cardArt?.programName, "My Program")
    }

    func testDecodedObject_onlyRequiredFields() {
        let response: [AnyHashable: Any] = ["payment_method": "pm_456"]
        let cardArt = STPPaymentMethodCardArt.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(cardArt)
        XCTAssertEqual(cardArt?.paymentMethod, "pm_456")
        XCTAssertNil(cardArt?.url)
        XCTAssertNil(cardArt?.programName)
    }

    func testDecodedObject_nilResponse() {
        XCTAssertNil(STPPaymentMethodCardArt.decodedObject(fromAPIResponse: nil))
    }

    func testDecodedObject_missingPaymentMethod() {
        let response: [AnyHashable: Any] = [
            "url": "https://b.stripecdn.com/cardart/assets/abc123",
            "program_name": "Name",
        ]
        XCTAssertNil(STPPaymentMethodCardArt.decodedObject(fromAPIResponse: response))
    }
}

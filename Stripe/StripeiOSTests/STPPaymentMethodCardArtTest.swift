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
            "art_image": ["url": "https://b.stripecdn.com/cardart/assets/abc123"],
            "program_name": "My Program",
        ]
        let cardArt = STPPaymentMethodCardArt.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(cardArt)
        XCTAssertEqual(cardArt?.paymentMethod, "pm_123")
        XCTAssertEqual(cardArt?.artImage?.url?.absoluteString, "https://b.stripecdn.com/cardart/assets/abc123")
        XCTAssertEqual(cardArt?.programName, "My Program")
    }

    func testDecodedObject_onlyRequiredFields() {
        let response: [AnyHashable: Any] = ["payment_method": "pm_456"]
        let cardArt = STPPaymentMethodCardArt.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(cardArt)
        XCTAssertEqual(cardArt?.paymentMethod, "pm_456")
        XCTAssertNil(cardArt?.artImage)
        XCTAssertNil(cardArt?.programName)
    }

    func testDecodedObject_artImageWithoutUrl() {
        let response: [AnyHashable: Any] = [
            "payment_method": "pm_789",
            "art_image": [:] as [AnyHashable: Any],
        ]
        let cardArt = STPPaymentMethodCardArt.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(cardArt)
        XCTAssertNotNil(cardArt?.artImage)
        XCTAssertNil(cardArt?.artImage?.url)
    }

    func testDecodedObject_nilResponse() {
        XCTAssertNil(STPPaymentMethodCardArt.decodedObject(fromAPIResponse: nil))
    }

    func testDecodedObject_missingPaymentMethod() {
        let response: [AnyHashable: Any] = [
            "art_image": ["url": "https://b.stripecdn.com/cardart/assets/abc123"],
            "program_name": "Name",
        ]
        XCTAssertNil(STPPaymentMethodCardArt.decodedObject(fromAPIResponse: response))
    }
}

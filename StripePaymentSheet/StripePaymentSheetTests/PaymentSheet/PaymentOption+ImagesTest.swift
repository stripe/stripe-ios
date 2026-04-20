//
//  PaymentOption+ImagesTest.swift
//  StripePaymentSheetTests
//

@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class PaymentOptionImagesTest: XCTestCase {

    // MARK: - STPPaymentMethod.cardArtURL

    func testCardArtURL_nilWhenNoCardArt() {
        let pm = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_1",
            "type": "card",
            "created": 1651273166,
            "card": [
                "last4": "4242",
                "brand": "visa",
                "exp_month": "12",
                "exp_year": "2030",
            ],
        ])!
        XCTAssertNil(pm.cardArtCDNURL(cardArtEnabled: true))
    }

    func testCardArtURL_nilWhenCardArtHasNoURL() {
        let pm = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_1",
            "type": "card",
            "created": 1651273166,
            "card": [
                "last4": "4242",
                "brand": "visa",
                "exp_month": "12",
                "exp_year": "2030",
                "card_art": [
                    "payment_method": "pm_1",
                ],
            ],
        ])!
        XCTAssertNil(pm.cardArtCDNURL(cardArtEnabled: true))
    }
    func testCardArtURL_nil() {
        let pm = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_1",
            "type": "card",
            "created": 1651273166,
            "card": [
                "last4": "4242",
                "brand": "visa",
                "exp_month": "12",
                "exp_year": "2030",
                "card_art": [
                    "payment_method": "pm_1",
                    "art_image": ["url": "https://b.stripecdn.com/cardart/assets/abc123"],
                ],
            ],
        ])!
        let url = pm.cardArtCDNURL(cardArtEnabled: false)
        XCTAssertNil(url)
    }
    func testCardArtURL_returnsCDNURL() {
        let pm = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_1",
            "type": "card",
            "created": 1651273166,
            "card": [
                "last4": "4242",
                "brand": "visa",
                "exp_month": "12",
                "exp_year": "2030",
                "card_art": [
                    "payment_method": "pm_1",
                    "art_image": ["url": "https://b.stripecdn.com/cardart/assets/abc123"],
                ],
            ],
        ])!
        let url = pm.cardArtCDNURL(cardArtEnabled: true)
        XCTAssertNotNil(url)

        XCTAssertEqual(url!.absoluteString, "https://img.stripecdn.com/cdn-cgi/image/format=auto,height=26,dpr=3/https://b.stripecdn.com/cardart/assets/abc123")
        XCTAssertTrue(url!.absoluteString.contains("height=26"))
        XCTAssertTrue(url!.absoluteString.contains("dpr=3"))
    }

    func testCardArtURL_nilForNonCardPaymentMethod() {
        let pm = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_1",
            "type": "us_bank_account",
            "created": 1651273166,
            "us_bank_account": [
                "bank_name": "Test Bank",
                "last4": "6789",
            ],
        ])!
        XCTAssertNil(pm.cardArtCDNURL(cardArtEnabled: true))
    }
}

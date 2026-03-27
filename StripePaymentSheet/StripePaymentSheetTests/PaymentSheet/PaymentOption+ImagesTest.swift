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
        XCTAssertNil(pm.cardArtCDNURL(height: 40))
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
        XCTAssertNil(pm.cardArtCDNURL(height: 40))
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
                    "art_image": "https://b.stripecdn.com/cardart/assets/abc123",
                ],
            ],
        ])!
        let url = pm.cardArtCDNURL(height: 40)
        XCTAssertNotNil(url)

        XCTAssertEqual(url!.absoluteString, "https://img.stripecdn.com/cdn-cgi/image/format=auto,height=40,dpr=3/https://b.stripecdn.com/cardart/assets/abc123")
        XCTAssertTrue(url!.absoluteString.contains("height=40"))
        XCTAssertTrue(url!.absoluteString.contains("dpr=3"))
    }

    func testCardArtURL_respectsHeightParameter() {
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
                    "art_image": "https://b.stripecdn.com/cardart/assets/abc123",
                ],
            ],
        ])!
        let url20 = pm.cardArtCDNURL(height: 20)
        XCTAssertEqual(url20!.absoluteString, "https://img.stripecdn.com/cdn-cgi/image/format=auto,height=20,dpr=3/https://b.stripecdn.com/cardart/assets/abc123")

        let url40 = pm.cardArtCDNURL(height: 40)
        XCTAssertEqual(url40!.absoluteString, "https://img.stripecdn.com/cdn-cgi/image/format=auto,height=40,dpr=3/https://b.stripecdn.com/cardart/assets/abc123")

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
        XCTAssertNil(pm.cardArtCDNURL(height: 40))
    }
}

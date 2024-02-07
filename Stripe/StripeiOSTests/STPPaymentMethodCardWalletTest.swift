//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodCardWalletTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import StripePayments

class STPPaymentMethodCardWalletTest: XCTestCase {
    // MARK: - STPPaymentMethodCardWalletType Tests

    func testTypeFromString() {
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "amex_express_checkout"), .amexExpressCheckout)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "AMEX_EXPRESS_CHECKOUT"), .amexExpressCheckout)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "apple_pay"), .applePay)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "APPLE_PAY"), .applePay)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "google_pay"), .googlePay)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "GOOGLE_PAY"), .googlePay)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "masterpass"), .masterpass)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "MASTERPASS"), .masterpass)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "samsung_pay"), .samsungPay)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "SAMSUNG_PAY"), .samsungPay)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "visa_checkout"), .visaCheckout)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "VISA_CHECKOUT"), .visaCheckout)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "link"), .link)
        XCTAssertEqual(STPPaymentMethodCardWallet.type(from: "LINK"), .link)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseMapping() {
        let response = (STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)["card"] as! [AnyHashable: Any]) ["wallet"] as? [AnyHashable: Any]
        let wallet = STPPaymentMethodCardWallet.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(wallet)
        XCTAssertEqual(wallet?.type, .visaCheckout)
    }
}

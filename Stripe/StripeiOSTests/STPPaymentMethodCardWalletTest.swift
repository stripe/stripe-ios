//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentMethodCardWalletTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodCardWalletTest: XCTestCase {
    // MARK: - STPPaymentMethodCardWalletType Tests

    func testTypeFromString() {
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "amex_express_checkout"), Int(STPPaymentMethodCardWalletTypeAmexExpressCheckout))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "AMEX_EXPRESS_CHECKOUT"), Int(STPPaymentMethodCardWalletTypeAmexExpressCheckout))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "apple_pay"), Int(STPPaymentMethodCardWalletTypeApplePay))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "APPLE_PAY"), Int(STPPaymentMethodCardWalletTypeApplePay))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "google_pay"), Int(STPPaymentMethodCardWalletTypeGooglePay))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "GOOGLE_PAY"), Int(STPPaymentMethodCardWalletTypeGooglePay))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "masterpass"), Int(STPPaymentMethodCardWalletTypeMasterpass))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "MASTERPASS"), Int(STPPaymentMethodCardWalletTypeMasterpass))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "samsung_pay"), Int(STPPaymentMethodCardWalletTypeSamsungPay))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "SAMSUNG_PAY"), Int(STPPaymentMethodCardWalletTypeSamsungPay))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "visa_checkout"), Int(STPPaymentMethodCardWalletTypeVisaCheckout))
        XCTAssertEqual(STPPaymentMethodCardWallet.type(fromString: "VISA_CHECKOUT"), Int(STPPaymentMethodCardWalletTypeVisaCheckout))
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["card"]["wallet"] as? [AnyHashable : Any]
        let wallet = STPPaymentMethodCardWallet.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(Int(wallet ?? 0))
        XCTAssertEqual(wallet?.type ?? 0, Int(STPPaymentMethodCardWalletTypeVisaCheckout))
    }
}

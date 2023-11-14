//
//  STPElementsSessionTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 2/16/23.
//

import XCTest
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentSheet

class STPElementsSessionTest: XCTestCase {

    // MARK: - STPAPIResponseDecodable Tests
    func testDecodedObjectFromAPIResponseMapping() {
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        elementsSessionJson["unactivated_payment_method_types"] = ["cashapp"]
        elementsSessionJson["card_brand_choice"] = ["eligible": true]
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!

        XCTAssertEqual(
            elementsSession.orderedPaymentMethodTypes,
            [
                STPPaymentMethodType.card,
                STPPaymentMethodType.link,
                STPPaymentMethodType.USBankAccount,
                STPPaymentMethodType.afterpayClearpay,
                STPPaymentMethodType.klarna,
                STPPaymentMethodType.cashApp,
                STPPaymentMethodType.alipay,
                STPPaymentMethodType.weChatPay,
            ]
        )

        XCTAssertEqual(
            elementsSession.unactivatedPaymentMethodTypes,
            [STPPaymentMethodType.cashApp]
        )

        XCTAssertNotNil(elementsSession.linkSettings)
        XCTAssertEqual(elementsSession.countryCode, "US")
        XCTAssertEqual(elementsSession.merchantCountryCode, "US")
        XCTAssertNotNil(elementsSession.paymentMethodSpecs)
        XCTAssertEqual(elementsSession.cardBrandChoice?.eligible, true)
        XCTAssertTrue(elementsSession.isApplePayEnabled)
        XCTAssertEqual(elementsSession.allResponseFields as NSDictionary, elementsSessionJson as NSDictionary)
    }

    func testDecodedObjectFromAPIResponseMapping_applePayPreferenceDisabled() {
        var elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        elementsSessionJson["apple_pay_preference"] = "disabled"
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!

        XCTAssertFalse(elementsSession.isApplePayEnabled)
    }
}

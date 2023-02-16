//
//  STPElementsSessionTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 2/16/23.
//

import Foundation
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet

class STPElementsSessionTest: XCTestCase {

    // MARK: - Description Tests
    func testDescription() {
        let elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!

        XCTAssertNotNil(elementsSession)
        let desc = elementsSession.description
        XCTAssertTrue(desc.contains(NSStringFromClass(type(of: elementsSession).self)))
        XCTAssertGreaterThan((desc.count), 500, "Custom description should be long")
    }

    // MARK: - STPAPIResponseDecodable Tests
    func testDecodedObjectFromAPIResponseMapping() {
        let elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")!
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
        XCTAssertNotNil(elementsSession.paymentMethodSpecs)
    }

}

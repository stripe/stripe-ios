//
//  ElementsContextTests.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-20.
//

import XCTest

@testable @_spi(STP) import StripeCore

final class ElementsContextTests: XCTestCase {
    func testEmptyParameters() {
        let additionalParameter: [String: Any] = [:]
        let elementsContext = ElementsContext(from: additionalParameter)

        XCTAssertNotNil(elementsContext)
        XCTAssertNil(elementsContext.hostedSurface)
    }

    func testHostedSurface() {
        var additionalParameter = ["hosted_surface": "gibberish"]
        let gibberishElementsContext = ElementsContext(from: additionalParameter)

        XCTAssertNotNil(gibberishElementsContext)
        XCTAssertNil(gibberishElementsContext.hostedSurface)

        additionalParameter["hosted_surface"] = "payment_element"
        let paymentElementElementsContext = ElementsContext(from: additionalParameter)

        XCTAssertEqual(paymentElementElementsContext.hostedSurface, .paymentsSheet)

        additionalParameter["hosted_surface"] = "customer_sheet"
        let customerSheetElementsContext = ElementsContext(from: additionalParameter)

        XCTAssertEqual(customerSheetElementsContext.hostedSurface, .customerSheet)
    }
}

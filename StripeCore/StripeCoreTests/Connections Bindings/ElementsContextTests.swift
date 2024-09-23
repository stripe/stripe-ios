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
        XCTAssertNil(elementsContext.linkMode)
    }

    func testLinkMode() {
        let linkModeKey = "link_mode"

        var additionalParameter = [linkModeKey: "gibberish"]
        let gibberishElementsContext = ElementsContext(from: additionalParameter)

        XCTAssertNotNil(gibberishElementsContext)
        XCTAssertNil(gibberishElementsContext.linkMode)
        XCTAssertNil(gibberishElementsContext.linkMode?.isPantherPayment)

        additionalParameter[linkModeKey] = "LINK_PAYMENT_METHOD"
        let lpmElementsContext = ElementsContext(from: additionalParameter)

        XCTAssertEqual(lpmElementsContext.linkMode, .linkPaymentMethod)
        XCTAssert(lpmElementsContext.linkMode?.isPantherPayment == false)

        additionalParameter[linkModeKey] = "PASSTHROUGH"
        let passthroughElementsContext = ElementsContext(from: additionalParameter)

        XCTAssertEqual(passthroughElementsContext.linkMode, .passthrough)
        XCTAssert(passthroughElementsContext.linkMode?.isPantherPayment == false)

        additionalParameter[linkModeKey] = "LINK_CARD_BRAND"
        let linkCardBrandElementsContext = ElementsContext(from: additionalParameter)

        XCTAssertEqual(linkCardBrandElementsContext.linkMode, .linkCardBrand)
        XCTAssert(linkCardBrandElementsContext.linkMode?.isPantherPayment == true)
    }
}

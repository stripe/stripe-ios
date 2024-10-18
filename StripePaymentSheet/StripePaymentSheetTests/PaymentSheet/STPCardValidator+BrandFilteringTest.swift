//
//  STPCardValidator+BrandFilteringTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/11/24.
//

@testable @_spi(CardBrandFilteringBeta) import StripePaymentSheet
import StripePaymentsTestUtils
import XCTest

class STPCardValidator_BrandFilteringTest: XCTestCase {

    let testVisaCoBrandedNumber = "49730197"

    func testPossibleBrands_allAllowed() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let expectation = expectation(description: "Visa/CB")

        STPCardValidator.possibleBrands(forNumber: testVisaCoBrandedNumber, with: .default) { result in
            let brands = try! result.get()
            XCTAssertEqual(brands, [.cartesBancaires, .visa])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testPossibleBrands_visaNotAllowed() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let expectation = expectation(description: "Visa/CB")

        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: [.visa]))
        STPCardValidator.possibleBrands(forNumber: testVisaCoBrandedNumber, with: filter) { result in
            let brands = try! result.get()
            XCTAssertEqual(brands, [.cartesBancaires])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testPossibleBrands_visaOnlyAllowed() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let expectation = expectation(description: "Visa/CB")

        let filter = CardBrandFilter(cardBrandAcceptance: .allowed(brands: [.visa]))
        STPCardValidator.possibleBrands(forNumber: testVisaCoBrandedNumber, with: filter) { result in
            let brands = try! result.get()
            XCTAssertEqual(brands, [.visa])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

}

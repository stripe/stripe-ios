//
//  STPCardValidator+BrandFilteringTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 9/21/24.
//

@testable @_spi(CardBrandFilteringAlpha) import StripePaymentSheet
import StripePaymentsTestUtils
import XCTest

class STPCardValidator_BrandFilteringTest: XCTestCase {
    
    let testMastercardCoBrandedNumber = "5131301234"
    
    func testPossibleBrands_allAllowed() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let expectation = expectation(description: "Mastercard/CBC")

        STPCardValidator.possibleBrands(forNumber: testMastercardCoBrandedNumber, with: .default) { result in
            let brands = try! result.get()
            XCTAssertEqual(brands, [.cartesBancaires, .mastercard])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPossibleBrands_mastercardNotAllowed() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let expectation = expectation(description: "Mastercard/CBC")
        
        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: [.mastercard]))
        STPCardValidator.possibleBrands(forNumber: testMastercardCoBrandedNumber, with: filter) { result in
            let brands = try! result.get()
            XCTAssertEqual(brands, [.cartesBancaires])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPossibleBrands_mastercardOnlyAllowed() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let expectation = expectation(description: "Mastercard/CBC")
        
        let filter = CardBrandFilter(cardBrandAcceptance: .allowed(brands: [.mastercard]))
        STPCardValidator.possibleBrands(forNumber: testMastercardCoBrandedNumber, with: filter) { result in
            let brands = try! result.get()
            // CB should not be filtered out.
            XCTAssertEqual(brands, [.cartesBancaires, .mastercard])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
}

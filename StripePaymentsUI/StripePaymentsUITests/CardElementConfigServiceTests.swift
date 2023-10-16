//
//  CardElementConfigServiceTests.swift
//  StripePaymentsUITests
//

import Foundation

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripePaymentsUI
@_spi(STP) @testable import StripeCoreTestUtils
import XCTest

class CardElementConfigServiceTests: APIStubbedTestCase {
    
    func testFetchConfig() throws {
        let exp = expectation(description: "fetched config")
        let cecs = CardElementConfigService()
        cecs.apiClient = stubbedAPIClient()
        cecs.apiClient.publishableKey = "pk_test_123abc"
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/mobile-card-element-config") ?? false
        } response: { _ in
            let responseData = """
            {"card_brand_choice":{"eligible":true}}
            """.data(using: .utf8)!
            defer {
                exp.fulfill()
            }
            return HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
        }
        // Returns false at first...
        XCTAssertFalse(cecs.isCBCEligible)
        
        waitForExpectations(timeout: 3.0)
        // But after waiting for the response (and another turn of the runloop), it returns true!
        let exp2 = expectation(description: "processed and checked response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(cecs.isCBCEligible)
            exp2.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
}

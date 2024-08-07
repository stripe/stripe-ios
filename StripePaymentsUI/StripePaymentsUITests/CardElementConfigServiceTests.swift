//
//  CardElementConfigServiceTests.swift
//  StripePaymentsUITests
//

import Foundation

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentsUI
import XCTest

class CardElementConfigServiceTests: APIStubbedTestCase {

    func testSuccessfullyFetchesConfig() throws {
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
        XCTAssertFalse(cecs.isCBCEligible())

        waitForExpectations(timeout: 3.0)
        // But after waiting for the response (and another turn of the runloop), it returns true!
        let exp2 = expectation(description: "processed and checked response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(cecs.isCBCEligible())
            exp2.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testSuccessfullyFetchesConfigForOnBehalfOf() throws {
        let exp = expectation(description: "fetched config")
        let cecs = CardElementConfigService()
        cecs.apiClient = stubbedAPIClient()
        cecs.apiClient.publishableKey = "pk_test_123abc"
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/mobile-card-element-config?on_behalf_of=acct_abc123") ?? false
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
        XCTAssertFalse(cecs.isCBCEligible(onBehalfOf: "acct_abc123"))

        waitForExpectations(timeout: 3.0)
        // But after waiting for the response (and another turn of the runloop), it returns true!
        let exp2 = expectation(description: "processed and checked response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(cecs.isCBCEligible(onBehalfOf: "acct_abc123"))
            exp2.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testNothingBadHappensOnInvalidData() throws {
        let exp = expectation(description: "fetched config")
        let cecs = CardElementConfigService()
        cecs.apiClient = stubbedAPIClient()
        cecs.apiClient.publishableKey = "pk_test_123abc"
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/mobile-card-element-config") ?? false
        } response: { _ in
            let responseData = """
            {"card_brand_choice":{"eligible":"chicken"}}
            """.data(using: .utf8)!
            defer {
                exp.fulfill()
            }
            return HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
        }
        // Returns false at first...
        XCTAssertFalse(cecs.isCBCEligible())

        waitForExpectations(timeout: 3.0)
        // But after waiting for the response (and another turn of the runloop), it still returns false (as the response was invalid)
        let exp2 = expectation(description: "processed and checked response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(cecs.isCBCEligible())
            exp2.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

}

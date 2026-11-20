//
//  STPAPIClient+LinkAccountSessionTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 4/26/23.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
import XCTest

final class STPAPIClient_LinkAccountSessionTest: XCTestCase {

    func testCreateLinkAccountSessionForDeferredIntent() {
        let e = expectation(description: "create link account session")
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        apiClient.createLinkAccountSessionForDeferredIntent(
            sessionId: "mobile_test_\(UUID().uuidString)",
            amount: nil,
            currency: nil,
            onBehalfOf: nil,
            linkMode: nil
        ) { linkAccountSession, error in
            XCTAssertNil(error)
            XCTAssertNotNil(linkAccountSession)
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}

final class STPAPIClient_LinkAccountSessionStubbedTest: APIStubbedTestCase {

    func testCreateLinkAccountSessionForDeferredIntentOmitsZeroAmount() {
        // Given a $0 amount, which the backend rejects
        // When creating a Link account session
        let queryItems = sentQueryItems(amount: 0)

        // Then the amount is omitted
        XCTAssertNil(queryItems.first { $0.name == "amount" })
        // ...and the currency is still sent
        XCTAssertEqual(queryItems.first { $0.name == "currency" }?.value, "usd")
    }

    func testCreateLinkAccountSessionForDeferredIntentSendsPositiveAmount() {
        // Given a $23.45 amount
        // When creating a Link account session
        let queryItems = sentQueryItems(amount: 2345)

        // Then the amount is sent
        XCTAssertEqual(queryItems.first { $0.name == "amount" }?.value, "2345")
    }

    private func sentQueryItems(amount: Int?) -> [URLQueryItem] {
        let apiClient = stubbedAPIClient()
        var queryItems: [URLQueryItem] = []
        stub { urlRequest in
            urlRequest.url?.absoluteString.contains("link_account_sessions_for_deferred_payment") ?? false
        } response: { urlRequest in
            queryItems = urlRequest.queryItems ?? []
            return HTTPStubsResponse(jsonObject: [:], statusCode: 400, headers: nil)
        }

        let e = expectation(description: "create link account session")
        apiClient.createLinkAccountSessionForDeferredIntent(
            sessionId: "mobile_test_\(UUID().uuidString)",
            amount: amount,
            currency: "usd",
            onBehalfOf: nil,
            linkMode: nil
        ) { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
        return queryItems
    }
}

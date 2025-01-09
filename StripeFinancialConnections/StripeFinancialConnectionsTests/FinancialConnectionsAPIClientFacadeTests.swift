//
//  FinancialConnectionsAPIClientFacadeTests.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-08.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripeFinancialConnections

class FinancialConnectionsAPIClientFacadeTests: XCTestCase {
    private let mockBackingApiClient = APIStubbedTestCase.stubbedAPIClient()

    private var legacyFacade: FinancialConnectionsAPIClientFacade!
    private var asyncFacade: FinancialConnectionsAPIClientFacade!

    override func setUp() {
        super.setUp()

        self.legacyFacade = FinancialConnectionsAPIClientFacade(
            apiClient: mockBackingApiClient,
            shouldUseAsyncClient: false
        )
        self.asyncFacade = FinancialConnectionsAPIClientFacade(
            apiClient: mockBackingApiClient,
            shouldUseAsyncClient: true
        )
    }

    override func tearDown() {
        super.tearDown()
        legacyFacade = nil
        asyncFacade = nil
    }

    func testApiClientClass() {
        XCTAssertTrue(legacyFacade.apiClient is FinancialConnectionsAPIClient)
        XCTAssertTrue(asyncFacade.apiClient is FinancialConnectionsAsyncAPIClient)
    }

    func testSynchronizeEquality() throws {
        let mock = FinancialConnectionsSynchronizeMock.synchronize
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/financial_connections/sessions/synchronize") ?? false
        } response: { _ in
            let data = try! mock.data()
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }

        let clientSecret = "client_secret"

        var legacyResult: Result<FinancialConnectionsSynchronize, any Error>?
        var asyncResult: Result<FinancialConnectionsSynchronize, any Error>?

        let legacyExpectation = expectation(description: "legacy synchronize complete")
        let asyncExpectation = expectation(description: "async synchronize complete")

        legacyFacade
            .synchronize(clientSecret: clientSecret, returnURL: nil)
            .observe { result in
                legacyResult = result
                legacyExpectation.fulfill()
            }

        asyncFacade
            .synchronize(clientSecret: clientSecret, returnURL: nil)
            .observe { result in
                asyncResult = result
                asyncExpectation.fulfill()
            }

        wait(for: [legacyExpectation, asyncExpectation], timeout: 5.0)

        guard case .success(let legacySynchronize) = legacyResult else {
            XCTFail("Legacy synchronize resulted in error.")
            return
        }

        guard case .success(let asyncSynchronize) = asyncResult else {
            XCTFail("Async synchronize resulted in error.")
            return
        }

        // Since the response model isn't Equatable, we'll compare an arbitrary property in both responses.
        let expectedSynchronize = try mock.make()
        let expectedAccountholderToken = expectedSynchronize.manifest.accountholderToken
        XCTAssertNotNil(expectedAccountholderToken)
        XCTAssertEqual(legacySynchronize.manifest.accountholderToken, expectedAccountholderToken)
        XCTAssertEqual(asyncSynchronize.manifest.accountholderToken, expectedAccountholderToken)
    }
}

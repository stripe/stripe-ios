//
//  STPAPIClient+CryptoOnrampTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 7/17/25.
//

import StripeCore
import StripeCoreTestUtils
@testable import StripeCryptoOnramp

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

final class STPAPIClientCryptoOnrampTests: APIStubbedTestCase {

    enum Constant {
        static let requestSecret = "cscs_12345"
        static let responseID = "crc_12345"
        static let grantPartnerMerchantPermissionsAPIPath = "/v1/crypto/internal/customers"
        static let errorDomain = "STPAPIClientCryptoOnrampTests.Error"
    }

    func testGrantPartnerMerchantPermissionsSuccess() throws {
        let mockResponseData = try JSONEncoder().encode(CustomerResponse(id: Constant.responseID))

        stub { request in
            XCTAssertEqual(request.url?.path, Constant.grantPartnerMerchantPermissionsAPIPath)
            XCTAssertEqual(request.httpMethod, "POST")

            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody data but found none.")
                return false
            }

            XCTAssertEqual(String(data: httpBody, encoding: .utf8), "credentials[consumer_session_client_secret]=\(Constant.requestSecret)")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        let expectation = expectation(description: "`grantPartnerMerchantPermissions` request completed.")

        Task {
            do {
                let response = try await apiClient.grantPartnerMerchantPermissions(consumerSessionClientSecret: Constant.requestSecret)
                XCTAssertEqual(response.id, Constant.responseID)
            } catch {
                XCTFail("Expected a success response but got an error: \(error).")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testGrantPartnerMerchantPermissionsFailure() throws {
        stub { request in
            XCTAssertEqual(request.url?.path, Constant.grantPartnerMerchantPermissionsAPIPath)
            return true
        } response: { _ in
            return HTTPStubsResponse(error: NSError(domain: Constant.errorDomain, code: 400))
        }

        let apiClient = stubbedAPIClient()
        let expectation = expectation(description: "`grantPartnerMerchantPermissions` request completed.")

        Task {
            do {
                _ = try await apiClient.grantPartnerMerchantPermissions(consumerSessionClientSecret: Constant.requestSecret)
                XCTFail("Expected failure but got success.")
            } catch {
                XCTAssertEqual((error as NSError).domain, Constant.errorDomain)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }
}

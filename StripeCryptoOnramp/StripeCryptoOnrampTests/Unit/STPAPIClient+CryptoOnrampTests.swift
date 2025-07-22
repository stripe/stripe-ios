//
//  STPAPIClient+CryptoOnrampTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 7/17/25.
//

import StripeCore
import StripeCoreTestUtils
@testable import StripeCryptoOnramp
@_spi(STP) import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

final class STPAPIClientCryptoOnrampTests: APIStubbedTestCase {

    private enum Constant {
        static let requestSecret = "cscs_12345"
        static let responseID = "crc_12345"
        static let grantPartnerMerchantPermissionsAPIPath = "/v1/crypto/internal/customers"
        static let errorDomain = "STPAPIClientCryptoOnrampTests.Error"
        static let validLinkAccountInfo = LinkAccountInfo(
            email: "test@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true,
            sessionState: .verified,
            consumerSessionClientSecret: requestSecret
        )
    }

    private struct LinkAccountInfo: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        var sessionState: StripePaymentSheet.PaymentSheetLinkAccount.SessionState
        var consumerSessionClientSecret: String?
    }

    func testGrantPartnerMerchantPermissionsSuccess() async throws {
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
        do {
            let response = try await apiClient.grantPartnerMerchantPermissions(with: Constant.validLinkAccountInfo)
            XCTAssertEqual(response.id, Constant.responseID)
        } catch {
            XCTFail("Expected a success response but got an error: \(error).")
        }

    }

    func testGrantPartnerMerchantPermissionsFailure() async {
        stub { request in
            XCTAssertEqual(request.url?.path, Constant.grantPartnerMerchantPermissionsAPIPath)
            return true
        } response: { _ in
            return HTTPStubsResponse(error: NSError(domain: Constant.errorDomain, code: 400))
        }

        let apiClient = stubbedAPIClient()

        do {
            _ = try await apiClient.grantPartnerMerchantPermissions(with: Constant.validLinkAccountInfo)
            XCTFail("Expected failure but got success.")
        } catch {
            XCTAssertEqual((error as NSError).domain, Constant.errorDomain)
        }
    }

    func testGrantPartnerMerchantPermissionsThrowsWithInvalidArguments() async {
        let apiClient = stubbedAPIClient()

        var noSecretLinkAccountInfo = Constant.validLinkAccountInfo
        noSecretLinkAccountInfo.consumerSessionClientSecret = nil
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.grantPartnerMerchantPermissions(with: noSecretLinkAccountInfo))

        var unverifiedLinkAccountInfo = Constant.validLinkAccountInfo
        unverifiedLinkAccountInfo.sessionState = .requiresVerification
        await XCTAssertThrowsErrorAsync(_ = try await apiClient.grantPartnerMerchantPermissions(with: unverifiedLinkAccountInfo))
    }
}

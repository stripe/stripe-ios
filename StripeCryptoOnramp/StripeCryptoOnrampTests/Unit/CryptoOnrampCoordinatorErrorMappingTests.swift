//
//  CryptoOnrampCoordinatorErrorMappingTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 5/26/26.
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
import XCTest

final class CryptoOnrampCoordinatorErrorMappingTests: XCTestCase {

    func testMappedErrorMapsAttestationErrorDecodedFromStripeAPIResponse() throws {
        let responseData = try StripeAPIErrorResponseMock.appAttestationFailure.data()
        let response = HTTPURLResponse(
            url: URL(string: "https://api.stripe.com/v1/consumers/mobile/sessions/lookup")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: ["request-id": "req_attestation_test"]
        )
        let stripeError = try XCTUnwrap(STPAPIClient.decodeStripeErrorResponse(data: responseData, response: response))
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let mappedError = CryptoOnrampCoordinator.mappedError(
            stripeError,
            during: .hasLinkAccount,
            apiClient: apiClient
        )
        let apiError = try XCTUnwrap(mappedError as? AppAttestationAPIError)

        XCTAssertEqual(apiError.reason, "app_not_registered")
        XCTAssertEqual(apiError.code, "link_failed_to_attest_request")
        XCTAssertEqual(apiError.operation, "has_link_account")
        XCTAssertEqual(apiError.mode, "test")
        XCTAssertEqual(apiError.requestID, "req_attestation_test")
        XCTAssertEqual(apiError.type, "invalid_request_error")
        XCTAssertEqual(
            apiError.apiMessage,
            "App identifier intentionally_invalid_app_id_for_testing (bundle ID on iOS or package name on Android) isn't registered as a trusted application in test mode for this Stripe account. Contact Stripe to register it and try again."
        )
        XCTAssertNil(apiError.apiUserMessage)
        XCTAssertNil(apiError.docURL)
        XCTAssertTrue(apiError.underlyingError is StripeError)

        let richError = apiError as StripeCryptoOnrampError
        XCTAssertEqual(richError.code, "link_failed_to_attest_request")
        XCTAssertEqual(richError.userMessage, apiError.userMessage)
        XCTAssertEqual(richError.developerMessage, apiError.developerMessage)

        XCTAssertEqual(apiError.errorDescription, apiError.userMessage)
        XCTAssertEqual(apiError.debugDescription, apiError.developerMessage)
        XCTAssertTrue(apiError.developerMessage.contains("App attestation failed: this app is not registered as a trusted application."))
        XCTAssertTrue(apiError.developerMessage.contains("reason: app_not_registered"))
        XCTAssertTrue(apiError.developerMessage.contains("request_id: req_attestation_test"))
    }

    func testMappedErrorUsesSafeUserMessageForUncategorizedAPIError() throws {
        let stripeError = StripeError.apiError(StripeAPIError(
            type: .invalidRequestError,
            code: "unexpected_backend_error",
            message: "Raw backend message that should not be shown to app users.",
            param: nil
        ))
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let mappedError = CryptoOnrampCoordinator.mappedError(
            stripeError,
            during: .hasLinkAccount,
            apiClient: apiClient
        )
        let apiError = try XCTUnwrap(mappedError as? UncategorizedAPIError)

        XCTAssertEqual(apiError.code, "unexpected_backend_error")
        XCTAssertEqual(apiError.apiMessage, "Raw backend message that should not be shown to app users.")
        XCTAssertEqual(apiError.userMessage, NSError.stp_unexpectedErrorMessage())
        XCTAssertNotEqual(apiError.userMessage, apiError.apiMessage)

        let richError = apiError as StripeCryptoOnrampError
        XCTAssertEqual(richError.userMessage, NSError.stp_unexpectedErrorMessage())
        XCTAssertTrue(richError.developerMessage.contains("Raw backend message that should not be shown to app users."))
    }

    func testAPIErrorCodeFallsBackWhenBackendCodeIsUnavailable() {
        let context = APIErrorContext(
            reason: nil,
            operation: CryptoOnrampOperation.hasLinkAccount.rawValue,
            appIdentifier: nil,
            mode: nil,
            sdkVersion: STPAPIClient.STPSDKVersion,
            apiErrorCode: nil,
            apiErrorType: nil,
            apiErrorMessage: nil,
            apiUserMessage: nil,
            docURL: nil,
            underlyingError: NSError(domain: "test", code: 0)
        )

        XCTAssertEqual(AppAttestationAPIError(context: context).code, "link_failed_to_attest_request")
        XCTAssertEqual(UncategorizedAPIError(context: context).code, "uncategorized_api_error")
    }
}

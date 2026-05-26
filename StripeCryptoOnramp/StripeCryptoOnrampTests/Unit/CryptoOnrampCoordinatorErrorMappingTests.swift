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
        let coordinatorError = try XCTUnwrap(mappedError as? CryptoOnrampCoordinator.Error)

        guard case .appAttestationFailed(let apiError) = coordinatorError else {
            return XCTFail("Expected appAttestationFailed, got \(coordinatorError).")
        }

        XCTAssertEqual(apiError.reason, "app_not_registered")
        XCTAssertEqual(apiError.context.reason, "app_not_registered")
        XCTAssertEqual(apiError.operation, "has_link_account")
        XCTAssertEqual(apiError.mode, "test")
        XCTAssertEqual(apiError.requestID, "req_attestation_test")
        XCTAssertEqual(apiError.apiErrorCode, "link_failed_to_attest_request")
        XCTAssertEqual(apiError.apiErrorType, "invalid_request_error")
        XCTAssertEqual(
            apiError.apiErrorMessage,
            "App identifier intentionally_invalid_app_id_for_testing (bundle ID on iOS or package name on Android) isn't registered as a trusted application in test mode for this Stripe account. Contact Stripe to register it and try again."
        )
        XCTAssertNil(apiError.apiUserMessage)
        XCTAssertNil(apiError.docURL)
        XCTAssertTrue(apiError.underlyingError is StripeError)

        XCTAssertEqual(coordinatorError.reason, apiError.reason)
        XCTAssertEqual(coordinatorError.operation, apiError.operation)
        XCTAssertEqual(coordinatorError.mode, apiError.mode)
        XCTAssertEqual(coordinatorError.requestID, apiError.requestID)
        XCTAssertEqual(coordinatorError.apiErrorCode, apiError.apiErrorCode)
        XCTAssertEqual(coordinatorError.apiErrorType, apiError.apiErrorType)
        XCTAssertEqual(coordinatorError.apiErrorMessage, apiError.apiErrorMessage)

        XCTAssertEqual(coordinatorError.errorDescription, coordinatorError.userFacingMessage)
        XCTAssertEqual(coordinatorError.debugDescription, coordinatorError.developerDescription)
        XCTAssertTrue(coordinatorError.developerDescription.contains("App attestation failed: this app is not registered as a trusted application."))
        XCTAssertTrue(coordinatorError.developerDescription.contains("reason: app_not_registered"))
        XCTAssertTrue(coordinatorError.developerDescription.contains("request_id: req_attestation_test"))
    }
}

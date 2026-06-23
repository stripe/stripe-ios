//
//  CryptoOnrampCoordinatorErrorMappingTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 5/26/26.
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
@testable @_spi(STP) import StripePaymentSheet
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

        let appIdentifier = try XCTUnwrap(Bundle.main.bundleIdentifier)
        XCTAssertEqual(apiError.developerMessage, """
        App attestation failed: this app is not registered as a trusted application.

        Request Context:
          operation: has_link_account
          app_id: \(appIdentifier)
          mode: test
          reason: app_not_registered
          request_id: req_attestation_test
          type: invalid_request_error

        Code: link_failed_to_attest_request

        Next step: Register this app's bundle ID or package name as a trusted application with Stripe, then retry the Onramp flow.
        SDK: stripe-ios@\(STPAPIClient.STPSDKVersion)
        """)
    }

    func testMappedErrorMapsMissingAppAttestationIntegrationErrorToRichAttestationError() throws {
        let apiClient = STPAPIClient(publishableKey: "pk_live_123")
        let additionalSDKVersions = [
            SDKVersion(name: "stripe-react-native", version: "1.2.3"),
        ]

        let mappedError = CryptoOnrampCoordinator.mappedError(
            LinkController.IntegrationError.missingAppAttestation,
            during: .createSession,
            apiClient: apiClient,
            additionalSDKVersions: additionalSDKVersions
        )
        let attestationError = try XCTUnwrap(mappedError as? AppAttestationUnavailableError)

        XCTAssertFalse(mappedError is StripeCryptoOnrampAPIError)
        XCTAssertEqual(attestationError.code, "app_attestation_unavailable")
        XCTAssertNil(attestationError.docURL)
        XCTAssertTrue(attestationError.underlyingError is LinkController.IntegrationError)
        XCTAssertEqual(attestationError.userMessage, "This app couldn't be verified. Contact the app developer for help.")
        XCTAssertEqual(attestationError.errorDescription, attestationError.userMessage)
        XCTAssertEqual(attestationError.debugDescription, attestationError.developerMessage)

        let richError = attestationError as StripeCryptoOnrampError
        XCTAssertEqual(richError.code, "app_attestation_unavailable")
        XCTAssertEqual(richError.userMessage, attestationError.userMessage)
        XCTAssertEqual(richError.developerMessage, attestationError.developerMessage)

        let appIdentifier = try XCTUnwrap(Bundle.main.bundleIdentifier)
        XCTAssertEqual(attestationError.developerMessage, """
        App attestation unavailable: this app isn't configured to use Stripe Crypto Onramp.

        This usually means app attestation isn't enabled for this Stripe account, or this app isn't registered as a trusted application. Use your iOS bundle ID and contact Stripe to enable app attestation or register the app for this account.

        Request Context:
          operation: configure
          app_id: \(appIdentifier)
          mode: live

        Code: app_attestation_unavailable

        Next step: Confirm app attestation is enabled for this Stripe account and that the app identifier is registered as trusted, then call configure again.
        SDK: stripe-ios@\(STPAPIClient.STPSDKVersion), stripe-react-native@1.2.3
        """)
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
            apiErrorCode: nil,
            apiErrorType: nil,
            apiErrorMessage: nil,
            apiUserMessage: nil,
            docURL: nil,
            underlyingError: NSError(domain: "test", code: 0)
        )
        let diagnosticContext = DiagnosticContext(
            operation: CryptoOnrampOperation.hasLinkAccount.rawValue,
            appPackageName: nil,
            mode: nil
        )

        XCTAssertEqual(
            AppAttestationAPIError(
                context: context,
                diagnosticContext: diagnosticContext
            ).code,
            "link_failed_to_attest_request"
        )
        XCTAssertEqual(
            UncategorizedAPIError(
                context: context,
                diagnosticContext: diagnosticContext
            ).code,
            "uncategorized_api_error"
        )
    }

    func testRendererAppendsFooterMetadata() {
        let developerMessage = StripeCryptoOnrampErrorRenderer.render(
            developerBody: "Developer body.",
            code: "test_code",
            nextStep: "Fix the integration.",
            docURL: URL(string: "https://stripe.com/docs/test")!
        )

        XCTAssertEqual(developerMessage, """
        Developer body.

        Code: test_code

        Next step: Fix the integration.
        Docs: https://stripe.com/docs/test
        SDK: stripe-ios@\(STPAPIClient.STPSDKVersion)
        """)
    }

    func testMappedErrorUsesAdditionalSDKVersionsInDeveloperMessage() throws {
        let stripeError = StripeError.apiError(StripeAPIError(
            type: .invalidRequestError,
            code: "link_failed_to_attest_request",
            message: nil,
            param: nil
        ))
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")
        let additionalSDKVersions = [
            SDKVersion(name: "stripe-react-native", version: "1.2.3"),
        ]

        let mappedError = CryptoOnrampCoordinator.mappedError(
            stripeError,
            during: .hasLinkAccount,
            apiClient: apiClient,
            additionalSDKVersions: additionalSDKVersions
        )
        let apiError = try XCTUnwrap(mappedError as? AppAttestationAPIError)

        XCTAssertTrue(apiError.developerMessage.contains("SDK: stripe-ios@\(STPAPIClient.STPSDKVersion), stripe-react-native@1.2.3"))
    }
}

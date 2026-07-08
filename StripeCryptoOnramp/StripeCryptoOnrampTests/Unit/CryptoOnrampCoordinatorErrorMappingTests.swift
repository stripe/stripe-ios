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

    func testMappedErrorMapsInvalidWalletOwnershipSignatureError() throws {
        let apiError = try assertMapsWalletOwnershipError(
            code: "crypto_onramp_invalid_wallet_ownership_signature",
            message: "The submitted signature does not prove ownership of the registered wallet.",
            expectedType: InvalidWalletOwnershipSignatureError.self,
            expectedUserMessage: "We couldn't verify ownership of this wallet. Please try again."
        )

        XCTAssertTrue(apiError.developerMessage.contains("The submitted signature does not prove ownership of the registered wallet."))
        XCTAssertTrue(apiError.developerMessage.contains("Code: crypto_onramp_invalid_wallet_ownership_signature"))
        XCTAssertTrue(apiError.developerMessage.contains("Next step: Sign the exact challenge message with the registered wallet address"))
    }

    func testMappedErrorMapsWalletOwnershipChallengeExpiredError() throws {
        let apiError = try assertMapsWalletOwnershipError(
            code: "crypto_onramp_wallet_ownership_challenge_expired",
            message: "The wallet ownership challenge has expired.",
            expectedType: WalletOwnershipChallengeExpiredError.self,
            expectedUserMessage: "This wallet verification request expired. Please try again."
        )

        XCTAssertTrue(apiError.developerMessage.contains("The wallet ownership challenge has expired."))
        XCTAssertTrue(apiError.developerMessage.contains("Code: crypto_onramp_wallet_ownership_challenge_expired"))
        XCTAssertTrue(apiError.developerMessage.contains("Next step: Request a new wallet ownership challenge"))
    }

    func testMappedErrorMapsInvalidWalletOwnershipChallengeError() throws {
        let apiError = try assertMapsWalletOwnershipError(
            code: "crypto_onramp_invalid_wallet_ownership_challenge",
            message: "The wallet ownership challenge is invalid.",
            expectedType: InvalidWalletOwnershipChallengeError.self,
            expectedUserMessage: "This wallet verification request is no longer valid. Please try again."
        )

        XCTAssertTrue(apiError.developerMessage.contains("The wallet ownership challenge is invalid."))
        XCTAssertTrue(apiError.developerMessage.contains("Code: crypto_onramp_invalid_wallet_ownership_challenge"))
        XCTAssertTrue(apiError.developerMessage.contains("Next step: Request a new challenge for the registered wallet"))
    }

    func testMappedErrorMapsWalletNotFoundError() throws {
        let apiError = try assertMapsWalletOwnershipError(
            code: "crypto_onramp_wallet_not_found",
            message: "The wallet was not found for the authenticated consumer.",
            expectedType: WalletNotFoundError.self,
            expectedUserMessage: "This wallet couldn't be found. Please choose or add a wallet and try again."
        )

        XCTAssertTrue(apiError.developerMessage.contains("The wallet was not found for the authenticated consumer."))
        XCTAssertTrue(apiError.developerMessage.contains("Code: crypto_onramp_wallet_not_found"))
        XCTAssertTrue(apiError.developerMessage.contains("Next step: Use a wallet registered to the authenticated consumer"))
    }

    func testMappedErrorMapsUnsupportedNetworkError() throws {
        let apiError = try assertMapsWalletOwnershipError(
            code: "crypto_onramp_unsupported_network",
            message: "The wallet network is not supported for this operation.",
            expectedType: UnsupportedNetworkError.self,
            expectedUserMessage: "This wallet network isn't supported. Please choose a different network."
        )

        XCTAssertTrue(apiError.developerMessage.contains("The wallet network is not supported for this operation."))
        XCTAssertTrue(apiError.developerMessage.contains("Code: crypto_onramp_unsupported_network"))
        XCTAssertTrue(apiError.developerMessage.contains("Next step: Use a network supported by Crypto Onramp"))
    }

    func testAPIErrorCodeFallsBackWhenBackendCodeIsUnavailable() {
        let apiErrorContext = APIErrorContext(
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
                apiErrorContext: apiErrorContext,
                diagnosticContext: diagnosticContext
            ).code,
            "link_failed_to_attest_request"
        )
        XCTAssertEqual(
            UncategorizedAPIError(
                apiErrorContext: apiErrorContext,
                diagnosticContext: diagnosticContext
            ).code,
            "uncategorized_api_error"
        )
        XCTAssertEqual(
            InvalidWalletOwnershipSignatureError(
                apiErrorContext: apiErrorContext,
                diagnosticContext: diagnosticContext
            ).code,
            "crypto_onramp_invalid_wallet_ownership_signature"
        )
        XCTAssertEqual(
            WalletOwnershipChallengeExpiredError(
                apiErrorContext: apiErrorContext,
                diagnosticContext: diagnosticContext
            ).code,
            "crypto_onramp_wallet_ownership_challenge_expired"
        )
        XCTAssertEqual(
            InvalidWalletOwnershipChallengeError(
                apiErrorContext: apiErrorContext,
                diagnosticContext: diagnosticContext
            ).code,
            "crypto_onramp_invalid_wallet_ownership_challenge"
        )
        XCTAssertEqual(
            WalletNotFoundError(
                apiErrorContext: apiErrorContext,
                diagnosticContext: diagnosticContext
            ).code,
            "crypto_onramp_wallet_not_found"
        )
        XCTAssertEqual(
            UnsupportedNetworkError(
                apiErrorContext: apiErrorContext,
                diagnosticContext: diagnosticContext
            ).code,
            "crypto_onramp_unsupported_network"
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

    @discardableResult
    private func assertMapsWalletOwnershipError<T: StripeCryptoOnrampAPIError>(
        code: String,
        message: String,
        expectedType: T.Type,
        expectedUserMessage: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> T {
        let stripeError = StripeError.apiError(StripeAPIError(
            type: .invalidRequestError,
            code: code,
            message: message,
            param: nil
        ))
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let mappedError = CryptoOnrampCoordinator.mappedError(
            stripeError,
            during: .submitWalletOwnershipSignature,
            apiClient: apiClient
        )
        let apiError = try XCTUnwrap(mappedError as? T, file: file, line: line)

        XCTAssertEqual(apiError.code, code, file: file, line: line)
        XCTAssertEqual(apiError.apiMessage, message, file: file, line: line)
        XCTAssertEqual(apiError.type, "invalid_request_error", file: file, line: line)
        XCTAssertEqual(apiError.userMessage, expectedUserMessage, file: file, line: line)
        XCTAssertEqual(apiError.errorDescription, apiError.userMessage, file: file, line: line)
        XCTAssertEqual(apiError.debugDescription, apiError.developerMessage, file: file, line: line)
        XCTAssertTrue(apiError.underlyingError is StripeError, file: file, line: line)
        XCTAssertFalse(apiError is UncategorizedAPIError, file: file, line: line)

        let richError = apiError as StripeCryptoOnrampError
        XCTAssertEqual(richError.code, code, file: file, line: line)
        XCTAssertEqual(richError.userMessage, apiError.userMessage, file: file, line: line)
        XCTAssertEqual(richError.developerMessage, apiError.developerMessage, file: file, line: line)

        return apiError
    }
}

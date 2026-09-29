//
//  CryptoOnrampCoordinatorErrorMappingTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 5/26/26.
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class CryptoOnrampCoordinatorErrorMappingTests: XCTestCase {

    func testCheckoutErrorPreservesLastPaymentErrorDetails() throws {
        // Given a PaymentIntent declined after authentication and a generic payment handler error
        let paymentIntent = try XCTUnwrap(STPPaymentIntent.decodedObject(fromAPIResponse: [
            "id": "pi_123",
            "client_secret": "pi_123_secret_123",
            "amount": 2345,
            "currency": "usd",
            "status": "requires_payment_method",
            "livemode": false,
            "created": 1_652_736_692.0,
            "payment_method_types": ["card"],
            "last_payment_error": [
                "code": "card_declined",
                "decline_code": "do_not_honor",
                "message": "Your card was declined.",
                "type": "card_error",
            ],
        ]))
        let originalError = NSError(
            domain: STPError.STPPaymentHandlerErrorDomain,
            code: 1,
            userInfo: [
                STPError.errorMessageKey: "There was an error confirming the Intent.",
                NSLocalizedDescriptionKey: "The payment handler selected this localized message.",
                STPError.stripeRequestIDKey: "req_123",
            ]
        )

        // When Crypto Onramp maps the failed next action
        let checkoutError = CryptoOnrampCoordinator.checkoutError(
            originalError,
            paymentIntent: paymentIntent
        ) as NSError

        // Then the original error metadata and structured PaymentIntent error details are preserved
        XCTAssertEqual(checkoutError.domain, originalError.domain)
        XCTAssertEqual(checkoutError.code, originalError.code)
        XCTAssertEqual(checkoutError.userInfo[STPError.stripeRequestIDKey] as? String, "req_123")
        XCTAssertEqual(checkoutError.userInfo[STPError.errorMessageKey] as? String, "Your card was declined.")
        XCTAssertEqual(checkoutError.localizedDescription, "The payment handler selected this localized message.")
        XCTAssertEqual(checkoutError.userInfo[STPError.stripeErrorCodeKey] as? String, "card_declined")
        XCTAssertEqual(checkoutError.userInfo[STPError.stripeDeclineCodeKey] as? String, "do_not_honor")
        XCTAssertEqual(checkoutError.userInfo[STPError.stripeErrorTypeKey] as? String, "card_error")
    }

    func testCheckoutErrorDoesNotExposeNonCardMessageAsLocalizedDescription() throws {
        // Given a non-card PaymentIntent error with developer-facing API details
        let paymentIntent = try XCTUnwrap(STPPaymentIntent.decodedObject(fromAPIResponse: [
            "id": "pi_123",
            "client_secret": "pi_123_secret_123",
            "amount": 2345,
            "currency": "usd",
            "status": "requires_payment_method",
            "livemode": false,
            "created": 1_652_736_692.0,
            "payment_method_types": ["card"],
            "last_payment_error": [
                "code": "parameter_invalid_integer",
                "message": "Developer-facing API details.",
                "type": "invalid_request_error",
            ],
        ]))
        let originalError = NSError(
            domain: STPError.STPPaymentHandlerErrorDomain,
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "We couldn't complete your payment.",
            ]
        )

        // When Crypto Onramp maps the failed next action
        let checkoutError = CryptoOnrampCoordinator.checkoutError(
            originalError,
            paymentIntent: paymentIntent
        ) as NSError

        // Then the API message is preserved as metadata without replacing user-safe copy
        XCTAssertEqual(
            checkoutError.userInfo[STPError.errorMessageKey] as? String,
            "Developer-facing API details."
        )
        XCTAssertEqual(checkoutError.localizedDescription, "We couldn't complete your payment.")
        XCTAssertEqual(
            checkoutError.userInfo[STPError.stripeErrorTypeKey] as? String,
            "invalid_request_error"
        )
    }

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
        let apiError = try XCTUnwrap(mappedError as? AppAttestationError)

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

    func testMappedErrorUsesSafeUserMessageForUncategorizedError() throws {
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
        let apiError = try XCTUnwrap(mappedError as? UncategorizedError)

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
            message: "The challenge does not exist, belongs to a different authenticated consumer, was already consumed, or is otherwise invalid.",
            expectedType: InvalidWalletOwnershipChallengeError.self,
            expectedUserMessage: "This wallet verification request is invalid. Please try again."
        )

        XCTAssertTrue(apiError.developerMessage.contains("The challenge does not exist, belongs to a different authenticated consumer, was already consumed, or is otherwise invalid."))
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
            AppAttestationError(
                apiErrorContext: apiErrorContext,
                diagnosticContext: diagnosticContext
            ).code,
            "link_failed_to_attest_request"
        )
        XCTAssertEqual(
            UncategorizedError(
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
        let apiError = try XCTUnwrap(mappedError as? AppAttestationError)

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
        XCTAssertFalse(apiError is UncategorizedError, file: file, line: line)

        let richError = apiError as StripeCryptoOnrampError
        XCTAssertEqual(richError.code, code, file: file, line: line)
        XCTAssertEqual(richError.userMessage, apiError.userMessage, file: file, line: line)
        XCTAssertEqual(richError.developerMessage, apiError.developerMessage, file: file, line: line)

        return apiError
    }
}

//
//  UserFacingErrorTests.swift
//  StripePaymentSheetTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@testable import StripePaymentSheet
import XCTest

final class UserFacingErrorTests: XCTestCase {
    private let liveAPIClient = STPAPIClient(publishableKey: "pk_live_example")
    private let testAPIClient = STPAPIClient(publishableKey: "pk_test_example")

    func testPresentationUsesCurrentAPIClientMode() {
        let apiClient = STPAPIClient(publishableKey: "pk_live_example")
        let error = PaymentSheetError.unknown(debugDescription: "Developer details")

        XCTAssertEqual(error.userFacingDescription(using: apiClient), generic(String((error as NSError).code)))

        apiClient.publishableKey = "pk_test_example"
        XCTAssertEqual(error.userFacingDescription(using: apiClient), error.nonGenericDescription)

        apiClient.publishableKey = "pk_live_example"
        XCTAssertEqual(error.userFacingDescription(using: apiClient), generic(String((error as NSError).code)))
    }

    func testLiveLegacyAPIErrorWithoutIntentUsesRequestID() {
        let error = apiError(requestID: "req_123")

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), generic("req_123"))
        XCTAssertEqual(error.userInfo[STPError.errorMessageKey] as? String, "Verbose server details")
        XCTAssertNil(error.userInfo["payment_intent"])
    }

    func testDecodedLegacyAPIErrorUsesResponseRequestID() throws {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: URL(string: "https://api.stripe.com/v1/payment_intents")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: ["Request-Id": "req_response"]
        ))
        let error = NSError.stp_error(
            errorType: "invalid_request_error",
            stripeErrorCode: nil,
            stripeErrorMessage: "This Connect account cannot make live charges.",
            errorParam: nil,
            declineCode: nil,
            intent: nil,
            httpResponse: response
        )

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), generic("req_response"))
        XCTAssertEqual(error.userFacingDescription(using: testAPIClient), error.nonGenericDescription)
    }

    func testTestModeKeepsExistingDescriptions() {
        let errors: [Error] = [
            apiError(requestID: "req_123"),
            PaymentSheetError.unknown(debugDescription: "Verbose SDK details"),
            NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2, userInfo: [
                NSUnderlyingErrorKey: apiError(requestID: "req_123"),
            ]),
        ]

        for error in errors {
            XCTAssertEqual(error.userFacingDescription(using: testAPIClient), error.nonGenericDescription)
        }
    }

    func testLiveModernAPIErrorUsesRequestID() throws {
        let error = try modernAPIError(type: "invalid_request_error", requestID: "req_modern")

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), generic("req_modern"))
        XCTAssertEqual(error.userFacingDescription(using: testAPIClient), error.nonGenericDescription)
    }

    func testLiveWrappedAPIErrorUsesUnderlyingRequestID() {
        let underlying = apiError(requestID: "req_underlying")
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Localized wrapper details",
            NSUnderlyingErrorKey: underlying,
        ])

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), "Localized wrapper details (req_underlying)")
    }

    func testLiveWrappedModernAPIErrorUsesRequestID() throws {
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2, userInfo: [
            NSUnderlyingErrorKey: try modernAPIError(type: "api_error", requestID: "req_modern"),
        ])

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), error.localizedDescription + " (req_modern)")
    }

    func testLiveCheckoutWrappedAPIErrorUsesUnderlyingRequestID() {
        let error = CheckoutError.apiError(message: "Checkout description", underlyingError: apiError(requestID: "req_checkout"))

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), "Checkout description (req_checkout)")
        XCTAssertEqual(error.userFacingDescription(using: testAPIClient), "Checkout description")
    }

    func testLiveCheckoutWrappedCardErrorKeepsActionableMessage() {
        let error = CheckoutError.apiError(message: "Your card was declined.", underlyingError: apiError(type: "card_error", requestID: "req_card", message: "Your card was declined."))

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), "Your card was declined. (req_card)")
    }

    func testLiveMissingRequestIDUsesErrorCode() {
        XCTAssertEqual(apiError(code: "account_invalid").userFacingDescription(using: liveAPIClient), generic("account_invalid"))
        XCTAssertEqual(apiError(requestID: "", code: "account_invalid").userFacingDescription(using: liveAPIClient), generic("account_invalid"))
    }

    func testLiveMissingRequestIDAndCodeUsesNumericCode() {
        let error = apiError()
        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), generic(String(error.code)))
    }

    func testLivePreservesExistingLocalizedDescription() {
        let error = NSError(domain: STPError.stripeDomain, code: 50, userInfo: [
            NSLocalizedDescriptionKey: "Verbose server details",
        ])

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), "Verbose server details (50)")
    }

    func testLiveSDKErrorUsesLocalizedDescriptionAndNumericCode() {
        let errors: [Error] = [
            PaymentSheetError.unknown(debugDescription: "secret server details"),
            PaymentSheetError.deferredIntentValidationFailed(message: "secret server details"),
            CheckoutError.apiError(message: "secret server details"),
            StripeError.invalidRequest,
        ]
        for error in errors {
            XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), error.localizedDescription + " (\((error as NSError).code))")
        }
    }

    func testLiveSDKErrorWithoutAssociatedValuesDoesNotExposeDebugDescription() {
        let error = PaymentSheetError.missingClientSecret

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), generic(String((error as NSError).code)))
        XCTAssertFalse(error.userFacingDescription(using: liveAPIClient).contains(error.debugDescription))
        XCTAssertEqual(error.userFacingDescription(using: testAPIClient), error.debugDescription)
    }

    func testLiveCardErrorKeepsActionableMessage() throws {
        let error = apiError(type: "card_error", requestID: "req_card", message: "Your card was declined.")
        let wrapped = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Your card was declined.",
            NSUnderlyingErrorKey: error,
        ])
        let modern = try modernAPIError(type: "card_error", requestID: "req_card", message: "Your card was declined.")

        for error in [error as Error, wrapped, modern] {
            XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), "Your card was declined. (req_card)")
        }
    }

    func testLivePaymentHandlerCardMessageStaysLocalized() {
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain,
                            code: STPPaymentHandlerErrorCode.paymentErrorCode.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "Your card was declined."])

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), "Your card was declined. (\(error.code))")
    }

    @MainActor
    func testLivePaymentHandlerPreservesAuthenticationMessages() {
        // Given actionable authentication errors created by PaymentHandler
        for code: STPPaymentHandlerErrorCode in [.notAuthenticatedErrorCode, .timedOutErrorCode] {
            let error = STPPaymentHandler()._error(for: code)

            // Then live mode uses the existing localized description without replacing it
            XCTAssertNotEqual(error.localizedDescription, NSError.stp_unexpectedErrorMessage())
            XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), error.localizedDescription + " (\(error.code))")
            XCTAssertEqual(error.userFacingDescription(using: testAPIClient), error.nonGenericDescription)
        }
    }

    func testLiveNestedWrappersPreserveOuterDescription() {
        let merchantError = NSError(domain: "merchant", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "This item is out of stock.",
        ])
        let handlerError = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2, userInfo: [
            NSUnderlyingErrorKey: merchantError,
        ])
        let error = CheckoutError.apiError(message: "Wrapper details", underlyingError: handlerError)

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), "Wrapper details (1)")
        XCTAssertEqual(error.userFacingDescription(using: testAPIClient), "Wrapper details")
    }

    func testLivePaymentHandlerWithoutLocalizedMessageUsesCode() {
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain,
                            code: STPPaymentHandlerErrorCode.paymentErrorCode.rawValue,
                            userInfo: [STPError.errorMessageKey: "Verbose confirmation details"])

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), error.localizedDescription + " (\(error.code))")
    }

    @MainActor
    func testLivePaymentHandlerDebugMessageUsesCode() {
        let error = STPPaymentHandler()._error(for: .missingReturnURL)

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), generic(String(error.code)))
    }

    func testMerchantErrorAndSDKValidationRemainActionable() {
        let error = NSError(domain: "merchant", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "This item is out of stock.",
        ])

        XCTAssertEqual(error.userFacingDescription(using: liveAPIClient), error.localizedDescription + " (\(error.code))")
        let validationError = PaymentSheetError.confirmingWithInvalidPaymentOption
        XCTAssertEqual(validationError.userFacingDescription(using: liveAPIClient),
                       validationError.localizedDescription + " (\((validationError as NSError).code))")
    }

    func testLinkVerificationKeepsKnownUserMessageAndAddsRequestIDToOtherErrors() {
        let known = apiError(code: LinkUtils.ConsumerErrorCode.consumerVerificationCodeInvalid.rawValue)
        let unknown = apiError(requestID: "req_link")

        XCTAssertEqual(LinkUtils.getLocalizedErrorMessage(from: known, apiClient: liveAPIClient),
                       LinkUtils.ConsumerErrorCode.consumerVerificationCodeInvalid.localizedDescription)
        XCTAssertEqual(LinkUtils.getLocalizedErrorMessage(from: unknown, apiClient: liveAPIClient), generic("req_link"))
        XCTAssertEqual(LinkUtils.getLocalizedErrorMessage(from: unknown, apiClient: testAPIClient), unknown.localizedDescription)
    }

    private func apiError(
        type: String = "invalid_request_error",
        requestID: String? = nil,
        code: String? = nil,
        message: String = "Verbose server details"
    ) -> NSError {
        let response = HTTPURLResponse(
            url: URL(string: "https://api.stripe.com/v1/payment_intents")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: requestID.map { ["Request-Id": $0] }
        )
        return NSError.stp_error(
            errorType: type,
            stripeErrorCode: code,
            stripeErrorMessage: message,
            errorParam: nil,
            declineCode: nil,
            intent: nil,
            httpResponse: response
        )
    }

    private func modernAPIError(type: String, requestID: String, message: String = "Verbose server details") throws -> StripeError {
        let data = try JSONSerialization.data(withJSONObject: ["type": type, "message": message])
        var error = try JSONDecoder().decode(StripeAPIError.self, from: data)
        error.requestID = requestID
        return .apiError(error)
    }

    private func generic(_ identifier: String) -> String {
        NSError.stp_unexpectedErrorMessage() + " (\(identifier))"
    }
}

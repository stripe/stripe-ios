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
    func testLiveLegacyAPIErrorWithoutIntentUsesRequestID() {
        let error = apiError(requestID: "req_123")

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic("req_123"))
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

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic("req_response"))
        XCTAssertEqual(error.userFacingDescription(isTestmode: true), error.nonGenericDescription)
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
            XCTAssertEqual(error.userFacingDescription(isTestmode: true), error.nonGenericDescription)
        }
    }

    func testLiveModernAPIErrorUsesRequestID() throws {
        let error = try modernAPIError(type: "invalid_request_error", requestID: "req_modern")

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic("req_modern"))
        XCTAssertEqual(error.userFacingDescription(isTestmode: true), error.nonGenericDescription)
    }

    func testLiveWrappedAPIErrorUsesUnderlyingRequestID() {
        let underlying = apiError(requestID: "req_underlying")
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Localized wrapper details",
            NSUnderlyingErrorKey: underlying,
        ])

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic("req_underlying"))
    }

    func testLiveWrappedModernAPIErrorUsesRequestID() throws {
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2, userInfo: [
            NSUnderlyingErrorKey: try modernAPIError(type: "api_error", requestID: "req_modern"),
        ])

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic("req_modern"))
    }

    func testLiveCheckoutWrappedAPIErrorUsesUnderlyingRequestID() {
        let error = CheckoutError.apiError(message: "Verbose server details", underlyingError: apiError(requestID: "req_checkout"))

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic("req_checkout"))
        XCTAssertEqual(error.userFacingDescription(isTestmode: true), "Verbose server details")
    }

    func testLiveCheckoutWrappedCardErrorKeepsActionableMessage() {
        let error = CheckoutError.apiError(message: "Your card was declined.", underlyingError: apiError(type: "card_error", message: "Your card was declined."))

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), "Your card was declined.")
    }

    func testLiveMissingRequestIDUsesErrorCode() {
        XCTAssertEqual(apiError(code: "account_invalid").userFacingDescription(isTestmode: false), generic("account_invalid"))
        XCTAssertEqual(apiError(requestID: "", code: "account_invalid").userFacingDescription(isTestmode: false), generic("account_invalid"))
    }

    func testLiveMissingRequestIDAndCodeUsesType() {
        XCTAssertEqual(apiError().userFacingDescription(isTestmode: false), generic("invalid_request_error"))
    }

    func testLiveMissingMetadataUsesNumericCode() {
        let error = NSError(domain: STPError.stripeDomain, code: 50, userInfo: [
            NSLocalizedDescriptionKey: "Verbose server details",
        ])

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic("50"))
    }

    func testLiveSDKErrorUsesCaseWithoutAssociatedDebugDetails() {
        let errors: [Error] = [
            PaymentSheetError.unknown(debugDescription: "secret server details"),
            PaymentSheetError.deferredIntentValidationFailed(message: "secret server details"),
            CheckoutError.apiError(message: "secret server details"),
            StripeError.invalidRequest,
        ]
        let codes = ["unknown", "deferredIntentValidationFailed", "apiError", "invalidRequest"]

        for (error, code) in zip(errors, codes) {
            XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic(code))
        }
    }

    func testLiveSDKErrorWithoutAssociatedValuesDoesNotExposeDebugDescription() {
        let error = PaymentSheetError.missingClientSecret

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic(String((error as NSError).code)))
        XCTAssertFalse(error.userFacingDescription(isTestmode: false).contains(error.debugDescription))
        XCTAssertEqual(error.userFacingDescription(isTestmode: true), error.debugDescription)
    }

    func testLiveCardErrorKeepsActionableMessage() throws {
        let error = apiError(type: "card_error", requestID: "req_card", message: "Your card was declined.")
        let wrapped = NSError(domain: STPError.STPPaymentHandlerErrorDomain, code: 2, userInfo: [
            NSUnderlyingErrorKey: error,
        ])
        let modern = try modernAPIError(type: "card_error", requestID: "req_card", message: "Your card was declined.")

        for error in [error as Error, wrapped, modern] {
            XCTAssertEqual(error.userFacingDescription(isTestmode: false), "Your card was declined.")
        }
    }

    func testLivePaymentHandlerCardMessageStaysLocalized() {
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain,
                            code: STPPaymentHandlerErrorCode.paymentErrorCode.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "Your card was declined."])

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), "Your card was declined.")
    }

    func testLivePaymentHandlerWithoutLocalizedMessageUsesCode() {
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain,
                            code: STPPaymentHandlerErrorCode.paymentErrorCode.rawValue,
                            userInfo: [STPError.errorMessageKey: "Verbose confirmation details"])

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic(String(error.code)))
    }

    func testLivePaymentHandlerDebugMessageUsesCode() {
        let error = NSError(domain: STPError.STPPaymentHandlerErrorDomain,
                            code: STPPaymentHandlerErrorCode.missingReturnURL.rawValue,
                            userInfo: [STPError.errorMessageKey: "Provide a return URL in your integration."])

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), generic(String(error.code)))
    }

    func testMerchantErrorAndSDKValidationRemainActionable() {
        let error = NSError(domain: "merchant", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "This item is out of stock.",
        ])

        XCTAssertEqual(error.userFacingDescription(isTestmode: false), error.localizedDescription)
        XCTAssertEqual(PaymentSheetError.confirmingWithInvalidPaymentOption.userFacingDescription(isTestmode: false),
                       PaymentSheetError.confirmingWithInvalidPaymentOption.localizedDescription)
    }

    func testLinkVerificationKeepsKnownUserMessageAndSanitizesUnknownErrors() {
        let known = apiError(code: LinkUtils.ConsumerErrorCode.consumerVerificationCodeInvalid.rawValue)
        let unknown = apiError(requestID: "req_link")

        XCTAssertEqual(LinkUtils.getLocalizedErrorMessage(from: known, isTestmode: false),
                       LinkUtils.ConsumerErrorCode.consumerVerificationCodeInvalid.localizedDescription)
        XCTAssertEqual(LinkUtils.getLocalizedErrorMessage(from: unknown, isTestmode: false), generic("req_link"))
        XCTAssertEqual(LinkUtils.getLocalizedErrorMessage(from: unknown, isTestmode: true), unknown.localizedDescription)
    }

    private func apiError(
        type: String = "invalid_request_error",
        requestID: String? = nil,
        code: String? = nil,
        message: String = "Verbose server details"
    ) -> NSError {
        var userInfo: [String: Any] = [
            STPError.stripeErrorTypeKey: type,
            STPError.errorMessageKey: message,
            NSLocalizedDescriptionKey: message,
        ]
        userInfo[STPError.stripeRequestIDKey] = requestID
        userInfo[STPError.stripeErrorCodeKey] = code
        return NSError(domain: STPError.stripeDomain, code: 50, userInfo: userInfo)
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

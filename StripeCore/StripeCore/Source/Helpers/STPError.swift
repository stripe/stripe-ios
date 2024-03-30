//
//  STPError.swift
//  StripeCore
//
//  Created by Saikat Chakrabarti on 11/4/12.
//  Copyright © 2012 Stripe, Inc. All rights reserved.
//

import Foundation

/// Possible error code values for NSErrors with the `StripeDomain` domain.
@objc public enum STPErrorCode: Int {
    /// Trouble connecting to Stripe.
    @objc(STPConnectionError) case connectionError = 40
    /// Your request had invalid parameters.
    @objc(STPInvalidRequestError) case invalidRequestError = 50
    /// No valid publishable API key provided.
    @objc(STPAuthenticationError) case authenticationError = 51
    /// General-purpose API error.
    @objc(STPAPIError) case apiError = 60
    /// Something was wrong with the given card details.
    @objc(STPCardError) case cardError = 70
    /// The operation was cancelled.
    @objc(STPCancellationError) case cancellationError = 80
    /// The ephemeral key could not be decoded. Make sure your backend is sending
    /// the unmodified JSON of the ephemeral key to your app.
    /// https://stripe.com/docs/mobile/ios/basic#prepare-your-api
    @objc(STPEphemeralKeyDecodingError) case ephemeralKeyDecodingError = 1000
}

// MARK: - STPError

// swift-format-ignore: DontRepeatTypeInStaticProperties
/// Top-level class for Stripe error constants.
@objc public class STPError: NSObject {
    // MARK: userInfo keys
    /// All Stripe iOS errors will be under this domain.
    @objc public static let stripeDomain = "com.stripe.lib"

    // swift-format-ignore: DontRepeatTypeInStaticProperties
    /// The error domain for errors in `STPPaymentHandler`.
    @objc public static let STPPaymentHandlerErrorDomain = "STPPaymentHandlerErrorDomain"

    /// A human-readable message providing more details about the error.
    /// For card errors, these messages can be shown to your users.
    /// - seealso: https://stripe.com/docs/api/errors#errors-message
    @objc public static let errorMessageKey = "com.stripe.lib:ErrorMessageKey"
    /// An SDK-supplied "hint" that is intended to help you, the developer, fix the error.
    @objc public static let hintKey = "com.stripe.lib:hintKey"
    /// What went wrong with your STPCard (e.g., STPInvalidCVC).
    ///
    /// See below for full list).
    @objc public static let cardErrorCodeKey = "com.stripe.lib:CardErrorCodeKey"
    /// Which parameter on the STPCard had an error (e.g., "cvc").
    ///
    /// Useful for marking up the right UI element.
    @objc public static let errorParameterKey = "com.stripe.lib:ErrorParameterKey"
    /// The error code returned by the Stripe API.
    ///
    /// - seealso: https://stripe.com/docs/api#errors-code
    /// - seealso: https://stripe.com/docs/error-codes
    @objc public static let stripeErrorCodeKey = "com.stripe.lib:StripeErrorCodeKey"
    /// The error type returned by the Stripe API.
    ///
    /// - seealso: https://stripe.com/docs/api#errors-type
    @objc public static let stripeErrorTypeKey = "com.stripe.lib:StripeErrorTypeKey"
    /// If the value of `userInfo[stripeErrorCodeKey]` is `STPError.cardDeclined`,
    /// the value for this key contains the decline code.
    ///
    /// - seealso: https://stripe.com/docs/declines/codes
    @objc public static let stripeDeclineCodeKey = "com.stripe.lib:DeclineCodeKey"

    /// The Stripe API request ID, if available. Looks like `req_123`.
    @_spi(STP) public static let stripeRequestIDKey = "com.stripe.lib:StripeRequestIDKey"
}

extension NSError {
    @_spi(STP) public class Utils {
        private static let apiErrorCodeToMessage: [String: String] = [
            "incorrect_number": NSError.stp_cardErrorInvalidNumberUserMessage(),
            "invalid_number": NSError.stp_cardErrorInvalidNumberUserMessage(),
            "invalid_expiry_month": NSError.stp_cardErrorInvalidExpMonthUserMessage(),
            "invalid_expiry_year": NSError.stp_cardErrorInvalidExpYearUserMessage(),
            "invalid_cvc": NSError.stp_cardInvalidCVCUserMessage(),
            "expired_card": NSError.stp_cardErrorExpiredCardUserMessage(),
            "incorrect_cvc": NSError.stp_cardInvalidCVCUserMessage(),
            "card_declined": NSError.stp_cardErrorDeclinedUserMessage(),
            "processing_error": NSError.stp_cardErrorProcessingErrorUserMessage(),
            "invalid_owner_name": NSError.stp_invalidOwnerName,
            "invalid_bank_account_iban": NSError.stp_invalidBankAccountIban,
            "generic_decline": NSError.stp_genericDeclineErrorUserMessage(),
        ]

        private static let apiErrorCodeToCardErrorCode: [String: STPCardErrorCode] = [
            "incorrect_number": .incorrectNumber,
            "invalid_number": .invalidNumber,
            "invalid_expiry_month": .invalidExpMonth,
            "invalid_expiry_year": .invalidExpYear,
            "invalid_cvc": .invalidCVC,
            "expired_card": .expiredCard,
            "incorrect_cvc": .invalidCVC,
            "card_declined": .cardDeclined,
            "processing_error": .processingError,
            "incorrect_zip": .incorrectZip,
        ]

        private init() {}

        @_spi(STP) public static func localizedMessage(
            fromAPIErrorCode errorCode: String,
            declineCode: String? = nil
        ) -> String? {
            return
                (apiErrorCodeToMessage[errorCode]
                ?? declineCode.flatMap { apiErrorCodeToMessage[$0] })
        }

        @_spi(STP) public static func cardErrorCode(
            fromAPIErrorCode errorCode: String
        ) -> STPCardErrorCode? {
            return apiErrorCodeToCardErrorCode[errorCode]
        }
    }
}

/// NSError extensions for creating error objects from Stripe API responses.
extension NSError {
    @_spi(STP) public static func stp_error(from modernStripeError: StripeError) -> NSError? {
        switch modernStripeError {
        case .apiError(let stripeAPIError):
            return stp_error(fromStripeResponse: ["error": stripeAPIError.allResponseFields])
        case .invalidRequest:
            return NSError(
                domain: STPError.stripeDomain,
                code: STPErrorCode.invalidRequestError.rawValue,
                userInfo: nil
            )
        }
    }

    @_spi(STP) public static func stp_error(
        errorType: String?,
        stripeErrorCode: String?,
        stripeErrorMessage: String?,
        errorParam: String?,
        declineCode: Any?,
        httpResponse: HTTPURLResponse?
    ) -> NSError? {
        var code = 0

        var userInfo: [AnyHashable: Any] = [
            NSLocalizedDescriptionKey: self.stp_unexpectedErrorMessage(),
        ]
        userInfo[STPError.stripeErrorCodeKey] = stripeErrorCode ?? ""
        userInfo[STPError.stripeErrorTypeKey] = errorType ?? ""
        if let errorParam = errorParam {
            userInfo[STPError.errorParameterKey] = URLEncoder.convertToCamelCase(
                snakeCase: errorParam
            )
        }
        if let stripeErrorMessage = stripeErrorMessage {
            userInfo[STPError.errorMessageKey] = stripeErrorMessage
            userInfo[STPError.hintKey] = ServerErrorMapper.mobileErrorMessage(
                from: stripeErrorMessage,
                httpResponse: httpResponse
            )
        } else {
            userInfo[STPError.errorMessageKey] =
                "Could not interpret the error response that was returned from Stripe."
        }
        if errorType == "api_error" {
            code = STPErrorCode.apiError.rawValue
        } else {
            if errorType == "invalid_request_error" {
                switch httpResponse?.statusCode {
                case 401:
                    code = STPErrorCode.authenticationError.rawValue
                default:
                    code = STPErrorCode.invalidRequestError.rawValue
                }
            } else if errorType == "card_error" {
                code = STPErrorCode.cardError.rawValue
                // see https://stripe.com/docs/api/errors#errors-message
                userInfo[NSLocalizedDescriptionKey] = stripeErrorMessage
            } else {
                code = STPErrorCode.apiError.rawValue
            }

            if let stripeErrorCode = stripeErrorCode, !stripeErrorCode.isEmpty {
                if let cardErrorCode = Utils.cardErrorCode(fromAPIErrorCode: stripeErrorCode) {
                    if cardErrorCode == STPCardErrorCode.cardDeclined,
                        let decline_code = declineCode
                    {
                        userInfo[STPError.stripeDeclineCodeKey] = decline_code
                    }
                    userInfo[STPError.cardErrorCodeKey] = cardErrorCode.rawValue
                }

                // If the server didn't send an error message, use a local one.
                if stripeErrorMessage == nil {
                    let localizedMessage = Utils.localizedMessage(
                        fromAPIErrorCode: stripeErrorCode,
                        declineCode: declineCode as? String
                    )

                    if let localizedMessage = localizedMessage {
                        userInfo[NSLocalizedDescriptionKey] = localizedMessage
                    }
                }
            }
        }

        // Add the Stripe request id if it exists
        if let requestId = httpResponse?.value(forHTTPHeaderField: "request-id") {
            userInfo[STPError.stripeRequestIDKey] = requestId
        }

        return NSError(
            domain: STPError.stripeDomain,
            code: code,
            userInfo: userInfo as? [String: Any]
        )
    }

    @_spi(STP) public static func stp_error(
        fromStripeResponse jsonDictionary: [AnyHashable: Any]?,
        httpResponse: HTTPURLResponse?
    ) -> NSError? {
        // TODO: Refactor. A lot of this can be replaced by a lookup/decision table. Check Android implementation for cues.
        guard let dict = (jsonDictionary as NSDictionary?),
            let errorDictionary = dict["error"] as? NSDictionary
        else {
            return nil
        }
        let errorType = errorDictionary["type"] as? String
        let errorParam = errorDictionary["param"] as? String
        let stripeErrorMessage = errorDictionary["message"] as? String
        let stripeErrorCode = errorDictionary["code"] as? String
        let declineCode = errorDictionary["decline_code"]

        return stp_error(
            errorType: errorType,
            stripeErrorCode: stripeErrorCode,
            stripeErrorMessage: stripeErrorMessage,
            errorParam: errorParam,
            declineCode: declineCode,
            httpResponse: httpResponse
        )
    }

    /// Creates an NSError object from a given Stripe API json response.
    /// - Parameter jsonDictionary: The root dictionary from the JSON response.
    /// - Returns: An NSError object with the error information from the JSON response,
    /// or nil if there was no error information included in the JSON dictionary.
    @objc(stp_errorFromStripeResponse:) public static func stp_error(
        fromStripeResponse jsonDictionary: [AnyHashable: Any]?
    )
        -> NSError?
    {
        stp_error(fromStripeResponse: jsonDictionary, httpResponse: nil)
    }
}

// MARK: STPCardErrorCodeKeys -

/// Possible string values you may receive when there was an error tokenizing a card.
///
/// These values will come back in the error `userInfo` dictionary
/// under the `STPCardErrorCodeKey` key.
public enum STPCardErrorCode: String {
    /// The card number is not a valid credit card number.
    case invalidNumber = "com.stripe.lib:InvalidNumber"
    /// The card has an invalid expiration month.
    case invalidExpMonth = "com.stripe.lib:InvalidExpiryMonth"
    /// The card has an invalid expiration year.
    case invalidExpYear = "com.stripe.lib:InvalidExpiryYear"
    /// The card has an invalid CVC.
    case invalidCVC = "com.stripe.lib:InvalidCVC"
    /// The card number is incorrect.
    case incorrectNumber = "com.stripe.lib:IncorrectNumber"
    /// The card is expired.
    case expiredCard = "com.stripe.lib:ExpiredCard"
    /// The card was declined.
    case cardDeclined = "com.stripe.lib:CardDeclined"
    /// The card has an incorrect CVC.
    case incorrectCVC = "com.stripe.lib:IncorrectCVC"
    /// An error occured while processing this card.
    case processingError = "com.stripe.lib:ProcessingError"
    /// The postal code is incorrect.
    case incorrectZip = "com.stripe.lib:IncorrectZip"
}

// swift-format-ignore: DontRepeatTypeInStaticProperties
@objc extension STPError {
    /// The card number is not a valid credit card number.
    public static let invalidNumber = STPCardErrorCode.invalidNumber.rawValue
    /// The card has an invalid expiration month.
    public static let invalidExpMonth = STPCardErrorCode.invalidExpMonth.rawValue
    /// The card has an invalid expiration year.
    public static let invalidExpYear = STPCardErrorCode.invalidExpYear.rawValue
    /// The card has an invalid CVC.
    public static let invalidCVC = STPCardErrorCode.invalidCVC.rawValue
    /// The card number is incorrect.
    public static let incorrectNumber = STPCardErrorCode.incorrectNumber.rawValue
    /// The card is expired.
    public static let expiredCard = STPCardErrorCode.expiredCard.rawValue
    /// The card was declined.
    public static let cardDeclined = STPCardErrorCode.cardDeclined.rawValue
    /// An error occured while processing this card.
    public static let processingError = STPCardErrorCode.processingError.rawValue
    /// The card has an incorrect CVC.
    public static let incorrectCVC = STPCardErrorCode.incorrectCVC.rawValue
    /// The postal code is incorrect.
    public static let incorrectZip = STPCardErrorCode.incorrectZip.rawValue
}

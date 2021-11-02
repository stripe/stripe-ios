//
//  STPError.swift
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/4/12.
//
//

import Foundation
@_spi(STP) import StripeCore

// These must line up with the codes in STPError.swift.
/// :nodoc:
///
/// Possible error code values for NSErrors with the `StripeDomain` domain
@available(swift, deprecated: 0.0.1, renamed: "STPErrorCode")
@objc(STPErrorCode) public enum _stpobjc_STPErrorCode: Int {
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
    /// https://stripe.com/docs/mobile/ios/standard#prepare-your-api
    @objc(STPEphemeralKeyDecodingError) case ephemeralKeyDecodingError = 1000
}

// MARK: - STPError

/// :nodoc:
///
/// Top-level class for Stripe error constants.
@available(swift, deprecated: 0.0.1, renamed: "STPError")
@objc(STPError) public class _stpobjc_STPError: NSObject {
    // MARK: userInfo keys
    /// All Stripe iOS errors will be under this domain.
    @objc public static let stripeDomain = STPError.stripeDomain

    /// A human-readable message providing more details about the error.
    /// For card errors, these messages can be shown to your users.
    /// - seealso: https://stripe.com/docs/api/errors#errors-message
    @objc public static let errorMessageKey = STPError.errorMessageKey
    /// An SDK-supplied "hint" that is intended to help you, the developer, fix the error
    @objc public static let hintKey = STPError.hintKey
    
    /// What went wrong with your STPCard (e.g., STPInvalidCVC. See below for full list).
    @objc public static let cardErrorCodeKey = STPError.cardErrorCodeKey
    /// Which parameter on the STPCard had an error (e.g., "cvc"). Useful for marking up the
    /// right UI element.
    @objc public static let errorParameterKey = STPError.errorParameterKey
    /// The error code returned by the Stripe API.
    /// - seealso: https://stripe.com/docs/api#errors-code
    /// - seealso: https://stripe.com/docs/error-codes
    @objc public static let stripeErrorCodeKey = STPError.stripeErrorCodeKey
    /// The error type returned by the Stripe API.
    /// - seealso: https://stripe.com/docs/api#errors-type
    @objc public static let stripeErrorTypeKey = STPError.stripeErrorTypeKey
    /// If the value of `userInfo[stripeErrorCodeKey]` is `STPError.cardDeclined`,
    /// the value for this key contains the decline code.
    /// - seealso: https://stripe.com/docs/declines/codes
    @objc public static let stripeDeclineCodeKey = STPError.stripeDeclineCodeKey
    
    // MARK: Card errors
    
    /// The card number is not a valid credit card number.
    @objc public static let invalidNumber = STPError.invalidNumber
    /// The card has an invalid expiration month.
    @objc public static let invalidExpMonth = STPError.invalidExpMonth
    /// The card has an invalid expiration year.
    @objc public static let invalidExpYear = STPError.invalidExpYear
    /// The card has an invalid CVC.
    @objc public static let invalidCVC = STPError.invalidCVC
    /// The card number is incorrect.
    @objc public static let incorrectNumber = STPError.incorrectNumber
    /// The card is expired.
    @objc public static let expiredCard = STPError.expiredCard
    /// The card was declined.
    @objc public static let cardDeclined = STPError.cardDeclined
    /// An error occured while processing this card.
    @objc public static let processingError = STPError.processingError
    /// The card has an incorrect CVC.
    @objc public static let incorrectCVC = STPError.incorrectCVC
    /// The postal code is incorrect.
    @objc public static let incorrectZip = STPError.incorrectZip
}

/// NSError extensions for creating error objects from Stripe API responses.
@objc extension NSError {
    /// Creates an NSError object from a given Stripe API json response.
    /// - Parameter jsonDictionary: The root dictionary from the JSON response.
    /// - Returns: An NSError object with the error information from the JSON response,
    /// or nil if there was no error information included in the JSON dictionary.
    @available(swift, deprecated: 0.0.1, renamed: "stp_error(fromStripeResponse:)")
    @objc(stp_errorFromStripeResponse:) public static func _stpobjc_stp_error(fromStripeResponse jsonDictionary: [AnyHashable: Any]?)
        -> NSError?
    {
        return stp_error(fromStripeResponse: jsonDictionary)
    }
}

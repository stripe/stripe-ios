//
//  NSError+Stripe.swift
//  StripeCore
//
//  Created by Brian Dorfman on 8/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

extension NSError {
    @objc @_spi(STP) public class func stp_genericConnectionError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey: "There was an error connecting to Stripe.",
        ]
        return NSError(
            domain: STPError.stripeDomain,
            code: STPErrorCode.connectionError.rawValue,
            userInfo: userInfo
        )
    }

    @objc @_spi(STP) public class func stp_genericFailedToParseResponseError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey:
                "The response from Stripe failed to get parsed into valid JSON.",
        ]
        return NSError(
            domain: STPError.stripeDomain,
            code: STPErrorCode.apiError.rawValue,
            userInfo: userInfo
        )
    }

    @objc @_spi(STP) public class func stp_ephemeralKeyDecodingError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey:
                "Failed to decode the ephemeral key. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app.",
        ]
        return NSError(
            domain: STPError.stripeDomain,
            code: STPErrorCode.ephemeralKeyDecodingError.rawValue,
            userInfo: userInfo
        )
    }

    @objc @_spi(STP) public class func stp_clientSecretError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey:
                "The `secret` format does not match expected client secret formatting.",
        ]
        return NSError(
            domain: STPError.stripeDomain,
            code: STPErrorCode.invalidRequestError.rawValue,
            userInfo: userInfo
        )
    }

    @objc @_spi(STP) public class func stp_cardBrandNotUpdatedError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_cardBrandNotUpdatedMessage()
        ]
        return NSError(
            domain: STPError.stripeDomain,
            code: STPErrorCode.apiError.rawValue,
            userInfo: userInfo
        )
    }

    @objc @_spi(STP) public class func stp_defaultPaymentMethodNotUpdatedError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_defaultPaymentMethodNotUpdatedMessage()
        ]
        return NSError(
            domain: STPError.stripeDomain,
            code: STPErrorCode.apiError.rawValue,
            userInfo: userInfo
        )
    }

    @objc @_spi(STP) public class func stp_genericErrorOccurredError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_genericErrorOccurredMessage()
        ]
        return NSError(
            domain: STPError.stripeDomain,
            code: STPErrorCode.apiError.rawValue,
            userInfo: userInfo
        )
    }

    // TODO(davide): We'll want to move these into StripePayments, once it exists.

    // MARK: Strings
    @objc @_spi(STP) public class func stp_cardErrorInvalidNumberUserMessage() -> String {
        return STPLocalizedString(
            "Your card's number is invalid",
            "Error when the card number is not valid"
        )
    }

    @objc @_spi(STP) public class func stp_cardInvalidCVCUserMessage() -> String {
        return STPLocalizedString(
            "Your card's security code is invalid",
            "Error when the card's CVC is not valid"
        )
    }

    @objc @_spi(STP) public class func stp_cardErrorInvalidExpMonthUserMessage() -> String {
        return STPLocalizedString(
            "Your card's expiration month is invalid",
            "Error when the card's expiration month is not valid"
        )
    }

    @objc @_spi(STP) public class func stp_cardErrorInvalidExpYearUserMessage() -> String {
        return STPLocalizedString(
            "Your card's expiration year is invalid",
            "Error when the card's expiration year is not valid"
        )
    }

    @objc @_spi(STP) public class func stp_cardErrorExpiredCardUserMessage() -> String {
        return STPLocalizedString(
            "Your card has expired",
            "Error when the card has already expired"
        )
    }

    @objc @_spi(STP) public class func stp_cardErrorDeclinedUserMessage() -> String {
        return STPLocalizedString(
            "Your card was declined",
            "Error when the card was declined by the credit card networks"
        )
    }

    @objc @_spi(STP) public class func stp_genericDeclineErrorUserMessage() -> String {
        return STPLocalizedString(
            "Your payment method was declined.",
            "Error message when a payment method gets declined."
        )
    }

    @objc @_spi(STP) public class func stp_cardErrorProcessingErrorUserMessage() -> String {
        return STPLocalizedString(
            "There was an error processing your card -- try again in a few seconds",
            "Error when there is a problem processing the credit card"
        )
    }

    @_spi(STP) public static var stp_invalidOwnerName: String {
        return STPLocalizedString(
            "Your name is invalid.",
            "Error when customer's name is invalid"
        )
    }

    @_spi(STP) public static var stp_invalidBankAccountIban: String {
        return STPLocalizedString(
            "The IBAN you entered is invalid.",
            "An error message displayed when the customer's iban is invalid."
        )
    }

    @objc @_spi(STP) public class func stp_cardBrandNotUpdatedMessage() -> String {
        return STPLocalizedString(
            "Card brand was not updated. Please try again.",
            "An error message displayed when updating a card brand fails."
        )
    }

    @objc @_spi(STP) public class func stp_defaultPaymentMethodNotUpdatedMessage() -> String {
        return STPLocalizedString(
            "Default payment method was not updated. Please try again.",
            "An error message displayed when setting a default payment method fails."
        )
    }

    @objc @_spi(STP) public class func stp_genericErrorOccurredMessage() -> String {
        return STPLocalizedString(
            "An error occurred. Please try again.",
            "A generic error message displayed when an error occurs."
        )
    }
}

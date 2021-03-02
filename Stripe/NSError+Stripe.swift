//
//  NSError+Stripe.swift
//  Stripe
//
//  Created by Brian Dorfman on 8/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

extension NSError {
    @objc class func stp_genericConnectionError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey: "There was an error connecting to Stripe.",
        ]
        return NSError(
            domain: STPError.stripeDomain, code: STPErrorCode.connectionError.rawValue,
            userInfo: userInfo
        )
    }

    @objc class func stp_genericFailedToParseResponseError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey:
                "The response from Stripe failed to get parsed into valid JSON.",
        ]
        return NSError(
            domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue, userInfo: userInfo)
    }

    @objc class func stp_ephemeralKeyDecodingError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: self.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey:
                "Failed to decode the ephemeral key. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app.",
        ]
        return NSError(
            domain: STPError.stripeDomain, code: STPErrorCode.ephemeralKeyDecodingError.rawValue,
            userInfo: userInfo)
    }

    // MARK: Strings
    @objc class func stp_cardErrorInvalidNumberUserMessage() -> String {
        return STPLocalizedString(
            "Your card's number is invalid", "Error when the card number is not valid")
    }

    @objc class func stp_cardInvalidCVCUserMessage() -> String {
        return STPLocalizedString(
            "Your card's security code is invalid", "Error when the card's CVC is not valid")
    }

    @objc class func stp_cardErrorInvalidExpMonthUserMessage() -> String {
        return STPLocalizedString(
            "Your card's expiration month is invalid",
            "Error when the card's expiration month is not valid")
    }

    @objc class func stp_cardErrorInvalidExpYearUserMessage() -> String {
        return STPLocalizedString(
            "Your card's expiration year is invalid",
            "Error when the card's expiration year is not valid"
        )
    }

    @objc class func stp_cardErrorExpiredCardUserMessage() -> String {
        return STPLocalizedString(
            "Your card has expired", "Error when the card has already expired")
    }

    @objc class func stp_cardErrorDeclinedUserMessage() -> String {
        return STPLocalizedString(
            "Your card was declined", "Error when the card was declined by the credit card networks"
        )
    }

    @objc class func stp_cardErrorProcessingErrorUserMessage() -> String {
        return STPLocalizedString(
            "There was an error processing your card -- try again in a few seconds",
            "Error when there is a problem processing the credit card")
    }

    @objc class func stp_unexpectedErrorMessage() -> String {
        return STPLocalizedString(
            "There was an unexpected error -- try again in a few seconds",
            "Unexpected error, such as a 500 from Stripe or a JSON parse error")
    }
}

//
//  String+Localized.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/14/25.
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension String.Localized {
    static var cryptoOnrampErrorInvalidPhoneFormat: String {
        return STPLocalizedString(
            "Invalid phone format. Please use E.164 format (e.g., +12125551234).",
            "Error message shown when the provided phone number is not in the expected format"
        )
    }

    static var cryptoOnrampErrorLinkAccountAlreadyExists: String {
        return STPLocalizedString(
            "A Link account already exists for this email. Log in instead.",
            "Error message shown when the user tries to create a Link account for an email that already has one"
        )
    }

    static var cryptoOnrampErrorMissingEphemeralKey: String {
        return STPLocalizedString(
            "Required information was missing. Please try again later.",
            "Error message shown when the SDK is missing required information from the server"
        )
    }

    static var cryptoOnrampErrorInvalidSelectedPaymentSource: String {
        return STPLocalizedString(
            "No payment method is ready to use. Please collect a payment method and try again.",
            "Error message shown when there is no usable payment method selected"
        )
    }

    static var cryptoOnrampErrorMissingCryptoCustomerID: String {
        return STPLocalizedString(
            "Finish verifying your Link account before continuing.",
            "Error message shown when the SDK needs a crypto customer ID before continuing"
        )
    }

    static var cryptoOnrampErrorLinkAccountNotVerified: String {
        return STPLocalizedString(
            "Verify your Link account before continuing.",
            "Error message shown when the user's Link account is not verified"
        )
    }

    static var cryptoOnrampErrorSeamlessSignInTokenInvalid: String {
        return STPLocalizedString(
            "An error occurred while automatically signing in to your Link account. Please sign in manually.",
            "Error message shown when automatic Link sign-in fails and the user needs to sign in manually"
        )
    }

    static var cryptoOnrampErrorAppAttestationFailed: String {
        return STPLocalizedString(
            "This app couldn't be verified due to an attestation error. Please try again later or contact the developer if the issue persists.",
            "Error message shown when app attestation fails"
        )
    }

    static var debitIsMostLikelyToBeAccepted: String {
        return STPLocalizedString(
            "Debit cards are most likely to be accepted.",
            "Label shown in the Link UI indicating that debit cards are more likely to be accepted"
        )
    }

    static func redactedCardDetails(using card: StripeAPI.PaymentMethod.Card) -> String? {
        let brand = stpCardBrand(from: card.brand)
        let brandString = STPCard.string(from: brand)
        guard !brandString.isEmpty, let last4 = card.last4 else {
            return nil
        }

        return String(format: card_details_xxxx, brandString, last4)
    }

    private static func stpCardBrand(from brand: StripeAPI.PaymentMethod.Card.Brand) -> STPCardBrand {
        switch brand {
        case .visa: return .visa
        case .amex: return .amex
        case .mastercard: return .mastercard
        case .discover: return .discover
        case .jcb: return .JCB
        case .diners: return .dinersClub
        case .unionpay: return .unionPay
        case .unknown, .unparsable: return .unknown
        }
    }
}

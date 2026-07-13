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
    static var cryptoOnrampErrorAppAttestationUnavailable: String {
        return STPLocalizedString(
            "This app couldn't be verified. Contact the app developer for help.",
            "Error message shown when app attestation is not configured for crypto onramp"
        )
    }

    static var cryptoOnrampErrorAppAttestationFailed: String {
        return STPLocalizedString(
            "This app couldn't be verified due to an attestation error. Please try again later or contact the developer if the issue persists.",
            "Error message shown when app attestation fails"
        )
    }

    static var cryptoOnrampErrorInvalidWalletOwnershipSignature: String {
        return STPLocalizedString(
            "We couldn't verify ownership of this wallet. Please try again.",
            "Error message shown when the submitted wallet ownership signature is invalid"
        )
    }

    static var cryptoOnrampErrorWalletOwnershipChallengeExpired: String {
        return STPLocalizedString(
            "This wallet verification request expired. Please try again.",
            "Error message shown when the wallet ownership challenge has expired"
        )
    }

    static var cryptoOnrampErrorInvalidWalletOwnershipChallenge: String {
        return STPLocalizedString(
            "This wallet verification request is invalid. Please try again.",
            "Error message shown when the wallet ownership challenge is invalid"
        )
    }

    static var cryptoOnrampErrorWalletNotFound: String {
        return STPLocalizedString(
            "This wallet couldn't be found. Please choose or add a wallet and try again.",
            "Error message shown when the wallet is not registered for crypto onramp"
        )
    }

    static var cryptoOnrampErrorUnsupportedNetwork: String {
        return STPLocalizedString(
            "This wallet network isn't supported. Please choose a different network.",
            "Error message shown when the wallet network is not supported for crypto onramp"
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

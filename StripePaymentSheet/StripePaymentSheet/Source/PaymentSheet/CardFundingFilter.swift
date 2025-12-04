//
//  CardFundingFilter.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/25/25.
//

import Foundation
import PassKit
@_spi(STP) import StripePayments

struct CardFundingFilter: Equatable {

    private let cardFundingAcceptance: PaymentSheet.CardFundingAcceptance

    init(cardFundingAcceptance: PaymentSheet.CardFundingAcceptance) {
        self.cardFundingAcceptance = cardFundingAcceptance
    }

    /// Determines if a merchant can accept a card based on its funding type using `cardFundingAcceptance`
    /// - Parameter cardFundingType: The `STPCardFundingType` to determine acceptance
    /// - Returns: Returns true if this merchant can accept this card funding type, false otherwise
    public func isAccepted(cardFundingType: STPCardFundingType) -> Bool {
        switch cardFundingAcceptance {
        case .all:
            return true
        case .allowed(let allowedFundingTypes):
            let fundingCategory = cardFundingType.asFundingCategory
            return allowedFundingTypes.contains(fundingCategory)
        }
    }

    /// Returns the `PKMerchantCapability` to use for Apple Pay based on the card funding acceptance configuration.
    /// - Returns: A `PKMerchantCapability` option set that includes 3DS and any funding type restrictions,
    ///            or `nil` if no override is needed (use the default capabilities provided on the payment request).
    func applePayMerchantCapabilities() -> PKMerchantCapability? {
        switch cardFundingAcceptance {
        case .all:
            // When all funding types are accepted, don't override the merchant capabilities.
            // The default capabilities on the payment request will be used.
            return nil
        case .allowed(let allowedFundingTypes):
            var capabilities: PKMerchantCapability = .capability3DS
            if allowedFundingTypes.contains(.debit) {
                capabilities.insert(.capabilityDebit)
            }
            if allowedFundingTypes.contains(.credit) {
                capabilities.insert(.capabilityCredit)
            }
            return capabilities
        }
    }
}

extension STPCardFundingType {
    var asFundingCategory: PaymentSheet.CardFundingType {
        switch self {
        case .debit:
            return .debit
        case .credit:
            return .credit
        case .prepaid:
            return .prepaid
        case .other:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}

extension PaymentElementConfiguration {
    var cardFundingFilter: CardFundingFilter {
        .init(cardFundingAcceptance: allowedCardFundingTypes)
    }
}

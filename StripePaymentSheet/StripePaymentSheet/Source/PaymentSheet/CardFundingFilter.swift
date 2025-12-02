//
//  CardFundingFilter.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/25/25.
//

import Foundation
import PassKit
@_spi(STP) import StripePayments

@_spi(CardFundingFilteringPrivatePreview)
public struct CardFundingFilter: Equatable {

    static let `default`: CardFundingFilter = .init(cardFundingAcceptance: .all)

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
    /// - Returns: A `PKMerchantCapability` option set that includes 3DS and any funding type restrictions
    func applePayMerchantCapabilities() -> PKMerchantCapability {
        switch cardFundingAcceptance {
        case .all:
            return .capability3DS
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
    @_spi(CardFundingFilteringPrivatePreview)
    public var asFundingCategory: PaymentSheet.CardFundingType {
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

@_spi(CardFundingFilteringPrivatePreview)
extension PaymentElementConfiguration {
    var cardFundingFilter: CardFundingFilter {
        .init(cardFundingAcceptance: allowedCardFundingTypes)
    }
}

// MARK: - STPPaymentMethodCard filtering

extension STPPaymentMethodCard {
    /// Determines if this card is accepted based on card brand and funding type filters.
    /// - Parameters:
    ///   - cardBrandFilter: The filter for allowed/disallowed card brands
    ///   - cardFundingFilter: The filter for allowed card funding types
    /// - Returns: `true` if the card passes both brand and funding filters, `false` otherwise
    func isAccepted(cardBrandFilter: CardBrandFilter, cardFundingFilter: CardFundingFilter) -> Bool {
        // Filter by card brand
        if !cardBrandFilter.isAccepted(cardBrand: preferredDisplayBrand) {
            return false
        }
        // Filter by card funding type
        if let fundingString = funding {
            let fundingType = STPCard.funding(from: fundingString)
            if !cardFundingFilter.isAccepted(cardFundingType: fundingType) {
                return false
            }
        }
        return true
    }
}

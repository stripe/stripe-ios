//
//  CardFundingFilter.swift
//  StripePaymentSheet
//
//  Created by Stripe on 11/24/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripePayments

struct CardFundingFilter: Equatable {

    static let `default`: CardFundingFilter = .init(cardFundingAcceptance: .all)

    private let cardFundingAcceptance: PaymentSheet.CardFundingAcceptance

    init(cardFundingAcceptance: PaymentSheet.CardFundingAcceptance) {
        self.cardFundingAcceptance = cardFundingAcceptance
    }

    /// Determines if a merchant can accept a card funding type based on `cardFundingAcceptance`
    /// - Parameter fundingType: The `STPCardFundingType` to determine acceptance
    /// - Returns: Returns true if this merchant can accept this card funding type, false otherwise
    func isAccepted(fundingType: STPCardFundingType) -> Bool {
        switch cardFundingAcceptance {
        case .all:
            return true
        case .allowed(let allowedFundingTypes):
            // If a merchant has specified a list of funding types to allow, block unknown types
            guard let fundingCategory = fundingType.asFundingCategory else {
                return false
            }

            if !allowedFundingTypes.contains(fundingCategory) {
                return false
            }
        case .disallowed(let disallowedFundingTypes):
            if let fundingCategory = fundingType.asFundingCategory, disallowedFundingTypes.contains(fundingCategory) {
                return false
            }
        }

        return true
    }

    /// Converts card funding acceptance configuration to PKMerchantCapability flags
    /// - Returns: PKMerchantCapability flags for the payment request
    func merchantCapabilities() -> PKMerchantCapability {
        // Always include 3DS as the base capability
        var capabilities: PKMerchantCapability = .capability3DS

        switch cardFundingAcceptance {
        case .all:
            // No additional restrictions - accept all funding types
            break

        case .allowed(let fundingTypes):
            // Only allow specified funding types
            let hasCredit = fundingTypes.contains(.credit)
            let hasDebit = fundingTypes.contains(.debit)
            // Note: Prepaid is handled via delegate, not merchantCapabilities

            if hasCredit && !hasDebit {
                capabilities.insert(.capabilityCredit)
            } else if hasDebit && !hasCredit {
                capabilities.insert(.capabilityDebit)
            }
            // If both credit and debit are allowed, or only prepaid, no additional capability needed

        case .disallowed(let fundingTypes):
            // Block specified funding types by only allowing the opposite
            let blocksCredit = fundingTypes.contains(.credit)
            let blocksDebit = fundingTypes.contains(.debit)

            if blocksCredit && !blocksDebit {
                capabilities.insert(.capabilityDebit)
            } else if blocksDebit && !blocksCredit {
                capabilities.insert(.capabilityCredit)
            }
            // If both are blocked, or only prepaid blocked, no additional capability
        }

        return capabilities
    }
}

extension STPCardFundingType {
    var asFundingCategory: PaymentSheet.CardFundingAcceptance.CardFundingCategory? {
        switch self {
        case .credit:
            return .credit
        case .debit:
            return .debit
        case .prepaid:
            return .prepaid
        case .unknown:
            return nil
        @unknown default:
            return nil
        }
    }
}

@_spi(CardFundingFilteringPrivatePreview)
extension PaymentElementConfiguration {
    var cardFundingFilter: CardFundingFilter {
        .init(cardFundingAcceptance: cardFundingAcceptance)
    }
}

@_spi(CardFundingFilteringPrivatePreview)
extension CustomerSheet.Configuration {
    var cardFundingFilter: CardFundingFilter {
        .init(cardFundingAcceptance: cardFundingAcceptance)
    }
}

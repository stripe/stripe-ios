//
//  CardFundingFilter.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/25/25.
//

import Foundation
import PassKit
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

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

    /// Returns a user-friendly display string of the allowed funding types (e.g. "debit", "debit and credit")
    /// - Returns: A localized string listing the allowed funding types, or nil if all types are allowed
    func allowedFundingTypesDisplayString() -> String? {
        switch cardFundingAcceptance {
        case .all:
            return nil
        case .allowed(let allowedFundingTypes):
            // Filter to only user-visible funding types (exclude unknown)
            let displayableTypes = allowedFundingTypes.filter { $0 != .unknown }
            guard !displayableTypes.isEmpty else { return nil }

            let displayNames = displayableTypes.compactMap { $0.displayName }
            guard !displayNames.isEmpty else { return nil }

            // Join with localized "and" for the last element
            if displayNames.count == 1 {
                return displayNames[0]
            } else if displayNames.count == 2 {
                return String.Localized.x_and_y(displayNames[0], displayNames[1])
            } else {
                // For 3+ items: "a, b, and c"
                let allButLast = displayNames.dropLast().joined(separator: ", ")
                return String.Localized.x_and_y(allButLast, displayNames.last!)
            }
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

    /// Returns a user-friendly display name for the card funding type.
    var displayName: String {
        return asFundingCategory.displayName
    }
}

extension PaymentSheet.CardFundingType {
    /// Returns a user-friendly display name for the card funding category.
    var displayName: String {
        switch self {
        case .credit:
            return String.Localized.credit.lowercased()
        case .debit:
            return String.Localized.debit.lowercased()
        case .prepaid:
            return String.Localized.prepaid.lowercased()
        case .unknown:
            return ""
        }
    }
}

extension PaymentElementConfiguration {
    var cardFundingFilter: CardFundingFilter {
        .init(cardFundingAcceptance: allowedCardFundingTypes)
    }
}

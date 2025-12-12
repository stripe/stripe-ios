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

    /// A default filter that accepts all card funding types (no filtering applied).
    static let `default`: CardFundingFilter = .init(allowedFundingTypes: .all, filteringEnabled: false)

    private let allowedFundingTypes: PaymentSheet.CardFundingType

    /// When `false`, the filter acts as a no-op and accepts all card funding types.
    /// This is controlled by the `elements_mobile_card_funding_filtering` flag from the server.
    private let filteringEnabled: Bool

    init(allowedFundingTypes: PaymentSheet.CardFundingType, filteringEnabled: Bool) {
        self.allowedFundingTypes = allowedFundingTypes
        self.filteringEnabled = filteringEnabled
    }

    /// Creates a `CardFundingFilter` using the configuration's allowed funding types and
    /// the server's filtering enabled flag from the elements session.
    /// - Parameters:
    ///   - allowedFundingTypes: The funding types allowed by the merchant configuration.
    ///   - elementsSession: The elements session containing the server-side flag.
    /// - Returns: A properly configured `CardFundingFilter`.
    static func from(
        allowedFundingTypes: PaymentSheet.CardFundingType,
        elementsSession: STPElementsSession
    ) -> CardFundingFilter {
        return CardFundingFilter(
            allowedFundingTypes: allowedFundingTypes,
            filteringEnabled: elementsSession.isCardFundingFilteringEnabled
        )
    }

    /// Determines if a merchant can accept a card based on its funding type
    /// - Parameter cardFundingType: The `STPCardFundingType` to determine acceptance
    /// - Returns: Returns true if this merchant can accept this card funding type, false otherwise.
    ///            Always returns true when filtering is disabled.
    public func isAccepted(cardFundingType: STPCardFundingType) -> Bool {
        guard filteringEnabled else {
            return true
        }
        if allowedFundingTypes == .all {
            return true
        }
        let fundingCategory = cardFundingType.asFundingType
        return allowedFundingTypes.contains(fundingCategory)
    }

    /// Returns the `PKMerchantCapability` to use for Apple Pay based on the allowed funding types.
    /// - Returns: A `PKMerchantCapability` option set that includes 3DS and any funding type restrictions,
    ///            or `nil` if no override is needed (use the default capabilities provided on the payment request).
    ///            Always returns `nil` when filtering is disabled.
    func applePayMerchantCapabilities() -> PKMerchantCapability? {
        guard filteringEnabled else {
            return nil
        }
        if allowedFundingTypes == .all {
            // When all funding types are accepted, don't override the merchant capabilities.
            // The default capabilities on the payment request will be used.
            return nil
        }

        var capabilities: PKMerchantCapability = .capability3DS
        if allowedFundingTypes.contains(.debit) {
            capabilities.insert(.capabilityDebit)
        }
        if allowedFundingTypes.contains(.credit) {
            capabilities.insert(.capabilityCredit)
        }
        return capabilities
    }

    /// Returns a user-friendly display string of the allowed funding types (e.g. "debit", "debit and credit")
    /// - Returns: A localized string listing the allowed funding types, or nil if all types are allowed.
    ///            Always returns `nil` when filtering is disabled.
    func allowedFundingTypesDisplayString() -> String? {
        guard filteringEnabled else {
            return nil
        }
        if allowedFundingTypes == .all {
            return nil
        }

        var displayNames: [String] = []
        if allowedFundingTypes.contains(.debit) {
            displayNames.append(String.Localized.debit.lowercased())
        }
        if allowedFundingTypes.contains(.credit) {
            displayNames.append(String.Localized.credit.lowercased())
        }
        if allowedFundingTypes.contains(.prepaid) {
            displayNames.append(String.Localized.prepaid.lowercased())
        }
        // Note: .unknown has no display name - we don't show it to users

        guard !displayNames.isEmpty,
              let displayNamesFirst = displayNames.first,
              let displayNamesLast = displayNames.last else { return nil }

        // Join with localized "and" for the last element
        if displayNames.count == 1 {
            // E.g. "debit"
            return displayNamesFirst
        } else if displayNames.count == 2 {
            // E.g. "debit and prepaid"
            return String.Localized.x_and_y(displayNamesFirst, displayNamesLast)
        } else {
            // For 3+ items: "credit, debit, and prepaid"
            let allButLast = displayNames.dropLast().joined(separator: ", ")
            return String.Localized.x_and_y(allButLast, displayNamesLast)
        }
    }
}

extension STPCardFundingType {
    var asFundingType: PaymentSheet.CardFundingType {
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
    /// Creates a `CardFundingFilter` using the configuration's allowed funding types and
    /// the filtering enabled flag from the elements session.
    /// - Parameter elementsSession: The elements session containing the server-side flag.
    /// - Returns: A properly configured `CardFundingFilter`.
    func cardFundingFilter(for elementsSession: STPElementsSession) -> CardFundingFilter {
        CardFundingFilter.from(allowedFundingTypes: allowedCardFundingTypes, elementsSession: elementsSession)
    }
}

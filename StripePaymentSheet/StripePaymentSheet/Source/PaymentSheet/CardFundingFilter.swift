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

    /// Returns a user-friendly display string indicating which funding types are accepted.
    /// - Returns: A complete localized message (e.g. "Only debit cards are accepted"), or nil if all types are allowed.
    ///            Always returns `nil` when filtering is disabled.
    func allowedFundingTypesDisplayString() -> String? {
        guard filteringEnabled else { return nil }
        if allowedFundingTypes == .all { return nil }

        let hasDebit = allowedFundingTypes.contains(.debit)
        let hasCredit = allowedFundingTypes.contains(.credit)
        let hasPrepaid = allowedFundingTypes.contains(.prepaid)

        switch (hasDebit, hasCredit, hasPrepaid) {
        // Single types
        case (true, false, false):
            return String.Localized.only_debit_cards_accepted
        case (false, true, false):
            return String.Localized.only_credit_cards_accepted
        case (false, false, true):
            return String.Localized.only_prepaid_cards_accepted
        // Two types
        case (true, true, false):
            return String.Localized.only_debit_and_credit_cards_accepted
        case (true, false, true):
            return String.Localized.only_debit_and_prepaid_cards_accepted
        case (false, true, true):
            return String.Localized.only_credit_and_prepaid_cards_accepted
        // All three types or no types (should never happen)
        case (true, true, true), (false, false, false):
            return nil
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

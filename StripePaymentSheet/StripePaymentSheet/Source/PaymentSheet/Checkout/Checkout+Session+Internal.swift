//
//  Checkout+Session+Internal.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

// MARK: - Computed Properties

extension Checkout.Session {
    /// The express button types available for this session, derived from the elements session.
    var availableExpressButtonTypes: [ExpressButton] {
        var types: [ExpressButton] = []
        for type in elementsSession.orderedPaymentMethodTypesAndWallets {
            switch type {
            case "apple_pay" where !types.contains(.applePay) && elementsSession.isApplePayEnabled:
                types.append(.applePay)
            case "link" where !types.contains(.link):
                types.append(.link)
            default:
                continue
            }
        }
        if elementsSession.linkPassthroughModeEnabled, !types.contains(.link) {
            types.append(.link)
        }
        return types
    }

    var customerId: String? {
        return customer?.id
    }

    var requiresShippingAddress: Bool {
        allowedShippingCountries != nil
    }

    var isPaymentMethodOptionsSetupFutureUsageSet: Bool {
        return !setupFutureUsageForPaymentMethodType.isEmpty
    }

    /// Whether this Checkout Session computes automatic tax from the billing address.
    var collectsTaxFromBillingAddress: Bool {
        return shouldSendTaxRegion(for: "billing")
    }

    /// Whether this session's `payment_status` is `no_payment_required`.
    var noPaymentRequired: Bool {
        return paymentStatus == .noPaymentRequired
    }
}

// MARK: - Methods

extension Checkout.Session {
    /// Returns `true` when the server needs a `tax_region` update for the given address type.
    ///
    /// - Parameter addressType: Either `"billing"` or `"shipping"`.
    func shouldSendTaxRegion(for addressType: String) -> Bool {
        return automaticTaxEnabled && automaticTaxAddressSource == addressType
    }

    /// Returns the expected amount for payment-style sessions and `nil` for setup-style sessions.
    func expectedAmount() -> Int? {
        guard !noPaymentRequired else { return nil }
        guard let total = total?.total.minorUnitsAmount else {
            stpAssertionFailure("Missing expected amount from checkout session")
            return nil
        }
        return total
    }

    func merchantWillSavePaymentMethod(_ paymentMethodType: STPPaymentMethodType) -> Bool {
        guard customerId != nil else {
            return false
        }

        if noPaymentRequired {
            return true
        }

        guard let setupFutureUsage = setupFutureUsage(for: paymentMethodType) else {
            return false
        }
        return setupFutureUsage != "none"
    }

    func setupFutureUsage(for paymentMethodType: STPPaymentMethodType) -> String? {
        let perPaymentMethodSetupFutureUsage = setupFutureUsageForPaymentMethodType[paymentMethodType.identifier]
        if let perPaymentMethodSetupFutureUsage {
            return perPaymentMethodSetupFutureUsage
        }

        return setupFutureUsage
    }
}

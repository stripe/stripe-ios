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
    var availableExpressButtonTypes: [ExpressCheckoutElement.PaymentMethod] {
        var types: [ExpressCheckoutElement.PaymentMethod] = []
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
        return Int(totals.total.minorUnitsAmount)
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

enum SessionFieldUpdate<Value> {
    case keepOldValue
    case newValue(Value?)

    func resolved(currentValue: Value?) -> Value? {
        switch self {
        case .keepOldValue:
            return currentValue
        case .newValue(let newValue):
            return newValue
        }
    }
}

extension Checkout.Session {
    /// Apologetic explanation for this method:
    /// - Situation: Session is immutable, so all mutations must create a new one.
    /// - Complication: Optional fields need three states here: keep the old value, replace with a non-nil value, or explicitly clear to nil.
    /// - Resolution: SessionFieldUpdate keeps that distinction visible at call sites instead of relying on double optionals.
    func makeCopyOverriding(
        shippingAddress: SessionFieldUpdate<Checkout.Session.ShippingAddress> = .keepOldValue,
        paymentOption: SessionFieldUpdate<Checkout.Session.PaymentOptionDisplayData> = .keepOldValue
    ) -> Self {
        return Self(
            id: id,
            businessName: businessName,
            currency: currency,
            currencyOptions: currencyOptions,
            discountAmounts: discountAmounts,
            email: email,
            orderSummaryItems: orderSummaryItems,
            livemode: livemode,
            minorUnitsAmountDivisor: minorUnitsAmountDivisor,
            paymentOption: paymentOption.resolved(currentValue: self.paymentOption),
            shippingAddress: shippingAddress.resolved(currentValue: self.shippingAddress),
            status: status,
            tax: tax,
            taxAmounts: taxAmounts,
            totals: totals,
            paymentStatus: paymentStatus,
            paymentMethodOptions: paymentMethodOptions,
            customer: customer,
            savedPaymentMethodsOfferSave: savedPaymentMethodsOfferSave,
            setupFutureUsage: setupFutureUsage,
            setupFutureUsageForPaymentMethodType: setupFutureUsageForPaymentMethodType,
            allowedShippingCountries: allowedShippingCountries,
            localizedPricesMetas: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta,
            adaptivePricingActive: adaptivePricingActive,
            billingAddressCollection: billingAddressCollection,
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource,
            elementsSession: elementsSession
        )
    }
}

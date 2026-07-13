//
//  Checkout+Session+Internal.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

// MARK: - Computed Properties

extension Checkout.Session {
    var customerId: String? {
        return customer?.id
    }

    var requiresShippingAddress: Bool {
        allowedShippingCountries != nil
    }

    var automaticTaxUsesBillingAddress: Bool {
        shouldSendTaxRegion(for: "billing")
    }

    var isPaymentMethodOptionsSetupFutureUsageSet: Bool {
        return !setupFutureUsageForPaymentMethodType.isEmpty
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

    /// Returns the expectedAmount if in `payment` mode, `nil` if in `setup` mode, and asserts
    /// if in `subscription` or `unknown` mode.
    func expectedAmount() -> Int? {
        switch mode {
        case .payment:
            guard let total = total?.total.minorUnitsAmount else {
                stpAssertionFailure("Missing expected amount from checkout session")
                return nil
            }
            return total
        case .setup:
            return nil
        case .unknown, .subscription:
            stpAssertionFailure("Unknown and subscription modes are not currently supported with checkout sessions")
            return nil
        }
    }

    func merchantWillSavePaymentMethod(_ paymentMethodType: STPPaymentMethodType) -> Bool {
        guard customerId != nil else {
            return false
        }

        switch mode {
        case .setup:
            return true
        case .payment:
            guard let setupFutureUsage = setupFutureUsage(for: paymentMethodType) else {
                return false
            }
            return setupFutureUsage != "none"
        case .subscription, .unknown:
            stpAssertionFailure("Unknown and subscription modes are not currently supported with checkout sessions")
            return false
        }
    }

    func setupFutureUsage(for paymentMethodType: STPPaymentMethodType) -> String? {
        let perPaymentMethodSetupFutureUsage = setupFutureUsageForPaymentMethodType[paymentMethodType.identifier]
        if let perPaymentMethodSetupFutureUsage {
            return perPaymentMethodSetupFutureUsage
        }

        return setupFutureUsage
    }

    func makeCopyOverriding(
        billingAddress: Checkout.ContactAddress? = nil,
        shippingAddress: Checkout.ContactAddress? = nil
    ) -> Self {
        return Self(
            id: id,
            billingAddress: billingAddress ?? self.billingAddress,
            businessName: businessName,
            currency: currency,
            currencyOptions: currencyOptions,
            discountAmounts: discountAmounts,
            email: email,
            lineItems: lineItems,
            livemode: livemode,
            minorUnitsAmountDivisor: minorUnitsAmountDivisor,
            savedPaymentMethods: savedPaymentMethods,
            shipping: shipping,
            shippingAddress: shippingAddress ?? self.shippingAddress,
            shippingOptions: shippingOptions,
            status: status,
            tax: tax,
            total: total,
            mode: mode,
            paymentMethodOptions: paymentMethodOptions,
            customer: customer,
            savedPaymentMethodsOfferSave: savedPaymentMethodsOfferSave,
            setupFutureUsage: setupFutureUsage,
            setupFutureUsageForPaymentMethodType: setupFutureUsageForPaymentMethodType,
            allowedShippingCountries: allowedShippingCountries,
            localizedPricesMetas: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta,
            requiresBillingAddress: requiresBillingAddress,
            adaptivePricingActive: adaptivePricingActive,
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource,
            elementsSession: elementsSession
        )
    }
}

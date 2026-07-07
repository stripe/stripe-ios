//
//  STPCheckoutSessionAPIResponse+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation
@_spi(STP) import StripePayments

extension STPCheckoutSessionAPIResponse {
    var minorUnitsAmountDivisor: Int? {
        guard let currency else { return nil }
        let oneMinorUnitInMajor = NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency)
        return Int(truncating: NSDecimalNumber(value: 1).dividing(by: oneMinorUnitInMajor))
    }

    /// Builds a public, read-only ``Checkout.Session`` snapshot from this API response object.
    func makePublicSession() -> Checkout.Session {
        return Checkout.Session(
            id: id,
            billingAddress: billingAddress,
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
            shippingAddress: shippingAddress,
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

// MARK: - Mode parsing

extension Checkout.Mode {
    static func mode(from string: String) -> Checkout.Mode {
        switch string.lowercased() {
        case "payment": return .payment
        case "setup": return .setup
        case "subscription": return .subscription
        default: return .unknown
        }
    }
}

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

    var isPaymentMethodOptionsSetupFutureUsageSet: Bool {
        return !setupFutureUsageForPaymentMethodType.isEmpty
    }

    /// Whether this Checkout Session computes automatic tax from the billing address.
    var collectsTaxFromBillingAddress: Bool {
        return shouldSendTaxRegion(for: "billing")
    }

    /// `true` for a setup-style session (no payment due now). Sessions can have a present-but-zero
    /// `total` even when setup-only, so this checks `paymentStatus` rather than `total != nil`.
    var isSetupOnly: Bool {
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

    /// The amount to *display* to the customer for payment-style sessions (payment, subscription,
    /// unified with priced items). Setup-style sessions (setup, unified setup-only) return `nil`,
    /// even if `total` is present (the real API can return a present-but-zero `total` on
    /// setup-only sessions).
    ///
    /// This governs UI decisions (e.g. whether Apple Pay shows a `.final` charge amount or a
    /// `.pending` placeholder) — it is deliberately *not* used for the confirm endpoint's
    /// `expected_amount` parameter, which has a different contract. Use ``expectedAmountForConfirm()``
    /// for that.
    func displayAmount() -> Int? {
        guard !isSetupOnly else { return nil }
        guard let amount = total?.total.minorUnitsAmount else {
            stpAssertionFailure("Missing expected amount from a payment-style checkout session")
            return nil
        }
        return amount
    }

    /// The `expected_amount` to send when confirming a payment-style session. The confirm
    /// endpoint does not accept this parameter for setup-only sessions.
    func expectedAmountForConfirm() -> Int? {
        guard !isSetupOnly else {
            return nil
        }
        guard let amountDue else {
            stpAssertionFailure("Missing expected amount from checkout session")
            let errorAnalytic = ErrorAnalytic(
                event: .unexpectedPaymentSheetConfirmationError,
                error: PaymentSheetError.unknown(debugDescription: "Missing total_summary.due when confirming a checkout session")
            )
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            return nil
        }
        return amountDue
    }

    func merchantWillSavePaymentMethod(_ paymentMethodType: STPPaymentMethodType) -> Bool {
        guard customerId != nil else {
            return false
        }

        // Setup-only sessions always save by definition.
        guard !isSetupOnly else {
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
        shippingAddress: SessionFieldUpdate<Checkout.ContactAddress> = .keepOldValue,
        paymentOption: SessionFieldUpdate<Checkout.Session.PaymentOptionDisplayData> = .keepOldValue
    ) -> Self {
        return Self(
            id: id,
            businessName: businessName,
            currency: currency,
            currencyOptions: currencyOptions,
            discountAmounts: discountAmounts,
            email: email,
            lineItems: lineItems,
            livemode: livemode,
            minorUnitsAmountDivisor: minorUnitsAmountDivisor,
            paymentOption: paymentOption.resolved(currentValue: self.paymentOption),
            savedPaymentMethods: savedPaymentMethods,
            shipping: shipping,
            shippingAddress: shippingAddress.resolved(currentValue: self.shippingAddress),
            shippingOptions: shippingOptions,
            status: status,
            tax: tax,
            total: total,
            paymentStatus: paymentStatus,
            amountDue: amountDue,
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

//
//  PaymentPagesAPIResponse+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation
@_spi(STP) import StripePayments

extension PaymentPagesAPIResponse {
    /// Builds a public, read-only ``Checkout.Session`` snapshot from this API response object.
    func makePublicSession() -> Checkout.Session {
        let publicPaymentStatus = Checkout.PaymentStatus.paymentStatus(from: paymentStatus)
        let publicStatus = status.map {
            Checkout.Status(
                type: Checkout.StatusType.statusType(from: $0),
                paymentStatus: publicPaymentStatus
            )
        }
        let publicDiscountAmounts = Self.makeDiscountAmounts(
            from: recurringDetails?.totalDiscountAmounts ?? [],
            currency: currency
        )
        let publicTaxAmounts = Self.makeTaxAmounts(
            from: recurringDetails?.totalTaxAmounts ?? [],
            currency: currency
        )
        let publicLineItems = Self.makeLineItems(from: checkoutItems, defaultCurrency: currency)
        let publicShippingOptions = Self.makeShippingOptions(from: shippingOptions, defaultCurrency: currency)
        let publicShipping = Self.makeSelectedShipping(
            from: shippingRate,
            shippingOptions: publicShippingOptions,
            shippingTaxAmounts: shippingTaxAmounts,
            currency: currency
        )
        let publicTotal = Self.makeTotal(
            from: totalSummary,
            currency: currency,
            taxAmounts: publicTaxAmounts,
            discountAmounts: publicDiscountAmounts,
            shippingRate: shippingRate
        )
        let publicTax = Checkout.Tax(
            status: Self.makeTaxStatus(taxMeta: taxMeta, taxContext: taxContext),
            taxAmounts: publicTaxAmounts.isEmpty ? nil : publicTaxAmounts
        )
        let localizedPricesMetas = STPCheckoutSessionLocalizedPriceMeta.localizedPricesMetas(from: allResponseFields)
        let exchangeRateMeta = STPCheckoutSessionExchangeRateMeta.decodedObject(from: allResponseFields)
        let automaticTaxEnabled = taxContext?.automaticTaxEnabled ?? false
        let automaticTaxAddressSource = Self.makeAutomaticTaxAddressSource(
            from: taxContext?.automaticTaxAddressSource
        )
        let elementsSessionValue = elementsSession.value
        if automaticTaxEnabled && automaticTaxAddressSource == "billing" {
            elementsSessionValue.disableLinkForAutomaticTaxBilling = true
        }

        return Checkout.Session(
            id: sessionId,
            businessName: elementsSession.businessName,
            currency: currency,
            currencyOptions: Self.makeCurrencyOptions(
                from: localizedPricesMetas,
                exchangeRateMeta: exchangeRateMeta
            ),
            discountAmounts: publicDiscountAmounts,
            email: customerEmail ?? customer?.email,
            lineItems: publicLineItems,
            livemode: livemode,
            minorUnitsAmountDivisor: Self.makeMinorUnitsAmountDivisor(currency: currency),
            paymentOption: local_paymentOption,
            savedPaymentMethods: customer?.paymentMethods ?? [],
            shipping: publicShipping,
            shippingAddress: local_shippingAddress,
            shippingOptions: publicShippingOptions,
            status: publicStatus,
            tax: publicTax,
            total: publicTotal,
            paymentStatus: publicPaymentStatus,
            paymentMethodOptions: paymentMethodOptions,
            customer: customer,
            savedPaymentMethodsOfferSave: Self.makeSavedPaymentMethodsOfferSave(from: savedPaymentMethodsOfferSave),
            setupFutureUsage: setupFutureUsage,
            setupFutureUsageForPaymentMethodType: setupFutureUsageForPaymentMethodType ?? [:],
            allowedShippingCountries: shippingAddressCollection?.allowedCountries,
            localizedPricesMetas: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta,
            adaptivePricingActive: developerToolContext?.adaptivePricing?.active ?? false,
            billingAddressCollection: billingAddressCollection.flatMap(Checkout.Session.BillingAddressCollection.init(rawValue:)) ?? .automatic,
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource,
            elementsSession: elementsSessionValue
        )
    }
}

// MARK: - Public model conversion

extension PaymentPagesAPIResponse {
    static func makeAmount(_ minorUnitsAmount: Int, currency: String?) -> Checkout.Amount {
        let formatted: String
        if let currency, !currency.isEmpty {
            formatted = String.localizedAmountDisplayString(for: minorUnitsAmount, currency: currency)
        } else {
            formatted = "\(minorUnitsAmount)"
        }
        return Checkout.Amount(amount: formatted, minorUnitsAmount: minorUnitsAmount)
    }

    private static func makeMinorUnitsAmountDivisor(currency: String?) -> Int? {
        guard let currency else { return nil }
        let oneMinorUnitInMajor = NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency)
        return Int(truncating: NSDecimalNumber(value: 1).dividing(by: oneMinorUnitInMajor))
    }

    private static func makeLineItems(
        from checkoutItems: [CheckoutItem],
        defaultCurrency: String?
    ) -> [Checkout.LineItem] {
        checkoutItems.compactMap { item in
            guard item.type == "one_time_price_item",
                  let id = item.key,
                  let oneTimePriceItem = item.oneTimePriceItem,
                  let quantity = oneTimePriceItem.quantity,
                  let price = oneTimePriceItem.price,
                  let product = price.product,
                  let name = product.name else {
                return nil
            }
            let currency = price.currency ?? defaultCurrency
            let unitAmount = price.unitAmount.map { makeAmount($0, currency: currency) }
            let unitAmountDecimal: Checkout.DecimalAmount? = price.unitAmountDecimal.flatMap { value in
                guard let decimal = Decimal(string: value) else { return nil }
                let intValue = NSDecimalNumber(decimal: decimal).intValue
                return Checkout.DecimalAmount(
                    amount: makeAmount(intValue, currency: currency).amount,
                    minorUnitsAmount: decimal
                )
            }
            return Checkout.LineItem(
                id: id,
                name: name,
                description: product.description,
                images: product.images ?? [],
                quantity: quantity,
                unitAmount: unitAmount,
                unitAmountDecimal: unitAmountDecimal,
                subtotal: nil,
                discount: nil,
                taxExclusive: nil,
                taxInclusive: nil,
                total: nil,
                discountAmounts: [],
                taxAmounts: [],
                adjustableQuantity: nil
            )
        }
    }

    private static func makeDiscountAmounts(
        from discountAmounts: [DiscountAmount],
        currency: String?
    ) -> [Checkout.DiscountAmount] {
        discountAmounts.compactMap { discount in
            guard let amount = discount.amount, amount > 0 else { return nil }
            return Checkout.DiscountAmount(
                amount: makeAmount(amount, currency: currency),
                displayName: discount.displayName
                    ?? discount.coupon?.name
                    ?? discount.coupon?.id
                    ?? String.Localized.discount,
                promotionCode: discount.promotionCode?.code
            )
        }
    }

    /// Test helper retained for focused discount conversion tests.
    static func parseDiscountAmounts(
        from dict: [AnyHashable: Any],
        currency: String?
    ) -> [Checkout.DiscountAmount] {
        let recurringDetails = (dict["recurring_details"] as? [AnyHashable: Any]).map(RecurringDetails.init)
        return makeDiscountAmounts(
            from: recurringDetails?.totalDiscountAmounts ?? [],
            currency: currency
        )
    }

    private static func makeTaxAmounts(
        from taxAmounts: [TaxAmount],
        currency: String?
    ) -> [Checkout.TaxAmount] {
        taxAmounts.compactMap { taxAmount in
            guard let amount = taxAmount.amount,
                  let inclusive = taxAmount.inclusive else { return nil }
            return Checkout.TaxAmount(
                amount: makeAmount(amount, currency: currency),
                inclusive: inclusive,
                displayName: taxAmount.displayName ?? taxAmount.taxRate?.displayName ?? String.Localized.tax
            )
        }
    }

    private static func makeShippingOptions(
        from shippingOptions: [ShippingOption],
        defaultCurrency: String?
    ) -> [Checkout.ShippingOption] {
        shippingOptions.compactMap { option in
            makeShippingOption(from: option.shippingRate, defaultCurrency: defaultCurrency)
        }
    }

    private static func makeShippingOption(
        from shippingRate: ShippingRate?,
        defaultCurrency: String?
    ) -> Checkout.ShippingOption? {
        guard let shippingRate,
              let id = shippingRate.id,
              let amount = shippingRate.amount else { return nil }
        let currency = shippingRate.currency ?? defaultCurrency ?? "usd"
        return Checkout.ShippingOption(
            id: id,
            displayName: shippingRate.displayName,
            amount: makeAmount(amount, currency: currency),
            currency: currency,
            deliveryEstimate: makeDeliveryEstimate(from: shippingRate.deliveryEstimate)
        )
    }

    private static func makeSelectedShipping(
        from shippingRate: ShippingRate?,
        shippingOptions: [Checkout.ShippingOption],
        shippingTaxAmounts: [TaxAmount]?,
        currency: String?
    ) -> Checkout.SelectedShipping? {
        guard let shippingRate,
              let id = shippingRate.id,
              let option = shippingOptions.first(where: { $0.id == id })
                ?? makeShippingOption(from: shippingRate, defaultCurrency: currency) else {
            return nil
        }
        return Checkout.SelectedShipping(
            shippingOption: option,
            taxAmounts: makeTaxAmounts(from: shippingTaxAmounts ?? [], currency: currency)
        )
    }

    private static func makeDeliveryEstimate(from estimate: DeliveryEstimate?) -> Checkout.DeliveryEstimate? {
        guard let estimate else { return nil }
        let minimum = makeDeliveryBound(from: estimate.minimum)
        let maximum = makeDeliveryBound(from: estimate.maximum)
        guard minimum != nil || maximum != nil else { return nil }
        return Checkout.DeliveryEstimate(minimum: minimum, maximum: maximum)
    }

    private static func makeDeliveryBound(from bound: DeliveryBound?) -> Checkout.DeliveryEstimate.Bound? {
        guard let bound, let value = bound.value else { return nil }
        let unit: Checkout.DeliveryEstimate.Bound.Unit
        switch bound.unit?.lowercased() {
        case "hour": unit = .hour
        case "day": unit = .day
        case "business_day": unit = .businessDay
        case "week": unit = .week
        case "month": unit = .month
        default: unit = .unknown
        }
        return Checkout.DeliveryEstimate.Bound(unit: unit, value: value)
    }

    private static func makeTotal(
        from totalSummary: TotalSummary?,
        currency: String?,
        taxAmounts: [Checkout.TaxAmount],
        discountAmounts: [Checkout.DiscountAmount],
        shippingRate: ShippingRate?
    ) -> Checkout.Total? {
        guard let totalSummary,
              let subtotal = totalSummary.subtotal,
              let total = totalSummary.total else { return nil }
        let taxInclusive = taxAmounts.filter(\.inclusive).reduce(0) { $0 + $1.amount.minorUnitsAmount }
        let taxExclusive = taxAmounts.filter { !$0.inclusive }.reduce(0) { $0 + $1.amount.minorUnitsAmount }
        let discount = discountAmounts.reduce(0) { $0 + $1.amount.minorUnitsAmount }
        return Checkout.Total(
            subtotal: makeAmount(subtotal, currency: currency),
            taxExclusive: makeAmount(taxExclusive, currency: currency),
            taxInclusive: makeAmount(taxInclusive, currency: currency),
            shippingRate: makeAmount(shippingRate?.amount ?? 0, currency: currency),
            discount: makeAmount(discount, currency: currency),
            total: makeAmount(total, currency: currency),
            appliedBalance: makeAmount(totalSummary.appliedBalance ?? 0, currency: currency),
            balanceAppliedToNextInvoice: totalSummary.balanceAppliedToNextInvoice ?? false
        )
    }

    private static func makeTaxStatus(
        taxMeta: TaxMeta?,
        taxContext: TaxContext?
    ) -> Checkout.TaxStatus {
        guard taxMeta?.computationType == "automatic" else { return .ready }
        switch taxMeta?.status {
        case "complete":
            return .ready
        case "requires_location_inputs":
            return taxContext?.automaticTaxAddressSource == "session.shipping"
                ? .requiresShippingAddress
                : .requiresBillingAddress
        case "failed":
            return .unknown
        default:
            return .ready
        }
    }

    private static func makeAutomaticTaxAddressSource(from value: String?) -> String? {
        guard let value else { return nil }
        return value.hasPrefix("session.") ? String(value.dropFirst("session.".count)) : value
    }

    private static func makeSavedPaymentMethodsOfferSave(
        from value: SavedPaymentMethodsOfferSave?
    ) -> STPCheckoutSessionSavedPaymentMethodsOfferSave? {
        guard let value else { return nil }
        return STPCheckoutSessionSavedPaymentMethodsOfferSave(
            enabled: value.enabled ?? false,
            status: value.status == "accepted" ? .accepted : .notAccepted
        )
    }

    static func makeCurrencyOptions(
        from metas: [STPCheckoutSessionLocalizedPriceMeta],
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?
    ) -> [Checkout.CurrencyOption] {
        metas.map { meta in
            let conversion: Checkout.CurrencyConversion? = exchangeRateMeta.flatMap { rate in
                guard meta.currency.lowercased() == rate.localizedCurrency.lowercased() else { return nil }
                return Checkout.CurrencyConversion(fxRate: rate.exchangeRate, sourceCurrency: rate.sellCurrency)
            }
            return Checkout.CurrencyOption(
                amount: makeAmount(meta.total, currency: meta.currency),
                currency: meta.currency,
                currencyConversion: conversion
            )
        }
    }
}

extension Checkout.StatusType {
    static func statusType(from string: String) -> Checkout.StatusType {
        switch string.lowercased() {
        case "open": return .open
        case "complete": return .complete
        case "expired": return .expired
        default: return .unknown
        }
    }
}

extension Checkout.PaymentStatus {
    static func paymentStatus(from string: String) -> Checkout.PaymentStatus {
        switch string.lowercased() {
        case "paid": return .paid
        case "unpaid": return .unpaid
        case "no_payment_required": return .noPaymentRequired
        default: return .unknown
        }
    }
}

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
        let localizedPricesMetas = Self.makeLocalizedPricesMetas(from: adaptivePricingInfo)
        let exchangeRateMeta = Self.makeExchangeRateMeta(from: adaptivePricingInfo)
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
            paymentOption: nil,
            shippingAddress: nil,
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

    private static func makeLocalizedPricesMetas(
        from adaptivePricingInfo: AdaptivePricingInfo?
    ) -> [STPCheckoutSessionLocalizedPriceMeta] {
        guard let adaptivePricingInfo,
              let localCurrencyOptions = adaptivePricingInfo.localCurrencyOptions else {
            return []
        }
        var metas: [STPCheckoutSessionLocalizedPriceMeta] = localCurrencyOptions.compactMap { option in
            guard let currency = option.currency,
                  let amount = option.amount else {
                return nil
            }
            // Local currency options no longer include a dedicated ID, so currency is stable.
            return STPCheckoutSessionLocalizedPriceMeta(
                id: currency,
                currency: currency,
                total: amount
            )
        }

        // Always include the integration currency as an option.
        if let integrationCurrency = adaptivePricingInfo.integrationCurrency,
           let integrationAmount = adaptivePricingInfo.integrationAmount,
           !metas.contains(where: { $0.currency.lowercased() == integrationCurrency.lowercased() }) {
            metas.append(
                STPCheckoutSessionLocalizedPriceMeta(
                    id: integrationCurrency,
                    currency: integrationCurrency,
                    total: integrationAmount
                )
            )
        }

        return metas
    }

    private static func makeExchangeRateMeta(
        from adaptivePricingInfo: AdaptivePricingInfo?
    ) -> STPCheckoutSessionExchangeRateMeta? {
        guard let adaptivePricingInfo,
              let activePresentmentCurrency = adaptivePricingInfo.activePresentmentCurrency,
              let integrationCurrency = adaptivePricingInfo.integrationCurrency,
              let localCurrencyOptions = adaptivePricingInfo.localCurrencyOptions,
              let selectedOption = localCurrencyOptions.first(where: {
                  $0.currency?.lowercased() == activePresentmentCurrency.lowercased()
              }) ?? localCurrencyOptions.first,
              let localizedCurrency = selectedOption.currency,
              let exchangeRate = selectedOption.presentmentExchangeRate,
              let conversionMarkupBps = selectedOption.conversionMarkupBps else {
            return nil
        }

        return STPCheckoutSessionExchangeRateMeta(
            id: "\(integrationCurrency.lowercased())_to_\(localizedCurrency.lowercased())",
            buyCurrency: localizedCurrency,
            sellCurrency: integrationCurrency,
            exchangeRate: exchangeRate,
            integrationCurrency: integrationCurrency,
            localizedCurrency: localizedCurrency,
            conversionMarkupBps: conversionMarkupBps
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

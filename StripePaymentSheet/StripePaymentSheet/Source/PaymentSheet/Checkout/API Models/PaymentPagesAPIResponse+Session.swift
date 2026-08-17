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
        let publicStatus = Checkout.Status(
            type: Checkout.StatusType.statusType(from: status),
            paymentStatus: publicPaymentStatus
        )
        let elementsSessionValue = elementsSession.value
        let publicDiscountAmounts = Self.makeDiscountAmounts(
            from: recurringDetails?.totalDiscountAmounts ?? [],
            currency: currency
        )
        let publicTaxAmounts = Self.makeTaxAmounts(
            from: recurringDetails?.totalTaxAmounts ?? [],
            currency: currency
        )
        let publicOrderSummaryItems = Self.makeOrderSummaryItems(
            from: checkoutItems,
            defaultCurrency: currency,
            locale: .autoupdatingCurrent
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
        let localizedPricesMetas = Self.makeLocalizedPricesMetas(from: adaptivePricingInfo)
        let exchangeRateMeta = Self.makeExchangeRateMeta(from: adaptivePricingInfo)
        let automaticTaxEnabled = taxContext?.automaticTaxEnabled ?? false
        let automaticTaxAddressSource = Self.makeAutomaticTaxAddressSource(
            from: taxContext?.automaticTaxAddressSource
        )
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
            orderSummaryItems: publicOrderSummaryItems,
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
    static func makeAmount(_ minorUnitsAmount: Int, currency: String) -> Checkout.Amount {
        let formatted = String.localizedAmountDisplayString(for: minorUnitsAmount, currency: currency)
        return Checkout.Amount(amount: formatted, minorUnitsAmount: minorUnitsAmount)
    }

    // TODO: Have Payment Pages return Session.Amount-shaped values so clients don't duplicate
    // minor-to-major conversion and locale-aware currency formatting.
    private static func makeSessionAmount(
        _ minorUnitsAmount: Double,
        currency: String,
        locale: Locale,
        supportsSubcentPrecision: Bool = false
    ) -> Checkout.Session.Amount {
        let minorUnitValueInMajorUnits = NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency) // e.g. USD: 0.01
        let decimalizedAmount = NSDecimalNumber(value: minorUnitsAmount).multiplying(by: minorUnitValueInMajorUnits) // e.g. 49,900 × 0.01 = 499.00
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.locale = locale
        formatter.currencyCode = currency
        if supportsSubcentPrecision {
            // Match EwCS and preserve the API's supported 12 decimal places beyond the
            // currency's normal precision (e.g. up to 14 fraction digits for USD).
            formatter.maximumFractionDigits += 12
        }
        let formatted = formatter.string(from: decimalizedAmount)
            ?? "\(formatter.currencySymbol ?? "")\(decimalizedAmount)"
        return Checkout.Session.Amount(
            amount: formatted,
            minorUnitsAmount: minorUnitsAmount
        )
    }

    private static func makeMinorUnitsAmountDivisor(currency: String) -> Int {
        let oneMinorUnitInMajor = NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency)
        return Int(truncating: NSDecimalNumber(value: 1).dividing(by: oneMinorUnitInMajor))
    }

    private static func makeOrderSummaryItems(
        from checkoutItems: [CheckoutItem],
        defaultCurrency: String,
        locale: Locale
    ) -> [Checkout.Session.OrderSummaryItem] {
        checkoutItems.map { item in
            let oneTimePrice = item.oneTimePrice
            let publicItems: [Checkout.Session.OrderSummaryItem.OneTimePrice.Item] =
                oneTimePrice.items.map { item in
                    let price = item.price
                    let product = price.product
                    let currency = price.currency
                    let unitAmount = item.unitAmount ?? price.unitAmount ?? 0
                    let adjustableQuantity: Checkout.Session.AdjustableQuantity?
                    if let rawAdjustableQuantity = item.adjustableQuantity,
                       rawAdjustableQuantity.enabled {
                        // TODO: Payment Pages currently models these bounds as optional, although enabled
                        // adjustable quantity is normally populated with server defaults of 0 and 99.
                        // Once the response contract requires both bounds when enabled, reject missing
                        // values during decoding and remove these client-side fallbacks.
                        adjustableQuantity = Checkout.Session.AdjustableQuantity(
                            enabled: true,
                            maximum: rawAdjustableQuantity.maximum ?? 99,
                            minimum: rawAdjustableQuantity.minimum ?? 0
                        )
                    } else {
                        adjustableQuantity = nil
                    }
                    return Checkout.Session.OrderSummaryItem.OneTimePrice.Item(
                        key: price.id,
                        displayName: product.name,
                        images: product.images,
                        unitAmount: makeSessionAmount(
                            Double(unitAmount),
                            currency: currency,
                            locale: locale
                        ),
                        unitAmountDecimal: item.unitAmountDecimal.map {
                            makeSessionAmount(
                                $0,
                                currency: currency,
                                locale: locale,
                                supportsSubcentPrecision: true
                            )
                        },
                        unitLabel: item.unitLabel,
                        quantity: item.quantity,
                        adjustableQuantity: adjustableQuantity
                    )
                }

            let taxAmounts = oneTimePrice.items.flatMap(\.taxAmounts).map {
                makeSessionTaxAmount(from: $0, currency: defaultCurrency, locale: locale)
            }
            let taxInclusive = oneTimePrice.items.reduce(0) { $0 + $1.taxInclusive }
            let taxExclusive = oneTimePrice.items.reduce(0) { $0 + $1.taxExclusive }
            let amountDetails = Checkout.Session.OrderSummaryItem.OneTimePrice.AmountDetails(
                total: makeSessionAmount(Double(oneTimePrice.total), currency: defaultCurrency, locale: locale),
                subtotal: makeSessionAmount(
                    Double(oneTimePrice.subtotal),
                    currency: defaultCurrency,
                    locale: locale
                ),
                taxAmounts: taxAmounts.isEmpty ? nil : taxAmounts,
                discount: makeSessionAmount(0, currency: defaultCurrency, locale: locale),
                taxInclusive: makeSessionAmount(
                    Double(taxInclusive),
                    currency: defaultCurrency,
                    locale: locale
                ),
                taxExclusive: makeSessionAmount(
                    Double(taxExclusive),
                    currency: defaultCurrency,
                    locale: locale
                )
            )
            return .oneTimePrice(
                Checkout.Session.OrderSummaryItem.OneTimePrice(
                    key: item.key,
                    description: nil,
                    items: publicItems,
                    amountDetails: amountDetails
                )
            )
        }
    }

    private static func makeSessionTaxAmount(
        from taxAmount: TaxAmount,
        currency: String,
        locale: Locale
    ) -> Checkout.Session.TaxAmount {
        let publicAmount = makeSessionAmount(Double(taxAmount.amount), currency: currency, locale: locale)
        return Checkout.Session.TaxAmount(
            amount: publicAmount.amount,
            minorUnitsAmount: publicAmount.minorUnitsAmount,
            inclusive: taxAmount.inclusive,
            displayName: taxAmount.taxRate.displayName,
            percentage: taxAmount.taxRate.rateType == "flat_amount"
                ? nil
                : taxAmount.taxRate.percentage
        )
    }

    private static func makeDiscountAmounts(
        from discountAmounts: [DiscountAmount],
        currency: String
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
        currency: String
    ) -> [Checkout.TaxAmount] {
        taxAmounts.map { taxAmount in
            return Checkout.TaxAmount(
                amount: makeAmount(taxAmount.amount, currency: currency),
                inclusive: taxAmount.inclusive,
                displayName: taxAmount.taxRate.displayName
            )
        }
    }

    private static func makeTotal(
        from totalSummary: TotalSummary?,
        currency: String,
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

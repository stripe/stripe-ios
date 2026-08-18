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
        let elementsSessionValue = elementsSession.value
        let publicDiscountAmounts = Self.makeDiscountAmounts(
            from: recurringDetails?.totalDiscountAmounts ?? [],
            currency: currency
        )
        // TODO: Have Payment Pages return session-level tax amounts directly. `recurring_details`
        // is an odd source for one-time-price modeless Checkout, and clients shouldn't need to
        // derive this aggregate from recurring-specific response models.
        let publicTaxAmounts = recurringDetails?.totalTaxAmounts?.map {
            Self.makeSessionTaxAmount(from: $0, currency: currency, locale: .autoupdatingCurrent)
        }
        let publicOrderSummaryItems = Self.makeOrderSummaryItems(
            from: checkoutItems,
            defaultCurrency: currency,
            locale: .autoupdatingCurrent
        )
        let publicTotals = Self.makeTotals(from: checkoutItems, currency: currency)
        let publicTax = Self.makeTax(taxMeta: taxMeta, taxContext: taxContext)
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
            status: status,
            tax: publicTax,
            taxAmounts: publicTaxAmounts,
            totals: publicTotals,
            paymentStatus: paymentStatus,
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
    static func makeAmount(_ minorUnitsAmount: Int, currency: String) -> Checkout.Session.Amount {
        return makeAmount(Double(minorUnitsAmount), currency: currency, locale: .autoupdatingCurrent)
    }

    // TODO: Have Payment Pages return Session.Amount-shaped values so clients don't duplicate
    // minor-to-major conversion and locale-aware currency formatting.
    private static func makeAmount(
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
                        key: item.innerItemKey,
                        displayName: product.name,
                        images: product.images,
                        unitAmount: makeAmount(
                            Double(unitAmount),
                            currency: currency,
                            locale: locale
                        ),
                        unitAmountDecimal: item.unitAmountDecimal.map {
                            makeAmount(
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
                total: makeAmount(Double(oneTimePrice.total), currency: defaultCurrency, locale: locale),
                subtotal: makeAmount(
                    Double(oneTimePrice.subtotal),
                    currency: defaultCurrency,
                    locale: locale
                ),
                taxAmounts: taxAmounts.isEmpty ? nil : taxAmounts,
                discount: makeAmount(0, currency: defaultCurrency, locale: locale),
                taxInclusive: makeAmount(
                    Double(taxInclusive),
                    currency: defaultCurrency,
                    locale: locale
                ),
                taxExclusive: makeAmount(
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
        let publicAmount = makeAmount(Double(taxAmount.amount), currency: currency, locale: locale)
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
    ) -> [Checkout.Session.DiscountAmount] {
        discountAmounts.compactMap { discount in
            guard let amount = discount.amount, amount > 0 else { return nil }
            let publicAmount = makeAmount(amount, currency: currency)
            return Checkout.Session.DiscountAmount(
                amount: publicAmount.amount,
                minorUnitsAmount: publicAmount.minorUnitsAmount,
                displayName: discount.displayName
                    ?? discount.coupon?.name
                    ?? discount.coupon?.id
                    ?? String.Localized.discount,
                promotionCode: discount.promotionCode?.code,
                percentOff: discount.coupon?.percentOff
            )
        }
    }

    private static func makeTotals(
        from checkoutItems: [CheckoutItem],
        currency: String
    ) -> Checkout.Session.Totals {
        var subtotal = 0
        var taxExclusive = 0
        var taxInclusive = 0
        var total = 0
        for checkoutItem in checkoutItems {
            let oneTimePrice = checkoutItem.oneTimePrice
            subtotal += oneTimePrice.subtotal
            taxExclusive += oneTimePrice.items.reduce(0) { $0 + $1.taxExclusive }
            taxInclusive += oneTimePrice.items.reduce(0) { $0 + $1.taxInclusive }
            total += oneTimePrice.total
        }
        return Checkout.Session.Totals(
            subtotal: makeAmount(subtotal, currency: currency),
            taxExclusive: makeAmount(taxExclusive, currency: currency),
            taxInclusive: makeAmount(taxInclusive, currency: currency),
            // Discounts are not currently supported in unified mode.
            discount: makeAmount(0, currency: currency),
            total: makeAmount(total, currency: currency)
        )
    }

    private static func makeTax(
        taxMeta: TaxMeta?,
        taxContext: TaxContext?
    ) -> Checkout.Session.Tax? {
        // TODO: Decode computation_type as an enum. Longer term, the backend should return
        // the public tax status directly instead of requiring each client to derive it.
        // Until then, match EwCS by treating every non-automatic computation type as ready.
        guard let computationType = taxMeta?.computationType else { return nil }
        guard computationType == "automatic" else {
            return Checkout.Session.Tax(status: .ready)
        }
        switch taxMeta?.status {
        case "complete":
            return Checkout.Session.Tax(status: .ready)
        case "requires_location_inputs":
            switch taxContext?.automaticTaxAddressSource {
            case "session.shipping":
                return Checkout.Session.Tax(status: .requiresShippingAddress)
            case "session.billing":
                return Checkout.Session.Tax(status: .requiresBillingAddress)
            default:
                return nil
            }
        default:
            return nil
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

extension Checkout.Session.Status {
    static func status(
        from string: String,
        paymentStatus: Checkout.Session.Status.PaymentStatus
    ) -> Checkout.Session.Status? {
        switch string.lowercased() {
        case "open": return .open
        case "complete": return .complete(paymentStatus)
        case "expired": return .expired
        default: return nil
        }
    }
}

extension Checkout.Session.Status.PaymentStatus {
    static func paymentStatus(from string: String) -> Checkout.Session.Status.PaymentStatus? {
        switch string.lowercased() {
        case "paid": return .paid
        case "unpaid": return .unpaid
        case "no_payment_required": return .noPaymentRequired
        default: return nil
        }
    }
}

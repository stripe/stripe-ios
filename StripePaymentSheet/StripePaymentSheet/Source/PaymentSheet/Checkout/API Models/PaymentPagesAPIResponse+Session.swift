//
//  PaymentPagesAPIResponse+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation
@_spi(STP) import StripePayments

extension PaymentPagesAPIResponse {
    /// Builds a public, read-only ``CheckoutController.Session`` snapshot from this API response object.
    func makePublicSession() -> CheckoutController.Session {
        let elementsSessionValue = elementsSession.value
        let publicDiscountAmounts = Self.makeDiscountAmounts(
            from: recurringDetails?.totalDiscountAmounts ?? [],
            currency: currency
        )
        // TODO: Have Payment Pages return session-level tax amounts directly. `recurring_details`
        // is an odd source for one-time-price modeless Checkout, and clients shouldn't need to
        // derive this aggregate from recurring-specific response models.
        let publicTaxAmounts = recurringDetails?.totalTaxAmounts.map {
            Self.makeSessionTaxAmount(from: $0, currency: currency, locale: .autoupdatingCurrent)
        }
        let publicOrderSummaryItems = Self.makeOrderSummaryItems(
            from: checkoutItems,
            locale: .autoupdatingCurrent
        )
        let publicTotals = Self.makeTotals(from: checkoutItems, currency: currency)
        let publicTax = Self.makeTax(taxMeta: taxMeta, taxContext: taxContext)
        let localizedPricesMetas = Self.makeLocalizedPricesMetas(from: adaptivePricingInfo)
        let exchangeRateMeta = Self.makeExchangeRateMeta(from: adaptivePricingInfo)
        // TODO: Read explicit integration and presentment currency fields from the mobile
        // translation layer once available instead of deriving them from the PP response shape.
        let presentmentDetails = adaptivePricingInfo.map {
            CheckoutController.Session.PresentmentDetails(presentmentCurrency: $0.activePresentmentCurrency)
        }
        let automaticTaxEnabled = taxContext?.automaticTaxEnabled ?? false
        let automaticTaxAddressSource = Self.makeAutomaticTaxAddressSource(
            from: taxContext?.automaticTaxAddressSource
        )
        if automaticTaxEnabled && automaticTaxAddressSource == "billing" {
            elementsSessionValue.disableLinkForAutomaticTaxBilling = true
        }

        return CheckoutController.Session(
            id: sessionId,
            businessName: elementsSession.businessName,
            currency: adaptivePricingInfo?.integrationCurrency ?? currency,
            presentmentDetails: presentmentDetails,
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
            allowedShippingCountries: shippingAddressCollection?.allowedCountries.map { $0.uppercased() },
            localizedPricesMetas: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta,
            adaptivePricingActive: adaptivePricingInfo != nil,
            billingAddressCollection: billingAddressCollection.flatMap(CheckoutController.Session.BillingAddressCollection.init(rawValue:)) ?? .automatic,
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource,
            merchantCountryCode: elementsSession.merchantCountryCode,
            elementsSession: elementsSessionValue
        )
    }
}

// MARK: - Public model conversion

extension PaymentPagesAPIResponse {
    static func makeAmount(_ minorUnitsAmount: Int, currency: String) -> CheckoutController.Session.Amount {
        return makeAmount(Double(minorUnitsAmount), currency: currency, locale: .autoupdatingCurrent)
    }

    // TODO: Have Payment Pages return Session.Amount-shaped values so clients don't duplicate
    // minor-to-major conversion and locale-aware currency formatting.
    private static func makeAmount(
        _ minorUnitsAmount: Double,
        currency: String,
        locale: Locale,
        supportsSubcentPrecision: Bool = false
    ) -> CheckoutController.Session.Amount {
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
        return CheckoutController.Session.Amount(
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
        locale: Locale
    ) -> [CheckoutController.Session.OrderSummaryItem] {
        checkoutItems.map { item in
            let oneTimePrice = item.oneTimePrice
            let publicItems: [CheckoutController.Session.OrderSummaryItem.OneTimePrice.Item] =
                oneTimePrice.items.map { item in
                    let price = item.price
                    let product = price.product
                    let currency = price.currency
                    let unitAmount = item.unitAmount ?? price.unitAmount ?? 0
                    let adjustableQuantity: CheckoutController.Session.AdjustableQuantity?
                    if let rawAdjustableQuantity = item.adjustableQuantity,
                       rawAdjustableQuantity.enabled,
                       let maximum = rawAdjustableQuantity.maximum,
                       let minimum = rawAdjustableQuantity.minimum {
                        adjustableQuantity = CheckoutController.Session.AdjustableQuantity(
                            enabled: true,
                            maximum: maximum,
                            minimum: minimum
                        )
                    } else {
                        adjustableQuantity = nil
                    }
                    let taxAmounts = item.taxAmounts.map {
                        makeSessionTaxAmount(from: $0, currency: currency, locale: locale)
                    }
                    let amountDetails = CheckoutController.Session.OrderSummaryItem.OneTimePrice.Item.AmountDetails(
                        total: makeAmount(Double(item.total), currency: currency, locale: locale),
                        subtotal: makeAmount(Double(item.subtotal), currency: currency, locale: locale),
                        taxAmounts: taxAmounts.isEmpty ? nil : taxAmounts,
                        taxInclusive: makeAmount(Double(item.taxInclusive), currency: currency, locale: locale),
                        taxExclusive: makeAmount(Double(item.taxExclusive), currency: currency, locale: locale)
                    )
                    return CheckoutController.Session.OrderSummaryItem.OneTimePrice.Item(
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
                        adjustableQuantity: adjustableQuantity,
                        amountDetails: amountDetails
                    )
                }

            return .oneTimePrice(
                CheckoutController.Session.OrderSummaryItem.OneTimePrice(
                    key: item.key,
                    description: nil,
                    items: publicItems
                )
            )
        }
    }

    private static func makeSessionTaxAmount(
        from taxAmount: TaxAmount,
        currency: String,
        locale: Locale
    ) -> CheckoutController.Session.TaxAmount {
        let publicAmount = makeAmount(Double(taxAmount.amount), currency: currency, locale: locale)
        return CheckoutController.Session.TaxAmount(
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
    ) -> [CheckoutController.Session.DiscountAmount] {
        discountAmounts.compactMap { discount in
            guard discount.amount > 0 else { return nil }
            let publicAmount = makeAmount(discount.amount, currency: currency)
            return CheckoutController.Session.DiscountAmount(
                amount: publicAmount.amount,
                minorUnitsAmount: publicAmount.minorUnitsAmount,
                displayName: discount.displayName
                    ?? discount.coupon.name
                    ?? discount.coupon.code,
                promotionCode: discount.promotionCode?.code,
                percentOff: discount.coupon.percentOff
            )
        }
    }

    private static func makeTotals(
        from checkoutItems: [CheckoutItem],
        currency: String
    ) -> CheckoutController.Session.Totals {
        var subtotal = 0
        var taxExclusive = 0
        var taxInclusive = 0
        var total = 0
        for checkoutItem in checkoutItems {
            for item in checkoutItem.oneTimePrice.items {
                subtotal += item.subtotal
                taxExclusive += item.taxExclusive
                taxInclusive += item.taxInclusive
                total += item.total
            }
        }
        return CheckoutController.Session.Totals(
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
    ) -> CheckoutController.Session.Tax? {
        // TODO: The backend should return the public tax status directly instead of requiring
        // each client to derive it. Until then, match EwCS by treating every non-automatic
        // computation type as ready.
        guard let taxMeta else { return nil }
        guard taxMeta.computationType == .automatic else {
            return CheckoutController.Session.Tax(status: .ready)
        }
        switch taxMeta.status?.value {
        case .complete:
            return CheckoutController.Session.Tax(status: .ready)
        case .requiresLocationInputs:
            switch taxContext?.automaticTaxAddressSource {
            case "session.shipping":
                return CheckoutController.Session.Tax(status: .requiresShippingAddress)
            case "session.billing":
                return CheckoutController.Session.Tax(status: .requiresBillingAddress)
            default:
                return nil
            }
        case .failed, nil:
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
            enabled: value.enabled,
            status: value.status == .accepted ? .accepted : .notAccepted
        )
    }

    private static func makeLocalizedPricesMetas(
        from adaptivePricingInfo: AdaptivePricingInfo?
    ) -> [STPCheckoutSessionLocalizedPriceMeta] {
        guard let adaptivePricingInfo else {
            return []
        }
        var metas: [STPCheckoutSessionLocalizedPriceMeta] = adaptivePricingInfo.localCurrencyOptions.map { option in
            return STPCheckoutSessionLocalizedPriceMeta(
                currency: option.currency,
                total: option.amount
            )
        }

        // Always include the integration currency as an option.
        if !metas.contains(where: {
            $0.currency.lowercased() == adaptivePricingInfo.integrationCurrency.lowercased()
        }) {
            metas.append(
                STPCheckoutSessionLocalizedPriceMeta(
                    currency: adaptivePricingInfo.integrationCurrency,
                    total: adaptivePricingInfo.integrationAmount
                )
            )
        }

        return metas
    }

    private static func makeExchangeRateMeta(
        from adaptivePricingInfo: AdaptivePricingInfo?
    ) -> CheckoutController.Session.ExchangeRateMeta? {
        guard let adaptivePricingInfo,
              let selectedOption = adaptivePricingInfo.localCurrencyOptions.first(where: {
                  $0.currency.lowercased() == adaptivePricingInfo.activePresentmentCurrency.lowercased()
              }) ?? adaptivePricingInfo.localCurrencyOptions.first else {
            return nil
        }

        return CheckoutController.Session.ExchangeRateMeta(
            exchangeRate: selectedOption.presentmentExchangeRate,
            integrationCurrency: adaptivePricingInfo.integrationCurrency,
            localizedCurrency: selectedOption.currency,
            conversionMarkupBps: selectedOption.conversionMarkupBps
        )
    }

}

extension CheckoutController.Session.Status {
    static func status(
        from string: String,
        paymentStatus: CheckoutController.Session.Status.PaymentStatus
    ) -> CheckoutController.Session.Status? {
        switch string.lowercased() {
        case "open": return .open
        case "complete": return .complete(paymentStatus)
        case "expired": return .expired
        default: return nil
        }
    }
}

extension CheckoutController.Session.Status.PaymentStatus {
    static func paymentStatus(from string: String) -> CheckoutController.Session.Status.PaymentStatus? {
        switch string.lowercased() {
        case "paid": return .paid
        case "unpaid": return .unpaid
        case "no_payment_required": return .noPaymentRequired
        default: return nil
        }
    }
}

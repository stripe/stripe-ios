//
//  CheckoutClientAPIResponse+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation
@_spi(STP) import StripePayments

// MARK: - Public model conversion

extension CheckoutClientAPIResponse {
    static func makeAmount(_ minorUnitsAmount: Int, currency: String) -> CheckoutController.Session.Amount {
        return makeAmount(Double(minorUnitsAmount), currency: currency, locale: .autoupdatingCurrent)
    }

    // TODO: Have CheckoutClient return Session.Amount-shaped values so clients don't duplicate
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

    static func makeMinorUnitsAmountDivisor(currency: String) -> Int {
        let oneMinorUnitInMajor = NSDecimalNumber.stp_decimalNumber(withAmount: 1, currency: currency)
        return Int(truncating: NSDecimalNumber(value: 1).dividing(by: oneMinorUnitInMajor))
    }

    static func makeOrderSummaryItems(
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

    static func makeSessionTaxAmount(
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

    static func makeTotals(
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

    static func makeTax(from automaticTax: AutomaticTax?) -> CheckoutController.Session.Tax? {
        guard let automaticTax else { return nil }
        switch automaticTax.status {
        case "ready":
            return .init(status: .ready)
        case "requires_address":
            switch automaticTax.addressSource {
            case "shipping": return .init(status: .requiresShippingAddress)
            case "billing": return .init(status: .requiresBillingAddress)
            default: return nil
            }
        default:
            return nil
        }
    }

    static func makeSessionTaxAmount(
        from taxAmount: TotalTaxAmount,
        currency: String,
        locale: Locale
    ) -> CheckoutController.Session.TaxAmount {
        let amount = makeAmount(Double(taxAmount.amount), currency: currency, locale: locale)
        return .init(
            amount: amount.amount,
            minorUnitsAmount: amount.minorUnitsAmount,
            inclusive: taxAmount.inclusive,
            displayName: taxAmount.displayName,
            percentage: taxAmount.percentage
        )
    }

    static func makeLocalizedPricesMetas(
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
            $0.currency.lowercased() == adaptivePricingInfo.integrationCurrencyOption.currency.lowercased()
        }) {
            metas.append(
                STPCheckoutSessionLocalizedPriceMeta(
                    currency: adaptivePricingInfo.integrationCurrencyOption.currency,
                    total: adaptivePricingInfo.integrationCurrencyOption.amount
                )
            )
        }

        return metas
    }

    static func makeExchangeRateMeta(
        from adaptivePricingInfo: AdaptivePricingInfo?,
        presentmentCurrency: String
    ) -> CheckoutController.Session.ExchangeRateMeta? {
        guard let adaptivePricingInfo,
            let selectedOption = adaptivePricingInfo.localCurrencyOptions.first(where: {
                $0.currency.lowercased() == presentmentCurrency.lowercased()
            }) ?? adaptivePricingInfo.localCurrencyOptions.first
        else {
            return nil
        }

        return CheckoutController.Session.ExchangeRateMeta(
            integrationCurrency: adaptivePricingInfo.integrationCurrencyOption.currency,
            localizedCurrency: selectedOption.currency,
            caption: selectedOption.disclosure?.caption,
            details: selectedOption.disclosure?.details,
            integrationCaption: adaptivePricingInfo.integrationCurrencyOption.disclosure?.caption
        )
    }

}

extension CheckoutController.Session {
    /// Builds a read-only session snapshot from server-backed and local state.
    init(
        apiResponse: CheckoutClientAPIResponse,
        localState: LocalState,
        configuration: CheckoutController.Configuration? = nil
    ) {
        let elementsSessionValue = apiResponse.elementsSession
        let publicTaxAmounts = apiResponse.totalSummary?.totalTaxAmounts?.map {
            CheckoutClientAPIResponse.makeSessionTaxAmount(
                from: $0,
                currency: apiResponse.presentmentCurrency,
                locale: .autoupdatingCurrent
            )
        }
        let publicOrderSummaryItems = CheckoutClientAPIResponse.makeOrderSummaryItems(
            from: apiResponse.items,
            locale: .autoupdatingCurrent
        )
        let publicTotals = CheckoutClientAPIResponse.makeTotals(
            from: apiResponse.items,
            currency: apiResponse.presentmentCurrency
        )
        let publicTax = CheckoutClientAPIResponse.makeTax(from: apiResponse.automaticTax)
        let localizedPricesMetas = CheckoutClientAPIResponse.makeLocalizedPricesMetas(
            from: apiResponse.adaptivePricingInfo
        )
        let exchangeRateMeta = CheckoutClientAPIResponse.makeExchangeRateMeta(
            from: apiResponse.adaptivePricingInfo,
            presentmentCurrency: apiResponse.presentmentCurrency
        )
        let presentmentDetails = apiResponse.adaptivePricingInfo.map { _ in
            CheckoutController.Session.PresentmentDetails(presentmentCurrency: apiResponse.presentmentCurrency)
        }
        let automaticTaxEnabled = apiResponse.automaticTax?.enabled ?? false
        let automaticTaxAddressSource = apiResponse.automaticTax?.addressSource
        if automaticTaxEnabled && automaticTaxAddressSource == "billing" {
            elementsSessionValue.disableLinkForAutomaticTaxBilling = true
        }
        let availableExpressCheckoutPaymentMethods =
            configuration.map {
                ExpressCheckoutElementUtilities.availablePaymentMethods(for: apiResponse, configuration: $0).map(
                    \.rawValue
                )
            } ?? []
        let serverEmail = apiResponse.customerEmail

        self.init(
            id: apiResponse.id,
            businessName: apiResponse.merchantInfo.displayName,
            currency: apiResponse.integrationCurrency,
            presentmentDetails: presentmentDetails,
            discountAmounts: [],
            orderSummaryItems: publicOrderSummaryItems,
            livemode: apiResponse.livemode,
            minorUnitsAmountDivisor: CheckoutClientAPIResponse.makeMinorUnitsAmountDivisor(
                currency: apiResponse.presentmentCurrency
            ),
            status: apiResponse.status,
            tax: publicTax,
            taxAmounts: publicTaxAmounts,
            totals: publicTotals,
            availableExpressCheckoutPaymentMethods: availableExpressCheckoutPaymentMethods,
            paymentStatus: apiResponse.paymentStatus,
            paymentMethodOptions: apiResponse.paymentMethodOptions,
            serverEmail: serverEmail,
            localState: localState,
            customer: apiResponse.customer.map {
                Customer(
                    id: $0.id,
                    paymentMethods: $0.paymentMethods,
                    canDetachPaymentMethod: apiResponse.savedPaymentMethodOptions?.paymentMethodRemove == "enabled"
                )
            },
            savedPaymentMethodsOfferSave: apiResponse.savedPaymentMethodOptions?.paymentMethodSave.map {
                STPCheckoutSessionSavedPaymentMethodsOfferSave(enabled: $0 == "enabled")
            },
            setupFutureUsage: nil,
            setupFutureUsageForPaymentMethodType: apiResponse.setupFutureUsageForPaymentMethodType ?? [:],
            allowedShippingCountries: apiResponse.shippingAddressCollection?.allowedCountries.map { $0.uppercased() },
            localizedPricesMetas: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta,
            adaptivePricingActive: apiResponse.adaptivePricingInfo != nil,
            billingAddressCollection: apiResponse.billingAddressCollection.flatMap(
                CheckoutController.Session.BillingAddressCollection.init(rawValue:)
            ) ?? .automatic,
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource,
            merchantCountryCode: apiResponse.merchantInfo.country,
            elementsSession: elementsSessionValue
        )
    }
}

//
//  CurrencySelectorUtilities.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/23/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// Shared utilities for currency selector components (standalone and in-form).
enum CurrencySelectorUtilities {

    /// A normalized currency code that provides typed access for API vs display use.
    struct CurrencyCode: Equatable {
        /// Lowercase form for comparisons, identifiers, and API calls (e.g. "usd").
        let apiValue: String
        /// Uppercase form for user-facing UI (e.g. "USD").
        let displayValue: String

        init(_ rawValue: String) {
            self.apiValue = rawValue.lowercased()
            self.displayValue = rawValue.uppercased()
        }
    }

    // MARK: - Two-option builder

    /// Local currency on the left, integration (merchant) currency on the right.
    /// Uses `exchangeRateMeta` for stable ordering that doesn't change on reload.
    ///
    /// - Parameter flagPrefixProvider: Returns an attributed flag icon for each currency code.
    static func buildSelectorItems(
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta,
        localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta],
        labelContent: Checkout.CurrencySelectorView.Appearance.LabelContent = .currencyCode,
        flagPrefixProvider: (String) -> NSAttributedString = { _ in NSAttributedString() }
    ) -> (left: TwoOptionSelectorItem, right: TwoOptionSelectorItem) {
        let localCurrency = CurrencyCode(exchangeRateMeta.localizedCurrency)
        let integrationCurrency = CurrencyCode(exchangeRateMeta.integrationCurrency)

        let localMeta = localizedPricesMetas.first { CurrencyCode($0.currency) == localCurrency }
        let integrationMeta = localizedPricesMetas.first { CurrencyCode($0.currency) == integrationCurrency }

        let left = localMeta.map {
            makeSelectorItem(currency: CurrencyCode($0.currency), total: $0.total, labelContent: labelContent, flagPrefix: flagPrefixProvider(localCurrency.apiValue))
        } ?? makeSelectorItem(currency: localCurrency, total: 0, labelContent: labelContent, flagPrefix: flagPrefixProvider(localCurrency.apiValue))

        let right = integrationMeta.map {
            makeSelectorItem(currency: CurrencyCode($0.currency), total: $0.total, labelContent: labelContent, flagPrefix: flagPrefixProvider(integrationCurrency.apiValue))
        } ?? makeSelectorItem(currency: integrationCurrency, total: 0, labelContent: labelContent, flagPrefix: flagPrefixProvider(integrationCurrency.apiValue))

        return (left: left, right: right)
    }

    static func makeSelectorItem(currency: CurrencyCode, total: Int, labelContent: Checkout.CurrencySelectorView.Appearance.LabelContent = .currencyCode, flagPrefix: NSAttributedString) -> TwoOptionSelectorItem {
        let displayText = NSMutableAttributedString(attributedString: flagPrefix)
        if displayText.length > 0 {
            displayText.append(NSAttributedString(string: " \u{2009}"))
        }
        let accessibilityLabel: String
        switch labelContent {
        case .currencyCode:
            displayText.append(NSAttributedString(string: currency.displayValue))
            accessibilityLabel = currency.displayValue
        case .amount:
            let formattedAmount = String.localizedAmountDisplayString(for: total, currency: currency.apiValue)
            displayText.append(NSAttributedString(string: formattedAmount))
            accessibilityLabel = "\(formattedAmount) \(currency.displayValue)"
        case .automatic:
            assertionFailure(".automatic should be resolved before reaching makeSelectorItem")
            displayText.append(NSAttributedString(string: currency.displayValue))
            accessibilityLabel = currency.displayValue
        }
        return TwoOptionSelectorItem(
            id: currency.apiValue,
            displayText: displayText,
            accessibilityLabel: accessibilityLabel,
            accessibilityIdentifier: "currency_option_\(currency.apiValue)"
        )
    }

    // MARK: - Caption

    /// Shows the exchange rate when the local currency is selected,
    /// or a bank-fees disclaimer when the merchant's currency is selected.
    static func caption(
        forSelectedCurrency selectedCurrency: String,
        exchangeRateMeta meta: STPCheckoutSessionExchangeRateMeta
    ) -> String {
        let isIntegrationCurrencySelected = selectedCurrency == CurrencyCode(meta.integrationCurrency).apiValue
        if isIntegrationCurrencySelected {
            return String.Localized.bankExchangeRateDisclaimer
        }

        return formatExchangeRate(from: meta)
    }

    private static let exchangeRateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter
    }()

    static func formatExchangeRate(from meta: STPCheckoutSessionExchangeRateMeta) -> String {
        let localCurrency = CurrencyCode(meta.localizedCurrency).displayValue
        let integrationCurrency = CurrencyCode(meta.integrationCurrency).displayValue

        let formattedRate: String
        if let rateDouble = Double(meta.exchangeRate) {
            let inverse = 1.0 / rateDouble
            formattedRate = exchangeRateFormatter.string(from: NSNumber(value: inverse)) ?? meta.exchangeRate
        } else {
            formattedRate = meta.exchangeRate
        }

        if meta.conversionMarkupBps > 0 {
            let feePercent = String(format: "%g", Double(meta.conversionMarkupBps) / 100.0)
            return .Localized.exchangeRateWithConversionFee(
                localCurrency: localCurrency,
                rate: formattedRate,
                integrationCurrency: integrationCurrency,
                feePercent: feePercent
            )
        }

        return .Localized.exchangeRate(
            localCurrency: localCurrency,
            rate: formattedRate,
            integrationCurrency: integrationCurrency
        )
    }

    /// Returns the expandable detail text for the exchange rate, or nil if not applicable.
    /// This will be replaced by a server-provided string from the translation layer in the future.
    static func detailText(exchangeRateMeta meta: STPCheckoutSessionExchangeRateMeta) -> String? {
        guard meta.conversionMarkupBps > 0 else { return nil }
        return "This string will come from the translation layer in the future"
    }

    // MARK: - Availability

    /// Returns the adaptive pricing data needed to show a currency selector,
    /// or `nil` if adaptive pricing is not available for the given session.
    static func adaptivePricingData(
        from session: Checkout.Session?
    ) -> (session: Checkout.Session, exchangeRateMeta: STPCheckoutSessionExchangeRateMeta, currency: String)? {
        guard let session,
              session.adaptivePricingActive,
              !session.localizedPricesMetas.isEmpty,
              let exchangeRateMeta = session.exchangeRateMeta,
              let currency = session.currency
        else { return nil }
        return (session, exchangeRateMeta, currency)
    }

    // MARK: - Flag emoji

    // Most currency codes already start with the country code (USD→US, GBP→GB) per ISO 4217.
    // ANG is the one exception among Stripe-supported currencies — it maps to NL, not the
    // defunct "AN" (Netherlands Antilles). X-prefixed codes (XAF, XOF, etc.) are multi-country
    // so we just skip the flag entirely.
    // See also: stripe-js CURRENCY_TO_FLAG_CODES in src/lib/inner/components/FlagIcon/

    private static let regionCodeOverrides: [String: String] = [
        "ang": "NL",
    ]

    private static let unmappedCurrencies: Set<String> = [
        "xaf", "xcd", "xof", "xpf",
    ]

    /// Region code for the currency, or nil for multi-country currencies (XAF, XOF, etc.)
    static func regionCode(for currency: CurrencyCode) -> String? {
        if unmappedCurrencies.contains(currency.apiValue) { return nil }
        if let override = regionCodeOverrides[currency.apiValue] { return override }
        return String(currency.displayValue.prefix(2))
    }

    static func flagEmoji(for currency: CurrencyCode) -> String {
        guard let regionCode = regionCode(for: currency) else {
            return ""
        }
        return String.regionFlagEmoji(for: regionCode) ?? ""
    }
}

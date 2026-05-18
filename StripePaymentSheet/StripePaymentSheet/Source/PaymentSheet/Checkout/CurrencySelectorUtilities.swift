//
//  CurrencySelectorUtilities.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/23/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

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
        switch labelContent {
        case .currencyCode:
            displayText.append(NSAttributedString(string: currency.displayValue))
        case .amount:
            let formattedAmount = String.localizedAmountDisplayString(for: total, currency: currency.apiValue)
            displayText.append(NSAttributedString(string: formattedAmount))
        }
        return TwoOptionSelectorItem(
            id: currency.apiValue,
            displayText: displayText,
            accessibilityLabel: "\(amount) \(currency.displayValue)",
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

    static func formatExchangeRate(from meta: STPCheckoutSessionExchangeRateMeta) -> String {
        let localCurrency = CurrencyCode(meta.localizedCurrency).displayValue
        let integrationCurrency = CurrencyCode(meta.integrationCurrency).displayValue

        let formattedRate: String
        if let rateDouble = Double(meta.exchangeRate) {
            let inverse = 1.0 / rateDouble
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 4
            formattedRate = formatter.string(from: NSNumber(value: inverse)) ?? meta.exchangeRate
        } else {
            formattedRate = meta.exchangeRate
        }

        if meta.conversionMarkupBps > 0 {
            let feePercent = formatConversionFeePercent(bps: meta.conversionMarkupBps)
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

    private static func formatConversionFeePercent(bps: Int) -> String {
        let percent = Double(bps) / 100.0
        if percent.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", percent)
        }
        return String(format: "%g", percent)
    }

    // MARK: - Availability

    /// Returns the adaptive pricing data needed to show a currency selector,
    /// or `nil` if adaptive pricing is not available for the given session.
    static func adaptivePricingData(
        from session: Checkout.Session?
    ) -> (session: STPCheckoutSession, exchangeRateMeta: STPCheckoutSessionExchangeRateMeta, currency: String)? {
        guard let session = session as? STPCheckoutSession,
              session.adaptivePricingActive,
              !session.localizedPricesMetas.isEmpty,
              let exchangeRateMeta = session.exchangeRateMeta,
              let currency = session.currency
        else { return nil }
        return (session, exchangeRateMeta, currency)
    }

    // MARK: - Flag emoji

    static func flagEmoji(for currency: CurrencyCode) -> String {
        let regionCode = String(currency.displayValue.prefix(2))
        return String.regionFlagEmoji(for: regionCode) ?? ""
    }
}

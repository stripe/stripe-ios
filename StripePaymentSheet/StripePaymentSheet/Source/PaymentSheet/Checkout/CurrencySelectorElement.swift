//
//  CurrencySelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/20/26.

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// Adaptive pricing currency selector built on `TwoOptionSelectorElement`.
/// Shows two currencies with flag emoji and formatted amounts.
final class CurrencySelectorElement: Element {

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

    weak var delegate: ElementDelegate?

    let collectsUserInput: Bool = true

    var view: UIView { selectorElement.view }

    private let selectorElement: TwoOptionSelectorElement
    private let exchangeRateMeta: STPCheckoutSessionExchangeRateMeta

    /// The selected currency code (lowercased).
    var selectedCurrency: String { selectorElement.selectedItemId }

    init(
        currentCurrency: String,
        currentTotal: Int,
        localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta],
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta,
        appearance: PaymentSheet.Appearance,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.exchangeRateMeta = exchangeRateMeta
        let currency = CurrencyCode(currentCurrency)
        let (left, right) = Self.buildSelectorItems(
            exchangeRateMeta: exchangeRateMeta,
            localizedPricesMetas: localizedPricesMetas
        )
        selectorElement = TwoOptionSelectorElement(
            leftItem: left,
            rightItem: right,
            selectedItemId: currency.apiValue,
            caption: Self.caption(forSelectedCurrency: currency.apiValue, exchangeRateMeta: exchangeRateMeta),
            appearance: appearance
        )
        selectorElement.delegate = self
        analyticsHelper.logAdaptivePricingCurrencySelectorInit(isStandaloneElement: false)
    }

    // MARK: - Factory

    static func makeIfNeeded(
        intent: Intent,
        isFlowController: Bool,
        appearance: PaymentSheet.Appearance,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) -> CurrencySelectorElement? {
        guard !isFlowController else { return nil }
        guard case .checkoutSession(let session) = intent else { return nil }
        guard session.adaptivePricingActive else { return nil }
        guard !session.localizedPricesMetas.isEmpty else { return nil }
        guard let exchangeRateMeta = session.exchangeRateMeta else { return nil }
        guard let currency = session.currency, let total = session.totals?.total else { return nil }

        return CurrencySelectorElement(
            currentCurrency: currency,
            currentTotal: total,
            localizedPricesMetas: session.localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta,
            appearance: appearance,
            analyticsHelper: analyticsHelper
        )
    }

    // MARK: - Public API

    func setEnabled(_ enabled: Bool) {
        selectorElement.setEnabled(enabled)
    }

    // MARK: - Two-option builder

    /// Local currency on the left, integration (merchant) currency on the right.
    /// Uses `exchangeRateMeta` for stable ordering that doesn't change on reload.
    static func buildSelectorItems(
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta,
        localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta]
    ) -> (left: TwoOptionSelectorItem, right: TwoOptionSelectorItem) {
        let localCurrency = CurrencyCode(exchangeRateMeta.localizedCurrency)
        let integrationCurrency = CurrencyCode(exchangeRateMeta.integrationCurrency)

        let localMeta = localizedPricesMetas.first { CurrencyCode($0.currency) == localCurrency }
        let integrationMeta = localizedPricesMetas.first { CurrencyCode($0.currency) == integrationCurrency }

        let left = localMeta.map { makeSelectorItem(currency: CurrencyCode($0.currency), total: $0.total) }
            ?? makeSelectorItem(currency: localCurrency, total: 0)
        let right = integrationMeta.map { makeSelectorItem(currency: CurrencyCode($0.currency), total: $0.total) }
            ?? makeSelectorItem(currency: integrationCurrency, total: 0)

        return (left: left, right: right)
    }

    static func makeSelectorItem(currency: CurrencyCode, total: Int) -> TwoOptionSelectorItem {
        let flag = flagEmoji(for: currency)
        let amount = String.localizedAmountDisplayString(for: total, currency: currency.displayValue)
        return TwoOptionSelectorItem(
            id: currency.apiValue,
            displayText: "\(flag) \(amount)",
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
        let sellCurrency = CurrencyCode(meta.sellCurrency).displayValue
        let buyCurrency = CurrencyCode(meta.buyCurrency).displayValue

        let formattedRate: String
        if let rateDouble = Double(meta.exchangeRate) {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 4
            formattedRate = formatter.string(from: NSNumber(value: rateDouble)) ?? meta.exchangeRate
        } else {
            formattedRate = meta.exchangeRate
        }

        return "1 \(sellCurrency) = \(formattedRate) \(buyCurrency)"
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

// MARK: - ElementDelegate forwarding

extension CurrencySelectorElement: ElementDelegate {
    func didUpdate(element: Element) {
        selectorElement.updateCaption(
            Self.caption(forSelectedCurrency: selectedCurrency, exchangeRateMeta: exchangeRateMeta)
        )
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}

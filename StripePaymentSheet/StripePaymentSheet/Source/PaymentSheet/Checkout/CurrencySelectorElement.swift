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
        appearance: PaymentSheet.Appearance
    ) {
        self.exchangeRateMeta = exchangeRateMeta
        let (left, right) = Self.buildSelectorItems(
            exchangeRateMeta: exchangeRateMeta,
            localizedPricesMetas: localizedPricesMetas
        )
        selectorElement = TwoOptionSelectorElement(
            leftItem: left,
            rightItem: right,
            selectedItemId: currentCurrency.lowercased(),
            caption: Self.caption(forSelectedCurrency: currentCurrency.lowercased(), exchangeRateMeta: exchangeRateMeta),
            appearance: appearance
        )
        selectorElement.delegate = self
    }

    // MARK: - Factory

    static func makeIfNeeded(
        intent: Intent,
        isFlowController: Bool,
        appearance: PaymentSheet.Appearance
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
            appearance: appearance
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
        let localCurrency = exchangeRateMeta.localizedCurrency.lowercased()
        let integrationCurrency = exchangeRateMeta.integrationCurrency.lowercased()

        let localMeta = localizedPricesMetas.first { $0.currency.lowercased() == localCurrency }
        let integrationMeta = localizedPricesMetas.first { $0.currency.lowercased() == integrationCurrency }

        let left = localMeta.map { makeSelectorItem(currency: $0.currency, total: $0.total) }
            ?? makeSelectorItem(currency: localCurrency, total: 0)
        let right = integrationMeta.map { makeSelectorItem(currency: $0.currency, total: $0.total) }
            ?? makeSelectorItem(currency: integrationCurrency, total: 0)

        return (left: left, right: right)
    }

    static func makeSelectorItem(currency: String, total: Int) -> TwoOptionSelectorItem {
        let flag = flagEmoji(for: currency)
        let amount = String.localizedAmountDisplayString(for: total, currency: currency.uppercased())
        return TwoOptionSelectorItem(
            id: currency.lowercased(),
            displayText: "\(flag) \(amount)",
            accessibilityIdentifier: "currency_option_\(currency.lowercased())"
        )
    }

    // MARK: - Caption

    /// Shows the exchange rate when the local currency is selected,
    /// or a bank-fees disclaimer when the merchant's currency is selected.
    static func caption(
        forSelectedCurrency selectedCurrency: String,
        exchangeRateMeta meta: STPCheckoutSessionExchangeRateMeta
    ) -> String {
        let isIntegrationCurrencySelected = selectedCurrency == meta.integrationCurrency.lowercased()
        if isIntegrationCurrencySelected {
            return String.Localized.bankExchangeRateDisclaimer
        }

        return formatExchangeRate(from: meta)
    }

    static func formatExchangeRate(from meta: STPCheckoutSessionExchangeRateMeta) -> String {
        let sellCurrency = meta.sellCurrency.uppercased()
        let buyCurrency = meta.buyCurrency.uppercased()

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

    /// Whether the given session has the data needed to show a currency selector.
    static func isAdaptivePricingAvailable(session: Checkout.Session?) -> Bool {
        guard let session = session as? STPCheckoutSession else { return false }
        return session.adaptivePricingActive
            && !session.localizedPricesMetas.isEmpty
            && session.exchangeRateMeta != nil
            && session.currency != nil
    }

    // MARK: - Flag emoji

    static func flagEmoji(for currencyCode: String) -> String {
        let regionCode = String(currencyCode.lowercased().prefix(2)).uppercased()
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

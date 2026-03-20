//
//  CurrencySelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/20/26.

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// Adaptive pricing currency selector built on `PillSelectorElement`.
/// Shows two currencies with flag emoji and formatted amounts.
final class CurrencySelectorElement: Element {
    weak var delegate: ElementDelegate?

    let collectsUserInput: Bool = true

    var view: UIView { pillElement.view }

    private let pillElement: PillSelectorElement
    private var exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?

    /// The selected currency code (lowercased).
    var selectedCurrency: String { pillElement.selectedItemId }

    init(
        currentCurrency: String,
        currentTotal: Int,
        localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta],
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?,
        appearance: PaymentSheet.Appearance
    ) {
        self.exchangeRateMeta = exchangeRateMeta
        let (left, right) = Self.buildPillItems(
            currentCurrency: currentCurrency,
            currentTotal: currentTotal,
            localizedPricesMetas: localizedPricesMetas
        )
        pillElement = PillSelectorElement(
            leftItem: left,
            rightItem: right,
            selectedItemId: currentCurrency.lowercased(),
            caption: Self.caption(forSelectedCurrency: currentCurrency.lowercased(), exchangeRateMeta: exchangeRateMeta),
            appearance: appearance
        )
        pillElement.delegate = self
    }

    // MARK: - Public API

    func selectCurrency(_ currency: String) {
        pillElement.select(currency.lowercased())
    }

    func setEnabled(_ enabled: Bool) {
        pillElement.setEnabled(enabled)
    }

    // MARK: - Two-option builder

    /// Current currency on the left, the other available currency on the right.
    private static func buildPillItems(
        currentCurrency: String,
        currentTotal: Int,
        localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta]
    ) -> (left: PillSelectorItem, right: PillSelectorItem) {
        let other = localizedPricesMetas.first { $0.currency.lowercased() != currentCurrency.lowercased() }

        let left = makePillItem(currency: currentCurrency, total: currentTotal)
        let right = other.map { makePillItem(currency: $0.currency, total: $0.total) } ?? left

        return (left: left, right: right)
    }

    private static func makePillItem(currency: String, total: Int) -> PillSelectorItem {
        let flag = flagEmoji(for: currency)
        let amount = String.localizedAmountDisplayString(for: total, currency: currency.uppercased())
        return PillSelectorItem(
            id: currency.lowercased(),
            displayText: "\(flag) \(amount)",
            accessibilityIdentifier: "currency_option_\(currency.lowercased())"
        )
    }

    // MARK: - Caption

    /// Shows the exchange rate when the local currency is selected,
    /// or a bank-fees disclaimer when the merchant's currency is selected.
    private static func caption(
        forSelectedCurrency selectedCurrency: String,
        exchangeRateMeta meta: STPCheckoutSessionExchangeRateMeta?
    ) -> String? {
        guard let meta else { return nil }

        let isIntegrationCurrencySelected = selectedCurrency == meta.integrationCurrency.lowercased()
        if isIntegrationCurrencySelected {
            return String.Localized.bankExchangeRateDisclaimer
        }

        return formatExchangeRate(from: meta)
    }

    private static func formatExchangeRate(from meta: STPCheckoutSessionExchangeRateMeta) -> String {
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

    // MARK: - Flag emoji

    // "ang" -> "NL" because the Netherlands Antilles was dissolved in 2010.
    private static let regionCodeOverrides: [String: String] = ["ang": "NL"]

    private static func flagEmoji(for currencyCode: String) -> String {
        let lower = currencyCode.lowercased()
        let regionCode = regionCodeOverrides[lower] ?? String(lower.prefix(2)).uppercased()
        return String.regionFlagEmoji(for: regionCode) ?? ""
    }
}

// MARK: - ElementDelegate forwarding

extension CurrencySelectorElement: ElementDelegate {
    func didUpdate(element: Element) {
        pillElement.updateCaption(
            Self.caption(forSelectedCurrency: selectedCurrency, exchangeRateMeta: exchangeRateMeta)
        )
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}

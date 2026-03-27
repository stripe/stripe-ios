//
//  CurrencySelectorElementTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/20/26.

@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import UIKit
import XCTest

@MainActor
final class CurrencySelectorElementTests: XCTestCase {

    func testCurrentCurrencyMissingFromMetas() {
        let element = makeCurrencySelectorElement(
            currentCurrency: "usd",
            currentTotal: 1200,
            localizedPricesMetas: [
                localizedPriceMeta(currency: "eur", total: 1100),
                localizedPriceMeta(currency: "gbp", total: 1000),
            ]
        )

        XCTAssertEqual(element.selectedCurrency, "usd")
        let ids = buttonIdentifiers(in: element.view)
        XCTAssertTrue(ids.contains("currency_option_usd"))
        XCTAssertEqual(ids.count, 2)
    }

    func testTapOnNewCurrencyNotifiesDelegateAndUpdatesSelection() throws {
        let delegate = MockElementDelegate()
        let element = makeCurrencySelectorElement(
            currentCurrency: "usd",
            currentTotal: 1200,
            localizedPricesMetas: [
                localizedPriceMeta(currency: "usd", total: 1200),
                localizedPriceMeta(currency: "eur", total: 1100),
            ],
            exchangeRateMeta: exchangeRateMeta(buyCurrency: "eur", sellCurrency: "usd", exchangeRate: "0.92")
        )
        element.delegate = delegate

        let eurButton = try XCTUnwrap(button(in: element.view, id: "currency_option_eur"))
        eurButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(element.selectedCurrency, "eur")
        XCTAssertEqual(selectedButton(in: element.view)?.accessibilityIdentifier, "currency_option_eur")
        XCTAssertTrue(delegate.didUpdateCalled)
        XCTAssertTrue(delegate.lastUpdatedElement === element)
    }

    func testTapOnSelectedCurrencyDoesNotNotifyDelegate() throws {
        let delegate = MockElementDelegate()
        let element = makeCurrencySelectorElement(
            currentCurrency: "usd",
            currentTotal: 1200,
            localizedPricesMetas: [
                localizedPriceMeta(currency: "usd", total: 1200),
                localizedPriceMeta(currency: "eur", total: 1100),
            ],
            exchangeRateMeta: exchangeRateMeta(buyCurrency: "eur", sellCurrency: "usd", exchangeRate: "0.92")
        )
        element.delegate = delegate

        let usdButton = try XCTUnwrap(button(in: element.view, id: "currency_option_usd"))
        usdButton.sendActions(for: .touchUpInside)

        XCTAssertFalse(delegate.didUpdateCalled)
        XCTAssertEqual(element.selectedCurrency, "usd")
    }

    func testShowsExchangeRateWhenLocalizedCurrencySelected() throws {
        let element = makeCurrencySelectorElement(
            currentCurrency: "gbp",
            currentTotal: 1000,
            localizedPricesMetas: [
                localizedPriceMeta(currency: "usd", total: 1200),
                localizedPriceMeta(currency: "gbp", total: 1000),
            ],
            exchangeRateMeta: exchangeRateMeta(
                buyCurrency: "gbp",
                sellCurrency: "usd",
                exchangeRate: "0.776917"
            )
        )

        let label = try XCTUnwrap(captionLabel(in: element.view))
        XCTAssertFalse(label.isHidden)
        XCTAssertEqual(label.text, "1 USD = 0.777 GBP")
    }

    func testShowsBankDisclaimerWhenIntegrationCurrencySelected() throws {
        let element = makeCurrencySelectorElement(
            currentCurrency: "usd",
            currentTotal: 1200,
            localizedPricesMetas: [
                localizedPriceMeta(currency: "usd", total: 1200),
                localizedPriceMeta(currency: "gbp", total: 1000),
            ],
            exchangeRateMeta: exchangeRateMeta(
                buyCurrency: "gbp",
                sellCurrency: "usd",
                exchangeRate: "0.776917"
            )
        )

        let label = try XCTUnwrap(captionLabel(in: element.view))
        XCTAssertFalse(label.isHidden)
        XCTAssertEqual(label.text, String.Localized.bankExchangeRateDisclaimer)
    }

    func testCaptionSwitchesWhenSelectionChanges() throws {
        let element = makeCurrencySelectorElement(
            currentCurrency: "gbp",
            currentTotal: 1000,
            localizedPricesMetas: [
                localizedPriceMeta(currency: "usd", total: 1200),
                localizedPriceMeta(currency: "gbp", total: 1000),
            ],
            exchangeRateMeta: exchangeRateMeta(
                buyCurrency: "gbp",
                sellCurrency: "usd",
                exchangeRate: "0.776917"
            )
        )

        let label = try XCTUnwrap(captionLabel(in: element.view))
        XCTAssertEqual(label.text, "1 USD = 0.777 GBP")

        element.selectCurrency("usd")
        XCTAssertEqual(label.text, String.Localized.bankExchangeRateDisclaimer)

        element.selectCurrency("gbp")
        XCTAssertEqual(label.text, "1 USD = 0.777 GBP")
    }

    func testOrderingIsStableRegardlessOfCurrentCurrency() {
        let meta = exchangeRateMeta(buyCurrency: "gbp", sellCurrency: "usd", exchangeRate: "0.776917")
        let metas = [
            localizedPriceMeta(currency: "usd", total: 1200),
            localizedPriceMeta(currency: "gbp", total: 1000),
        ]

        // Create with currentCurrency = gbp (local currency selected)
        let elementA = makeCurrencySelectorElement(
            currentCurrency: "gbp",
            currentTotal: 1000,
            localizedPricesMetas: metas,
            exchangeRateMeta: meta
        )

        // Create with currentCurrency = usd (integration currency selected, e.g. after reload)
        let elementB = makeCurrencySelectorElement(
            currentCurrency: "usd",
            currentTotal: 1200,
            localizedPricesMetas: metas,
            exchangeRateMeta: meta
        )

        let idsA = buttonIdentifiers(in: elementA.view)
        let idsB = buttonIdentifiers(in: elementB.view)

        // Both should have local currency (gbp) on the left and integration (usd) on the right
        XCTAssertEqual(idsA, idsB, "Button ordering should be stable regardless of currentCurrency")
        XCTAssertEqual(idsA, ["currency_option_gbp", "currency_option_usd"])
    }

    // MARK: - Helpers

    private func makeCurrencySelectorElement(
        currentCurrency: String,
        currentTotal: Int,
        localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta],
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta? = nil
    ) -> CurrencySelectorElement {
        CurrencySelectorElement(
            currentCurrency: currentCurrency,
            currentTotal: currentTotal,
            localizedPricesMetas: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta ?? self.exchangeRateMeta(
                buyCurrency: localizedPricesMetas.first?.currency ?? "eur",
                sellCurrency: "usd",
                exchangeRate: "1.0"
            ),
            appearance: .default
        )
    }

    private func localizedPriceMeta(currency: String, total: Int) -> STPCheckoutSessionLocalizedPriceMeta {
        STPCheckoutSessionLocalizedPriceMeta(id: currency, currency: currency, total: total)
    }

    private func exchangeRateMeta(
        buyCurrency: String,
        sellCurrency: String,
        exchangeRate: String
    ) -> STPCheckoutSessionExchangeRateMeta {
        STPCheckoutSessionExchangeRateMeta(
            id: "\(sellCurrency)_to_\(buyCurrency)",
            buyCurrency: buyCurrency,
            sellCurrency: sellCurrency,
            exchangeRate: exchangeRate,
            integrationCurrency: sellCurrency,
            localizedCurrency: buyCurrency,
            conversionMarkupBps: 400
        )
    }

    private func buttonIdentifiers(in view: UIView) -> [String] {
        allButtons(in: view).compactMap(\.accessibilityIdentifier)
    }

    private func button(in view: UIView, id: String) -> UIButton? {
        allButtons(in: view).first(where: { $0.accessibilityIdentifier == id })
    }

    private func selectedButton(in view: UIView) -> UIButton? {
        let buttons = allButtons(in: view)
        let selectedColor = PaymentSheet.Appearance.default.colors.componentText
        return buttons.first(where: { $0.titleColor(for: .normal) == selectedColor })
    }

    private func captionLabel(in view: UIView) -> UILabel? {
        allLabels(in: view).first(where: { $0.numberOfLines == 0 })
    }

    private func allButtons(in view: UIView) -> [UIButton] {
        allSubviews(in: view).compactMap { $0 as? UIButton }
    }

    private func allLabels(in view: UIView) -> [UILabel] {
        allSubviews(in: view).compactMap { $0 as? UILabel }
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap(allSubviews(in:))
    }
}

private final class MockElementDelegate: ElementDelegate {
    var didUpdateCalled = false
    weak var lastUpdatedElement: Element?

    func didUpdate(element: Element) {
        didUpdateCalled = true
        lastUpdatedElement = element
    }

    func continueToNextField(element: Element) {}
}

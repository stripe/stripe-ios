//
//  CurrencySelectorElementSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/20/26.

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import UIKit
// @iOS26
// ☠️ WARNING: These snapshots do not have capsule corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
final class CurrencySelectorElementSnapshotTests: STPSnapshotTestCase {
    var appearance = PaymentSheet.Appearance().applyingLiquidGlassIfPossible()

    func testFirstCurrencySelected() {
        let element = makeElement(
            currentCurrency: "usd",
            currentTotal: 1200,
            metas: [meta(currency: "usd", total: 1200), meta(currency: "gbp", total: 950)]
        )
        verify(element)
    }

    func testWithExchangeRate() {
        let element = makeElement(
            currentCurrency: "gbp",
            currentTotal: 950,
            metas: [meta(currency: "usd", total: 1200), meta(currency: "gbp", total: 950)],
            exchangeRateMeta: STPCheckoutSessionExchangeRateMeta(
                id: "usd_to_gbp",
                buyCurrency: "gbp",
                sellCurrency: "usd",
                exchangeRate: "0.776917",
                integrationCurrency: "usd",
                localizedCurrency: "gbp",
                conversionMarkupBps: 400
            )
        )
        verify(element)
    }

    func testBankExchangeRateDisclaimer() {
        let element = makeElement(
            currentCurrency: "usd",
            currentTotal: 1200,
            metas: [meta(currency: "usd", total: 1200), meta(currency: "gbp", total: 950)],
            exchangeRateMeta: STPCheckoutSessionExchangeRateMeta(
                id: "usd_to_gbp",
                buyCurrency: "gbp",
                sellCurrency: "usd",
                exchangeRate: "0.776917",
                integrationCurrency: "usd",
                localizedCurrency: "gbp",
                conversionMarkupBps: 400
            )
        )
        verify(element)
    }

    func testDisabled() {
        let element = makeElement(
            currentCurrency: "usd",
            currentTotal: 1200,
            metas: [meta(currency: "usd", total: 1200), meta(currency: "eur", total: 1100)]
        )
        element.setEnabled(false)
        verify(element)
    }

    func testDarkMode() {
        let element = makeElement(
            currentCurrency: "gbp",
            currentTotal: 950,
            metas: [meta(currency: "usd", total: 1200), meta(currency: "gbp", total: 950)],
            exchangeRateMeta: STPCheckoutSessionExchangeRateMeta(
                id: "usd_to_gbp",
                buyCurrency: "gbp",
                sellCurrency: "usd",
                exchangeRate: "0.776917",
                integrationCurrency: "usd",
                localizedCurrency: "gbp",
                conversionMarkupBps: 400
            )
        )
        verify(element, darkMode: true)
    }

    func testCustomAppearance() {
        appearance = ._testMSPaintTheme
        let element = makeElement(
            currentCurrency: "eur",
            currentTotal: 1100,
            metas: [meta(currency: "usd", total: 1200), meta(currency: "eur", total: 1100)],
            exchangeRateMeta: STPCheckoutSessionExchangeRateMeta(
                id: "usd_to_eur",
                buyCurrency: "eur",
                sellCurrency: "usd",
                exchangeRate: "0.875",
                integrationCurrency: "usd",
                localizedCurrency: "eur",
                conversionMarkupBps: 400
            )
        )
        verify(element)
    }

}

private extension CurrencySelectorElementSnapshotTests {
    func meta(currency: String, total: Int) -> STPCheckoutSessionLocalizedPriceMeta {
        STPCheckoutSessionLocalizedPriceMeta(id: currency, currency: currency, total: total)
    }

    func makeElement(
        currentCurrency: String,
        currentTotal: Int,
        metas: [STPCheckoutSessionLocalizedPriceMeta],
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta? = nil
    ) -> CurrencySelectorElement {
        CurrencySelectorElement(
            currentCurrency: currentCurrency,
            currentTotal: currentTotal,
            localizedPricesMetas: metas,
            exchangeRateMeta: exchangeRateMeta ?? STPCheckoutSessionExchangeRateMeta(
                id: "default",
                buyCurrency: metas.first?.currency ?? "eur",
                sellCurrency: "usd",
                exchangeRate: "1.0",
                integrationCurrency: "usd",
                localizedCurrency: metas.first?.currency ?? "eur",
                conversionMarkupBps: 400
            ),
            appearance: appearance
        )
    }

    func verify(
        _ element: CurrencySelectorElement,
        darkMode: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        verifySelectorSnapshotView(element.view, darkMode: darkMode, file: file, line: line)
    }
}

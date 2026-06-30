//
//  CurrencySelectorUtilitiesTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class CurrencySelectorUtilitiesTests: XCTestCase {

    // MARK: - CurrencyCode

    func testCurrencyCodeNormalization() {
        let code = CurrencySelectorUtilities.CurrencyCode("UsD")
        XCTAssertEqual(code.apiValue, "usd")
        XCTAssertEqual(code.displayValue, "USD")
    }

    func testCurrencyCodeEquality() {
        let a = CurrencySelectorUtilities.CurrencyCode("usd")
        let b = CurrencySelectorUtilities.CurrencyCode("USD")
        XCTAssertEqual(a, b)
    }

    // MARK: - formatConversionFeePercent (tested indirectly via formatExchangeRate)

    func testFormatExchangeRate_conversionFee_wholePercent() {
        let meta = makeExchangeRateMeta(conversionMarkupBps: 200)
        let result = CurrencySelectorUtilities.formatExchangeRate(from: meta)
        XCTAssertTrue(result.contains("2"), "Expected whole percent '2' in: \(result)")
    }

    func testFormatExchangeRate_conversionFee_fractionalPercent() {
        let meta = makeExchangeRateMeta(conversionMarkupBps: 150)
        let result = CurrencySelectorUtilities.formatExchangeRate(from: meta)
        XCTAssertTrue(result.contains("1.5"), "Expected fractional percent '1.5' in: \(result)")
    }

    // MARK: - formatExchangeRate

    func testFormatExchangeRate_withoutConversionFee() {
        let meta = makeExchangeRateMeta(
            exchangeRate: "0.776917",
            localizedCurrency: "gbp",
            integrationCurrency: "usd",
            conversionMarkupBps: 0
        )
        let result = CurrencySelectorUtilities.formatExchangeRate(from: meta)
        XCTAssertTrue(result.contains("GBP"))
        XCTAssertTrue(result.contains("USD"))
        XCTAssertTrue(result.contains("1.28"))
    }

    func testFormatExchangeRate_withConversionFee() {
        let meta = makeExchangeRateMeta(
            exchangeRate: "0.776917",
            localizedCurrency: "gbp",
            integrationCurrency: "usd",
            conversionMarkupBps: 400
        )
        let result = CurrencySelectorUtilities.formatExchangeRate(from: meta)
        XCTAssertTrue(result.contains("GBP"))
        XCTAssertTrue(result.contains("USD"))
        XCTAssertTrue(result.contains("4"))
    }

    func testFormatExchangeRate_invalidRateString() {
        let meta = makeExchangeRateMeta(
            exchangeRate: "not_a_number",
            localizedCurrency: "gbp",
            integrationCurrency: "usd",
            conversionMarkupBps: 0
        )
        let result = CurrencySelectorUtilities.formatExchangeRate(from: meta)
        XCTAssertTrue(result.contains("not_a_number"))
    }

    // MARK: - caption

    func testCaption_localCurrencySelected_showsExchangeRate() {
        let meta = makeExchangeRateMeta(
            exchangeRate: "0.776917",
            localizedCurrency: "gbp",
            integrationCurrency: "usd",
            conversionMarkupBps: 0
        )
        let result = CurrencySelectorUtilities.caption(
            forSelectedCurrency: "gbp",
            exchangeRateMeta: meta
        )
        XCTAssertTrue(result.contains("GBP"))
        XCTAssertTrue(result.contains("USD"))
    }

    func testCaption_integrationCurrencySelected_showsBankDisclaimer() {
        let meta = makeExchangeRateMeta(
            exchangeRate: "0.776917",
            localizedCurrency: "gbp",
            integrationCurrency: "usd",
            conversionMarkupBps: 0
        )
        let result = CurrencySelectorUtilities.caption(
            forSelectedCurrency: "usd",
            exchangeRateMeta: meta
        )
        XCTAssertEqual(result, String.Localized.bankExchangeRateDisclaimer)
    }

    // MARK: - detailText

    func testDetailText_noMarkup_returnsNil() {
        let meta = makeExchangeRateMeta(conversionMarkupBps: 0)
        XCTAssertNil(CurrencySelectorUtilities.detailText(exchangeRateMeta: meta))
    }

    func testDetailText_withMarkup_returnsNonNil() {
        let meta = makeExchangeRateMeta(conversionMarkupBps: 400)
        XCTAssertNotNil(CurrencySelectorUtilities.detailText(exchangeRateMeta: meta))
    }

    // MARK: - flagEmoji

    func testFlagEmoji_usd() {
        let code = CurrencySelectorUtilities.CurrencyCode("usd")
        let emoji = CurrencySelectorUtilities.flagEmoji(for: code)
        XCTAssertEqual(emoji, "\u{1F1FA}\u{1F1F8}")
    }

    func testFlagEmoji_gbp() {
        let code = CurrencySelectorUtilities.CurrencyCode("gbp")
        let emoji = CurrencySelectorUtilities.flagEmoji(for: code)
        XCTAssertEqual(emoji, "\u{1F1EC}\u{1F1E7}")
    }

    func testFlagEmoji_eur() {
        let code = CurrencySelectorUtilities.CurrencyCode("eur")
        let emoji = CurrencySelectorUtilities.flagEmoji(for: code)
        XCTAssertEqual(emoji, "\u{1F1EA}\u{1F1FA}")
    }

    // MARK: - adaptivePricingData

    func testAdaptivePricingData_nilSession_returnsNil() {
        XCTAssertNil(CurrencySelectorUtilities.adaptivePricingData(from: nil))
    }

    func testAdaptivePricingData_inactiveAP_returnsNil() {
        let session = CheckoutTestHelpers.makeAdaptivePricingSession(adaptivePricingActive: false)
        XCTAssertNil(CurrencySelectorUtilities.adaptivePricingData(from: session))
    }

    func testAdaptivePricingData_noLocalizedPrices_returnsNil() {
        let session = CheckoutTestHelpers.makeAdaptivePricingSession(includeLocalizedPrices: false)
        XCTAssertNil(CurrencySelectorUtilities.adaptivePricingData(from: session))
    }

    func testAdaptivePricingData_noExchangeRateMeta_returnsNil() {
        let session = CheckoutTestHelpers.makeAdaptivePricingSession(includeExchangeRateFields: false)
        XCTAssertNil(CurrencySelectorUtilities.adaptivePricingData(from: session))
    }

    func testAdaptivePricingData_validSession_returnsTuple() {
        let session = CheckoutTestHelpers.makeAdaptivePricingSession()
        let result = CurrencySelectorUtilities.adaptivePricingData(from: session)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.currency, "usd")
    }

    // MARK: - buildSelectorItems

    @MainActor
    func testBuildSelectorItems_usesCorrectCurrencyIds() {
        let meta = makeExchangeRateMeta(
            exchangeRate: "0.776917",
            localizedCurrency: "gbp",
            integrationCurrency: "usd",
            conversionMarkupBps: 0
        )
        let localizedPrices = [
            STPCheckoutSessionLocalizedPriceMeta(id: "gbp", currency: "gbp", total: 800),
            STPCheckoutSessionLocalizedPriceMeta(id: "usd", currency: "usd", total: 1000),
        ]

        let (left, right) = CurrencySelectorUtilities.buildSelectorItems(
            exchangeRateMeta: meta,
            localizedPricesMetas: localizedPrices,
            labelContent: .currencyCode
        )

        XCTAssertEqual(left.id, "gbp")
        XCTAssertEqual(right.id, "usd")
        XCTAssertTrue(left.displayText.string.contains("GBP"))
        XCTAssertTrue(right.displayText.string.contains("USD"))
    }

    @MainActor
    func testBuildSelectorItems_amountLabel() {
        let meta = makeExchangeRateMeta(
            exchangeRate: "0.776917",
            localizedCurrency: "gbp",
            integrationCurrency: "usd",
            conversionMarkupBps: 0
        )
        let localizedPrices = [
            STPCheckoutSessionLocalizedPriceMeta(id: "gbp", currency: "gbp", total: 800),
            STPCheckoutSessionLocalizedPriceMeta(id: "usd", currency: "usd", total: 1200),
        ]

        let (left, right) = CurrencySelectorUtilities.buildSelectorItems(
            exchangeRateMeta: meta,
            localizedPricesMetas: localizedPrices,
            labelContent: .amount
        )

        XCTAssertTrue(left.accessibilityLabel.contains("GBP"))
        XCTAssertTrue(right.accessibilityLabel.contains("USD"))
    }

    // MARK: - Helpers

    private func makeExchangeRateMeta(
        exchangeRate: String = "0.776917",
        localizedCurrency: String = "gbp",
        integrationCurrency: String = "usd",
        conversionMarkupBps: Int = 0
    ) -> STPCheckoutSessionExchangeRateMeta {
        STPCheckoutSessionExchangeRateMeta(
            id: "\(integrationCurrency)_to_\(localizedCurrency)",
            buyCurrency: localizedCurrency,
            sellCurrency: integrationCurrency,
            exchangeRate: exchangeRate,
            integrationCurrency: integrationCurrency,
            localizedCurrency: localizedCurrency,
            conversionMarkupBps: conversionMarkupBps
        )
    }
}

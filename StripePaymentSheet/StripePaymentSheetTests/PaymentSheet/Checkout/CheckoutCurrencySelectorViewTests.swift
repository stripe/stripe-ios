//
//  CheckoutCurrencySelectorViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/6/26.
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutCurrencySelectorViewTests: XCTestCase {

    // MARK: - Auto-hide tests

    func testHiddenWhenSessionIsNil() async {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let view = Checkout.CurrencySelectorView(checkout: checkout)

        // Session is nil before load(), so the view should be hidden
        XCTAssertTrue(view.isHidden)
    }

    func testHiddenWhenAdaptivePricingNotActive() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession(adaptivePricingActive: false)
        try await checkout.commitSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        // Give Combine time to deliver
        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testHiddenWhenLocalizedPricesEmpty() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession(includeLocalizedPrices: false)
        try await checkout.commitSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testHiddenWhenExchangeRateMetaNil() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession(includeExchangeRateFields: false)
        try await checkout.commitSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testVisibleWhenAdaptivePricingActive() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession()
        try await checkout.commitSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertFalse(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testTransitionsFromHiddenToVisibleOnSessionUpdate() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let view = Checkout.CurrencySelectorView(checkout: checkout)

        // Initially hidden
        XCTAssertTrue(view.isHidden)

        // Update with AP session
        let session = makeSession()
        try await checkout.commitSession(session)

        let expectation = expectation(description: "View becomes visible")
        DispatchQueue.main.async {
            XCTAssertFalse(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Label update tests

    func testLabelsUpdateWhenSessionAmountChanges() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession(integrationAmount: 1200, localAmount: 1000)
        try await checkout.commitSession(session)

        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.labelContent = .amount
        let view = Checkout.CurrencySelectorView(checkout: checkout, appearance: appearance)

        // Wait for initial build
        let built = expectation(description: "Initial build")
        DispatchQueue.main.async {
            built.fulfill()
        }
        await fulfillment(of: [built], timeout: 1.0)

        let selectorView = view.subviews.compactMap { ($0 as? UIStackView)?.arrangedSubviews.compactMap { $0 as? TwoOptionSelectorView }.first }.first
        XCTAssertNotNil(selectorView)
        XCTAssertTrue(selectorView!.leftItem.displayText.string.contains("10"))
        XCTAssertTrue(selectorView!.rightItem.displayText.string.contains("12"))

        // Update session with new amounts
        let updatedSession = makeSession(integrationAmount: 2400, localAmount: 2000)
        try await checkout.commitSession(updatedSession)

        let updated = expectation(description: "Labels updated")
        DispatchQueue.main.async {
            updated.fulfill()
        }
        await fulfillment(of: [updated], timeout: 1.0)

        XCTAssertTrue(selectorView!.leftItem.displayText.string.contains("20"))
        XCTAssertTrue(selectorView!.rightItem.displayText.string.contains("24"))
    }

    // MARK: - Region code / flag tests

    func testRegionCodeForCommonCurrencies() {
        let cases: [(String, String)] = [
            ("usd", "US"),
            ("gbp", "GB"),
            ("eur", "EU"),
            ("chf", "CH"),
            ("jpy", "JP"),
            ("aud", "AU"),
            ("cad", "CA"),
            ("inr", "IN"),
            ("krw", "KR"),
            ("brl", "BR"),
        ]
        for (currency, expected) in cases {
            let code = CurrencySelectorUtilities.CurrencyCode(currency)
            XCTAssertEqual(CurrencySelectorUtilities.regionCode(for: code), expected, "Failed for \(currency)")
        }
    }

    func testRegionCodeNilForXPrefixedCurrencies() {
        for currency in ["xaf", "xof", "xpf", "xcd"] {
            let code = CurrencySelectorUtilities.CurrencyCode(currency)
            XCTAssertNil(CurrencySelectorUtilities.regionCode(for: code), "Expected nil for \(currency)")
        }
    }

    func testANGMapsToNL() {
        let ang = CurrencySelectorUtilities.CurrencyCode("ang")
        XCTAssertEqual(CurrencySelectorUtilities.regionCode(for: ang), "NL")
    }

    func testRegionCodeCaseInsensitive() {
        let lower = CurrencySelectorUtilities.CurrencyCode("usd")
        let upper = CurrencySelectorUtilities.CurrencyCode("USD")
        XCTAssertEqual(CurrencySelectorUtilities.regionCode(for: lower), "US")
        XCTAssertEqual(CurrencySelectorUtilities.regionCode(for: upper), "US")
    }

    func testFlagEmojiUSD() {
        let usd = CurrencySelectorUtilities.CurrencyCode("usd")
        XCTAssertEqual(CurrencySelectorUtilities.flagEmoji(for: usd), "🇺🇸")
    }

    func testFlagEmojiEUR() {
        let eur = CurrencySelectorUtilities.CurrencyCode("eur")
        XCTAssertEqual(CurrencySelectorUtilities.flagEmoji(for: eur), "🇪🇺")
    }

    func testFlagEmojiEmptyForUnmappedCurrency() {
        let xaf = CurrencySelectorUtilities.CurrencyCode("xaf")
        XCTAssertTrue(CurrencySelectorUtilities.flagEmoji(for: xaf).isEmpty)
    }

    // MARK: - Helpers

    private func makeSession(
        adaptivePricingActive: Bool = true,
        includeLocalizedPrices: Bool = true,
        includeExchangeRateFields: Bool = true,
        integrationAmount: Int = 1200,
        localAmount: Int = 1000
    ) -> STPCheckoutSession {
        CheckoutTestHelpers.makeAdaptivePricingSession(
            adaptivePricingActive: adaptivePricingActive,
            includeLocalizedPrices: includeLocalizedPrices,
            includeExchangeRateFields: includeExchangeRateFields,
            integrationAmount: integrationAmount,
            localAmount: localAmount
        )
    }
}

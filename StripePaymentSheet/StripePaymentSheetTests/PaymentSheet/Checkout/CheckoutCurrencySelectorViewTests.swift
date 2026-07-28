//
//  CheckoutCurrencySelectorViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/6/26.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutCurrencySelectorViewTests: XCTestCase {

    // MARK: - Auto-hide tests

    func testHiddenWhenAdaptivePricingIsUnavailableAtInitialization() async throws {
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration()
        )
        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        XCTAssertTrue(view.isHidden)
    }

    func testHiddenWhenAdaptivePricingNotActive() async throws {
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration()
        )
        let session = makeSession(adaptivePricingActive: false)
        try await checkout.commitSession(session)

        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        XCTAssertTrue(view.isHidden)
    }

    func testHiddenWhenLocalizedPricesEmpty() async throws {
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration()
        )
        let session = makeSession(includeLocalizedPrices: false)
        try await checkout.commitSession(session)

        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        XCTAssertTrue(view.isHidden)
    }

    func testHiddenWhenExchangeRateMetaNil() async throws {
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration()
        )
        let session = makeSession(includeExchangeRateFields: false)
        try await checkout.commitSession(session)

        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        XCTAssertTrue(view.isHidden)
    }

    func testVisibleWhenAdaptivePricingActive() async throws {
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration()
        )
        let session = makeSession()
        try await checkout.commitSession(session)

        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        XCTAssertFalse(view.isHidden)
    }

    func testTransitionsFromHiddenToVisibleOnSessionUpdate() async throws {
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration()
        )
        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        XCTAssertTrue(view.isHidden)

        let session = makeSession()
        try await checkout.commitSession(session)

        XCTAssertFalse(view.isHidden)
    }

    func testTransitionsFromVisibleToHiddenOnSessionUpdate() async throws {
        let session = makeSession()
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: session)
        )
        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        XCTAssertFalse(view.isHidden)

        let updatedSession = makeSession(adaptivePricingActive: false)
        try await checkout.commitSession(updatedSession)

        XCTAssertTrue(view.isHidden)
    }

    // MARK: - Analytics tests

    func testCurrencyToggledEventIncludesCheckoutSessionId() async throws {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousLogHistory }

        let session = CheckoutTestHelpers.makeOpenSession()
        let delegate = MockCurrencySelectorElementDelegate()
        let view = await CurrencySelectorElementUIView(
            session: session.makePublicSession(),
            delegate: delegate,
            appearance: .init()
        )

        view.twoOptionSelectorView(makeSelectorView(), didSelectItemWithId: "gbp")

        try await waitUntil {
            currencySelectorEvents(.adaptivePricingCurrencyToggled, in: analyticsClient).count == 1
        }
        let event = try XCTUnwrap(currencySelectorEvents(.adaptivePricingCurrencyToggled, in: analyticsClient).first)
        XCTAssertEqual(event["checkout_session_id"] as? String, session.id)
    }

    func testCurrencyToggledFailedEventIncludesCheckoutSessionId() async throws {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousLogHistory }

        let session = CheckoutTestHelpers.makeOpenSession()
        let delegate = MockCurrencySelectorElementDelegate(error: CurrencySelectorElementTestError())
        let view = await CurrencySelectorElementUIView(
            session: session.makePublicSession(),
            delegate: delegate,
            appearance: .init()
        )

        view.twoOptionSelectorView(makeSelectorView(), didSelectItemWithId: "gbp")

        try await waitUntil {
            currencySelectorEvents(.adaptivePricingCurrencyToggledFailed, in: analyticsClient).count == 1
        }
        let event = try XCTUnwrap(currencySelectorEvents(.adaptivePricingCurrencyToggledFailed, in: analyticsClient).first)
        XCTAssertEqual(event["checkout_session_id"] as? String, session.id)
    }

    func testFlagImageLoadFailedEventsIncludeCheckoutSessionId() async throws {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousLogHistory }

        _ = CheckoutTestHelpers.makeStubbedAPIClient()
        let session = makeSession()
        let manager = AdaptivePricingFlagImageManager(analyticsClient: analyticsClient)

        await manager.prefetchFlagImages(for: session.makePublicSession())

        let events = currencySelectorEvents(.adaptivePricingFlagImageLoadFailed, in: analyticsClient)
        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events.allSatisfy { $0["checkout_session_id"] as? String == session.id })
    }

    // MARK: - Label update tests

    func testLabelsUpdateWhenSessionAmountChanges() async throws {
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        configuration.currencySelectorElement.appearance.labelContent = .amount
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(configuration: configuration)
        )
        let session = makeSession(integrationAmount: 1200, localAmount: 1000)
        try await checkout.commitSession(session)

        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        let selectorView = view.subviews.compactMap { ($0 as? UIStackView)?.arrangedSubviews.compactMap { $0 as? TwoOptionSelectorView }.first }.first
        XCTAssertNotNil(selectorView)
        XCTAssertTrue(selectorView!.leftItem.displayText.string.contains("10"))
        XCTAssertTrue(selectorView!.rightItem.displayText.string.contains("12"))

        let updatedSession = makeSession(integrationAmount: 2400, localAmount: 2000)
        try await checkout.commitSession(updatedSession)

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

    private func makeSelectorView() -> TwoOptionSelectorView {
        TwoOptionSelectorView(
            leftItem: makeSelectorItem(id: "usd"),
            rightItem: makeSelectorItem(id: "gbp"),
            selectedItemId: "usd",
            appearance: CurrencySelectorElement.Appearance()
        )
    }

    private func makeSelectorItem(id: String) -> TwoOptionSelectorItem {
        TwoOptionSelectorItem(
            id: id,
            displayText: NSAttributedString(string: id.uppercased()),
            accessibilityLabel: id.uppercased(),
            accessibilityIdentifier: id
        )
    }

    private func currencySelectorEvents(
        _ event: STPAnalyticEvent,
        in analyticsClient: STPAnalyticsClient
    ) -> [[String: Any]] {
        analyticsClient._testLogHistory.filter {
            $0["event"] as? String == event.rawValue
        }
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline {
                XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
                throw CurrencySelectorViewTestTimeoutError()
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func makeSession(
        adaptivePricingActive: Bool = true,
        includeLocalizedPrices: Bool = true,
        includeExchangeRateFields: Bool = true,
        integrationAmount: Int = 1200,
        localAmount: Int = 1000
    ) -> PaymentPagesAPIResponse {
        CheckoutTestHelpers.makeAdaptivePricingSession(
            adaptivePricingActive: adaptivePricingActive,
            includeLocalizedPrices: includeLocalizedPrices,
            includeExchangeRateFields: includeExchangeRateFields,
            integrationAmount: integrationAmount,
            localAmount: localAmount
        )
    }
}

private final class MockCurrencySelectorElementDelegate: CurrencySelectorElementDelegate {
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func selectCurrency(_ currency: String) async throws {
        if let error {
            throw error
        }
    }
}

private struct CurrencySelectorElementTestError: Error {}

private struct CurrencySelectorViewTestTimeoutError: Error {}

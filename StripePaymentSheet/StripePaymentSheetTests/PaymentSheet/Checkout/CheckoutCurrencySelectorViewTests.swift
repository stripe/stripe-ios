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

    // MARK: - Availability tests

    func testUnavailableWhenAdaptivePricingDataIsUnavailableAtInitialization() async throws {
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration()
        )

        XCTAssertNil(checkout.getCurrencySelectorElement())
    }

    func testAvailableWhenAdaptivePricingActive() async throws {
        let session = makeSession()
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: session)
        )

        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView

        XCTAssertFalse(view.isHidden)
    }

    // MARK: - Label update tests

    func testLabelsUpdateWhenSessionAmountChanges() async throws {
        var configuration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        var currencySelectorConfiguration = CurrencySelectorElement.Configuration()
        currencySelectorConfiguration.appearance.labelContent = .amount
        configuration.currencySelectorElement = currencySelectorConfiguration
        let session = makeSession(integrationAmount: 1200, localAmount: 1000)
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(
                apiResponse: session,
                configuration: configuration
            )
        )

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

    // MARK: - Height update tests

    func testNotifiesDelegateInsideAnimationWhenDetailsChangeHeight() async throws {
        // Given a currency selector in a merchant-owned container
        let session = makeSession()
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: session)
        )
        let element = try XCTUnwrap(checkout.getCurrencySelectorElement())
        let view = element.uiView
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 500))
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        containerView.layoutIfNeeded()
        let collapsedHeight = view.frame.height
        let delegate = CurrencySelectorElementDelegateMock {
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
        }
        element.delegate = delegate

        // When the customer expands the details
        currencySelector(in: view)?.expandableDetailView.toggleExpansion()

        // Then the merchant can animate its surrounding layout from the delegate callback
        XCTAssertEqual(delegate.heightUpdateCallCount, 1)
        XCTAssertGreaterThan(delegate.inheritedAnimationDuration, 0)
        XCTAssertGreaterThan(view.frame.height, collapsedHeight)
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
        integrationAmount: Int = 1200,
        localAmount: Int = 1000
    ) -> PaymentPagesAPIResponse {
        CheckoutTestHelpers.makeAdaptivePricingSession(
            integrationAmount: integrationAmount,
            localAmount: localAmount
        )
    }

    private func currencySelector(in view: CurrencySelectorElementUIView) -> TwoOptionSelectorView? {
        return view.subviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.compactMap { $0 as? TwoOptionSelectorView }.first }
            .first
    }
}

@MainActor
private final class CurrencySelectorElementDelegateMock: CurrencySelectorElementDelegate {
    private let updateLayout: () -> Void

    private(set) var heightUpdateCallCount = 0
    private(set) var inheritedAnimationDuration: TimeInterval = 0

    init(updateLayout: @escaping () -> Void) {
        self.updateLayout = updateLayout
    }

    func currencySelectorElementDidUpdateHeight(currencySelectorElement: CurrencySelectorElement) {
        heightUpdateCallCount += 1
        inheritedAnimationDuration = UIView.inheritedAnimationDuration
        updateLayout()
    }
}

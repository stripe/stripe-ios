//
//  CheckoutCurrencySelectorViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/6/26.
//

import Combine
import OHHTTPStubs
import OHHTTPStubsSwift
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

    func testSelectedCurrencyUpdatesWhenSessionCurrencyChanges() async throws {
        // Given a currency selector with USD selected
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: makeSession())
        )
        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView
        let selector = try XCTUnwrap(currencySelector(in: view))

        // When the Checkout Session changes to GBP
        try await checkout.commitSession(makeSession(currency: "gbp"))
        await waitForViewUpdate()

        // Then the selector agrees with the Checkout Session
        XCTAssertEqual(selector.selectedItemId, checkout.session.presentmentDetails?.presentmentCurrency)
    }

    func testFailedPaymentElementRefreshKeepsUpdatedSessionCurrencySelected() async throws {
        // Given a currency selector with USD selected and a currency update that returns GBP
        let initialSession = makeSession()
        let configuration = CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: initialSession)
        let updatedSessionJSON = makeSessionJSON(currency: "gbp", paymentMethodTypes: [])
        let sessionId = initialSession.sessionId
        stub(condition: { request in
            request.httpMethod == "POST" && request.url?.path == "/v1/payment_pages/\(sessionId)"
        }) { _ in
            HTTPStubsResponse(jsonObject: updatedSessionJSON, statusCode: 200, headers: nil)
        }
        let checkout = try await CheckoutController(configuration: configuration)
        let view = try XCTUnwrap(checkout.getCurrencySelectorElement()).uiView
        let selector = try XCTUnwrap(currencySelector(in: view))
        let updateFinished = expectation(description: "Currency update finishes")
        var didStartUpdate = false
        let updateSubscription = checkout.$isUpdating.sink { isUpdating in
            if isUpdating {
                didStartUpdate = true
            } else if didStartUpdate {
                updateFinished.fulfill()
            }
        }

        // When the customer selects GBP and Payment Element cannot reload
        selector.select("gbp", notifyDelegate: true)
        await fulfillment(of: [updateFinished], timeout: 2)
        withExtendedLifetime(updateSubscription) {}
        await waitForViewUpdate()

        // Then the selector shows the error without reverting the updated session currency
        XCTAssertNotNil(errorLabel(in: view)?.text)
        XCTAssertEqual(selector.selectedItemId, checkout.session.presentmentDetails?.presentmentCurrency)
        XCTAssertEqual(checkout.session.presentmentDetails?.presentmentCurrency, "gbp")
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

    func testCollapsingDetailsRestoresHeightAndSurroundingLayout() async throws {
        // Given a currency selector with content below it in a merchant-owned stack
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: makeSession())
        )
        let element = try XCTUnwrap(checkout.getCurrencySelectorElement())
        let footer = UIView()
        footer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        let stackView = UIStackView(arrangedSubviews: [element.uiView, footer])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 500))
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        let delegate = CurrencySelectorElementDelegateMock {
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
        }
        element.delegate = delegate
        containerView.layoutIfNeeded()
        let collapsedHeight = element.uiView.frame.height
        let initialFooterY = footer.frame.minY
        let selector = try XCTUnwrap(currencySelector(in: element.uiView))

        // When the customer expands the details
        let expansionCompleted = expectation(description: "Expansion completes before collapsing")
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            expansionCompleted.fulfill()
        }
        UIView.performWithoutAnimation {
            selector.expandableDetailView.toggleExpansion()
        }
        CATransaction.commit()
        await fulfillment(of: [expansionCompleted], timeout: 1)

        // Then the selector grows and moves the content below it
        XCTAssertGreaterThan(element.uiView.frame.height, collapsedHeight)
        XCTAssertGreaterThan(footer.frame.minY, initialFooterY)
        XCTAssertEqual(footer.frame.minY, element.uiView.frame.maxY, accuracy: 0.5)

        // When the customer collapses the details
        UIView.performWithoutAnimation {
            selector.expandableDetailView.toggleExpansion()
        }

        // Then both views return to their original positions and sizes
        XCTAssertEqual(delegate.heightUpdateCallCount, 2)
        XCTAssertEqual(element.uiView.frame.height, collapsedHeight, accuracy: 0.5)
        XCTAssertEqual(footer.frame.minY, initialFooterY, accuracy: 0.5)
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
        currency: String = "usd",
        integrationAmount: Int = 1200,
        localAmount: Int = 1000
    ) -> PaymentPagesAPIResponse {
        CheckoutTestHelpers.makeAdaptivePricingSession(
            currency: currency,
            integrationAmount: integrationAmount,
            localAmount: localAmount
        )
    }

    private func makeSessionJSON(
        currency: String,
        paymentMethodTypes: [String]
    ) -> [AnyHashable: Any] {
        var json = CheckoutTestHelpers.openSessionJSON
        json["currency"] = currency
        json["payment_method_types"] = paymentMethodTypes
        json["checkout_items"] = CheckoutTestHelpers.makeOneTimePriceCheckoutItems(currency: currency)
        json["elements_session"] = [
            "session_id": "es_test",
            "merchant_country": "US",
            "payment_method_preference": ["ordered_payment_method_types": paymentMethodTypes],
        ]
        json["adaptive_pricing_info"] = [
            "integration_currency": "usd",
            "integration_amount": 1200,
            "active_presentment_currency": currency,
            "local_currency_options": [
                [
                    "currency": "gbp",
                    "amount": 1000,
                    "presentment_exchange_rate": "0.776917",
                    "conversion_markup_bps": 400,
                ],
            ],
        ]
        return json
    }

    private func waitForViewUpdate() async {
        let viewUpdate = expectation(description: "Currency selector updates")
        DispatchQueue.main.async {
            viewUpdate.fulfill()
        }
        await fulfillment(of: [viewUpdate], timeout: 1)
    }

    private func currencySelector(in view: CurrencySelectorElementUIView) -> TwoOptionSelectorView? {
        return view.subviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.compactMap { $0 as? TwoOptionSelectorView }.first }
            .first
    }

    private func errorLabel(in view: CurrencySelectorElementUIView) -> UILabel? {
        return view.subviews
            .compactMap { $0 as? UIStackView }
            .flatMap(\.arrangedSubviews)
            .compactMap { $0 as? UILabel }
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

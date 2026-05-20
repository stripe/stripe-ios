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

    func testHiddenWhenAdaptivePricingNotActive() async {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession(adaptivePricingActive: false)
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        // Give Combine time to deliver
        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testHiddenWhenLocalizedPricesEmpty() async {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession(includeLocalizedPrices: false)
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testHiddenWhenExchangeRateMetaNil() async {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession(includeExchangeRateFields: false)
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testVisibleWhenAdaptivePricingActive() async {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let session = makeSession()
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertFalse(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testTransitionsFromHiddenToVisibleOnSessionUpdate() async {
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
        let view = Checkout.CurrencySelectorView(checkout: checkout)

        // Initially hidden
        XCTAssertTrue(view.isHidden)

        // Update with AP session
        let session = makeSession()
        checkout.updateSession(session)

        let expectation = expectation(description: "View becomes visible")
        DispatchQueue.main.async {
            XCTAssertFalse(view.isHidden)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeSession(
        adaptivePricingActive: Bool = true,
        includeLocalizedPrices: Bool = true,
        includeExchangeRateFields: Bool = true
    ) -> STPCheckoutSession {
        CheckoutTestHelpers.makeAdaptivePricingSession(
            adaptivePricingActive: adaptivePricingActive,
            includeLocalizedPrices: includeLocalizedPrices,
            includeExchangeRateFields: includeExchangeRateFields
        )
    }
}

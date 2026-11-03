import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
import UIKit
import XCTest

/// Uses the real test backend, without recorded or mocked responses.
@MainActor
final class CheckoutSupportedFlowsLiveTests: XCTestCase {
    override func setUp() {
        super.setUp()
        HTTPStubs.removeAllStubs()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        LinkAccountContext.shared.account = nil
        super.tearDown()
    }

    func testCOPFormattedTotalPreservesFractionalAmount() async throws {
        let checkout = try await makeCheckout(currency: "cop", amount: 1_234_567)
        XCTAssertEqual(checkout.session.currency, "cop")
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 1_234_567)
        let expected = NumberFormatter()
        expected.locale = .autoupdatingCurrent
        expected.numberStyle = .currency
        expected.currencyCode = "cop"
        expected.minimumFractionDigits = 2
        expected.maximumFractionDigits = 2
        XCTAssertEqual(checkout.session.totals.total.amount, expected.string(from: NSDecimalNumber(string: "12345.67")))
    }

    func testJPYFormattedTotalRemainsWholeUnits() async throws {
        let checkout = try await makeCheckout(currency: "jpy", amount: 1234)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 1234)
        let expected = NumberFormatter()
        expected.locale = .autoupdatingCurrent
        expected.numberStyle = .currency
        expected.currencyCode = "jpy"
        expected.minimumFractionDigits = 0
        expected.maximumFractionDigits = 0
        XCTAssertEqual(checkout.session.totals.total.amount, expected.string(from: 1234))
    }

    func testGuidePayButtonAllowsPurchaseWithoutShipping() async throws {
        // Given the guide's supported choice to omit shipping collection
        let checkout = try await makeCheckout()
        selectCard(on: checkout)
        XCTAssertEqual(checkout.session.status, .open)
        XCTAssertNotNil(checkout.session.email)
        XCTAssertNil(checkout.session.shippingAddress)

        // When the merchant copies updatePayButton from Render the order summary
        let guideEnablesPay = !checkout.isUpdating
            && checkout.session.paymentOption != nil
            && checkout.session.shippingAddress != nil

        // Then Pay should be enabled for this otherwise-complete non-shipping purchase
        XCTAssertTrue(guideEnablesPay, "The guide's unconditional shipping guard disables a valid purchase")
        let result = await checkout.confirm(from: UIViewController())
        guard case .completed(.paid) = result else {
            return XCTFail("Expected successful non-shipping purchase: \(result)")
        }
    }

    func testGuideServerCreatePayloadLoadsAndConfirms() async throws {
        // Given the server payload copied from setup.md, including its omitted top-level currency
        let parameters: [String: Any] = [
            "ui_mode": "mobile_elements",
            "customer_email": "jenny.rosen@example.com",
            "shipping_address_collection": ["allowed_countries": ["US", "CA"]],
            "items": [
                [
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "price_data": [
                                    "currency": "usd",
                                    "unit_amount": 5000,
                                    "product_data": ["name": "Painting class fee", "description": "1-hour painting class"],
                                ],
                                "quantity": 1,
                            ],
                        ],
                    ],
                ],
            ],
        ]
        let response = try await STPTestingAPIClient.shared.createCheckoutSession(sessionParametersOverride: parameters)
        // The guide requires registering the return URL; use the test host's registered scheme.
        var configuration = CheckoutController.Configuration(
            clientSecret: response.clientSecret, returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: response.publishableKey)
        configuration.paymentElement = .init()
        let checkout = try await CheckoutController(configuration: configuration)
        XCTAssertEqual(checkout.session.currency, "usd")
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5000)
        try await checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "510 Townsend St", city: "San Francisco", state: "CA", postalCode: "94103")
        )
        selectCard(on: checkout)
        let result = await checkout.confirm(from: UIViewController())
        guard case .completed(.paid) = result else {
            return XCTFail("Expected guide-created session to complete: \(result)")
        }
    }

    func testDeclineThenRetryCompletesSameSession() async throws {
        let checkout = try await makeCheckout()
        let sessionID = checkout.session.id
        selectCard(on: checkout, number: "4000000000000002")
        let decline = await checkout.confirm(from: UIViewController())
        guard case .failed(let error) = decline else {
            return XCTFail("Expected card decline: \(decline)")
        }
        XCTAssertEqual(error._stp_error_code, "card_declined")
        XCTAssertEqual(checkout.session.status, .open)
        XCTAssertFalse(checkout.isUpdating)
        selectCard(on: checkout)
        let retry = await checkout.confirm(from: UIViewController())
        guard case .completed(.paid) = retry else {
            return XCTFail("Expected successful retry: \(retry)")
        }
        XCTAssertEqual(checkout.session.id, sessionID)
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }

    func testDuplicateAndTerminalConfirmationAreRejected() async throws {
        let checkout = try await makeCheckout()
        selectCard(on: checkout)
        let started = expectation(description: "Real confirmation request started")
        started.assertForOverFulfill = false
        let observer = stub { request in
            if request.url?.path.hasSuffix("/confirm") == true {
                started.fulfill()
            }
            return false
        } response: { _ in
            XCTFail("Observer must never supply a response")
            return HTTPStubsResponse()
        }
        let first = Task { await checkout.confirm(from: UIViewController()) }
        await fulfillment(of: [started], timeout: 15)
        HTTPStubs.removeStub(observer)
        XCTAssertTrue(checkout.confirmationInProgress)
        let duplicate = await checkout.confirm(from: UIViewController())
        guard case .failed(let duplicateError) = duplicate else {
            return XCTFail("Expected duplicate rejection: \(duplicate)")
        }
        guard case PaymentSheetError.integrationError(let duplicateMessage) = duplicateError else {
            return XCTFail("Expected duplicate integration error: \(duplicateError)")
        }
        XCTAssertTrue(duplicateMessage.contains("second confirmation"))
        let original = await first.value
        guard case .completed(.paid) = original else {
            return XCTFail("Expected original confirmation success: \(original)")
        }
        let terminal = await checkout.confirm(from: UIViewController())
        guard case .failed(let terminalError) = terminal else {
            return XCTFail("Expected closed-session rejection: \(terminal)")
        }
        guard case PaymentSheetError.integrationError(let terminalMessage) = terminalError else {
            return XCTFail("Expected closed-session integration error: \(terminalError)")
        }
        XCTAssertTrue(terminalMessage.contains("no longer open"))
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }

    func testZeroAmountConfirmsWithoutPaymentMethod() async throws {
        let checkout = try await makeCheckout(amount: 0)
        XCTAssertNil(checkout.session.paymentOption)
        let result = await checkout.confirm(from: UIViewController())
        guard case .completed(.noPaymentRequired) = result else {
            return XCTFail("Expected free checkout success: \(result)")
        }
        XCTAssertEqual(checkout.session.status, .complete(.noPaymentRequired))
    }

    func testAdaptivePricingRoundTrip() async throws {
        let response = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax", customerEmailLocation: "DE"
        )
        var configuration = CheckoutController.Configuration(
            clientSecret: response.clientSecret, returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: response.publishableKey)
        configuration.currencySelectorElement = .init()
        let checkout = try await CheckoutController(configuration: configuration)
        XCTAssertEqual(checkout.session.presentmentDetails?.presentmentCurrency, "eur")
        let eurTotal = checkout.session.totals.total
        try await checkout.selectCurrency("usd")
        XCTAssertEqual(checkout.session.presentmentDetails?.presentmentCurrency, "usd")
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 2000)
        try await checkout.selectCurrency("eur")
        XCTAssertEqual(checkout.session.presentmentDetails?.presentmentCurrency, "eur")
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, eurTotal.minorUnitsAmount)
        XCTAssertEqual(checkout.session.totals.total.amount, eurTotal.amount)
    }

    func testUpdatedEmailReachesLinkWebParameters() async throws {
        // Given a successful real Link lookup for the merchant's initial local email
        let initialEmail = "checkout-audit-\(UUID().uuidString.lowercased())@example.com"
        let updatedEmail = "checkout-audit-\(UUID().uuidString.lowercased())@example.com"
        let response = try await STPTestingAPIClient.shared.createCheckoutSession(types: ["card", "link"])
        var configuration = CheckoutController.Configuration(
            clientSecret: response.clientSecret, returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: response.publishableKey)
        configuration.paymentElement = .init()
        configuration.defaults.email = initialEmail
        let checkout = try await CheckoutController(configuration: configuration)
        let element = checkout.getPaymentElement()
        XCTAssertTrue(PaymentSheet.isLinkEnabled(
            elementsSession: checkout.session.elementsSession,
            configuration: element.paymentSheetFlowController.configuration
        ))
        XCTAssertEqual(try XCTUnwrap(LinkAccountContext.shared.account).email, initialEmail)

        // When the merchant updates the email before opening Link
        try await checkout.updateEmail(updatedEmail)

        // Then the session, Payment Element, and Link web handoff should agree
        XCTAssertEqual(checkout.session.email, updatedEmail)
        let paymentConfiguration = element.paymentSheetFlowController.configuration
        XCTAssertEqual(paymentConfiguration.defaultBillingDetails.email, updatedEmail)
        let linkParams = try LinkURLGenerator.linkParams(
            configuration: paymentConfiguration,
            intent: .checkout(checkout.session),
            elementsSession: checkout.session.elementsSession,
            checkoutAttribution: .init(confirmingElement: .paymentElement, configuredElements: [.paymentElement])
        )
        XCTAssertEqual(linkParams.customerInfo.email, updatedEmail)
    }

    private func makeCheckout(currency: String = "usd", amount: Int = 1000) async throws -> CheckoutController {
        let response = try await STPTestingAPIClient.shared.createCheckoutSession(
            currency: currency, amount: amount, customerEmail: "checkout-audit@example.com"
        )
        var configuration = CheckoutController.Configuration(
            clientSecret: response.clientSecret, returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: response.publishableKey)
        configuration.paymentElement = .init()
        let checkout = try await CheckoutController(configuration: configuration)
        XCTAssertFalse(checkout.session.livemode)
        return checkout
    }

    private func selectCard(on checkout: CheckoutController, number: String = "4242424242424242") {
        let element = checkout.getPaymentElement()
        let params = IntentConfirmParams(type: .stripe(.card))
        params.paymentMethodParams.card = STPPaymentMethodCardParams()
        params.paymentMethodParams.card?.number = number
        params.paymentMethodParams.card?.expMonth = 12
        params.paymentMethodParams.card?.expYear = 2040
        params.paymentMethodParams.card?.cvc = "123"
        element.embeddedPaymentElement._test_paymentOption = .new(confirmParams: params)
        element.embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: element.embeddedPaymentElement)
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "card")
    }
}

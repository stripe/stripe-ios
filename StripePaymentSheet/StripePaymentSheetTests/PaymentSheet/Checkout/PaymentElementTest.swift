//
//  PaymentElementTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 7/15/26.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
@testable @_spi(STP) import StripeUICore
import XCTest

@MainActor
final class PaymentElementTest: XCTestCase {

    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testConfigurationSetsCheckoutDefaultBillingDetails() async throws {
        // Given Checkout billing defaults
        var checkoutConfiguration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        checkoutConfiguration.defaults = .init(
            billingDetails: Checkout.Configuration.Defaults.BillingDetails(
                name: "Jane Doe",
                address: .init(
                    country: "US",
                    line1: "123 Main St",
                    line2: "Apt 4",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94105"
                )
            )
        )

        // When Checkout creates PaymentElement
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(configuration: checkoutConfiguration)
        )
        let paymentElement = checkout.getPaymentElement()
        let paymentSheetConfiguration = paymentElement.paymentSheetFlowController.configuration
        let embeddedConfiguration = paymentElement.embeddedPaymentElement.configuration

        // Then both configurations receive the same default billing details
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.name, "Jane Doe")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.country, "US")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.line1, "123 Main St")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.line2, "Apt 4")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.city, "San Francisco")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.state, "CA")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.postalCode, "94105")

        XCTAssertEqual(embeddedConfiguration.defaultBillingDetails, paymentSheetConfiguration.defaultBillingDetails)
    }

    func testConfigurationSetsFullBillingAddressCollectionWhenCheckoutRequiresBillingAddress() async throws {
        // Given automatic billing address collection in PaymentElement
        let checkoutConfiguration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        let session = CheckoutTestHelpers.makeOpenSession(billingAddressCollection: "required")

        // When Checkout requires billing address collection
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(
                apiResponse: session,
                configuration: checkoutConfiguration
            )
        )
        let paymentElement = checkout.getPaymentElement()

        // Then both configurations collect full billing address
        XCTAssertEqual(paymentElement.paymentSheetFlowController.configuration.billingDetailsCollectionConfiguration.address, .full)
        XCTAssertEqual(paymentElement.embeddedPaymentElement.configuration.billingDetailsCollectionConfiguration.address, .full)
    }

    func testConfigurationPreservesFullBillingAddressCollectionWhenCheckoutBillingAddressCollectionIsAutomatic() async throws {
        // Given full billing address collection in PaymentElement
        var checkoutConfiguration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        checkoutConfiguration.paymentElement.billingDetailsCollectionConfiguration.address = .full

        // When Checkout uses automatic billing address collection
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(configuration: checkoutConfiguration)
        )
        let paymentElement = checkout.getPaymentElement()

        // Then both configurations preserve full billing address collection
        XCTAssertEqual(paymentElement.paymentSheetFlowController.configuration.billingDetailsCollectionConfiguration.address, .full)
        XCTAssertEqual(paymentElement.embeddedPaymentElement.configuration.billingDetailsCollectionConfiguration.address, .full)
    }

    func testCheckoutSessionUpdatePreservesFlowControllerPaymentOption() async throws {
        // Given a Checkout PaymentElement with PayNow available in the real FlowController sheet UI...
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.paymentElement.paymentMethodLayout = .vertical
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(
                apiResponse: Self.makeOpenSession(paymentMethodTypes: ["card", "paynow"]),
                configuration: configuration
            )
        )
        let paymentElement = checkout.getPaymentElement()
        let viewController = try XCTUnwrap(
            paymentElement.paymentSheetFlowController.viewController as? PaymentSheetVerticalViewController
        )
        let paymentMethodListViewController = try XCTUnwrap(viewController.paymentMethodListViewController)
        XCTAssertNil(paymentMethodListViewController.currentSelection)
        XCTAssertNil(checkout.session.paymentOption)

        // When the customer selects PayNow in FlowController and Checkout commits a session update...
        let payNowRowButton = try XCTUnwrap(
            paymentMethodListViewController.rowButtons.first { $0.accessibilityIdentifier == "PayNow" },
            "Available rows: \(paymentMethodListViewController.rowButtons.compactMap(\.accessibilityIdentifier))"
        )
        paymentMethodListViewController.didTap(
            rowButton: payNowRowButton,
            selection: .new(paymentMethodType: .stripe(.paynow))
        )
        paymentElement.paymentSheetFlowController.updatePaymentOption()
        XCTAssertEqual(checkout.session.paymentOption?.label, "PayNow")
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "paynow")

        let completedSession = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: {
            var json = Self.openSessionJSON(paymentMethodTypes: ["card", "paynow"])
            json["status"] = "complete"
            json["payment_status"] = "paid"
            return json
        }())!
        try await checkout.commitSession(completedSession)

        // Then the Checkout payment option still reflects FlowController's selected payment option.
        XCTAssertEqual(checkout.session.paymentOption?.label, "PayNow")
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "paynow")
    }

    func testCheckoutAndElementsDoNotRetainEachOther() async throws {
        weak var weakCheckout: Checkout?
        weak var weakPaymentElement: PaymentElement?
        weak var weakCurrencySelectorElement: CurrencySelectorElement?
        weak var weakCurrencySelectorUIView: CurrencySelectorElementUIView?
        weak var weakFlowController: PaymentSheet.FlowController?
        weak var weakEmbeddedPaymentElement: EmbeddedPaymentElement?

        do {
            let checkout = try await Checkout(
                configuration: CheckoutTestHelpers.makeConfiguration(
                    apiResponse: Self.makeOpenSession(paymentMethodTypes: ["card"])
                )
            )
            let paymentElement = checkout.getPaymentElement()
            let currencySelectorElement = checkout.getCurrencySelectorElement()

            weakCheckout = checkout
            weakPaymentElement = paymentElement
            weakCurrencySelectorElement = currencySelectorElement
            weakCurrencySelectorUIView = currencySelectorElement.uiView
            weakFlowController = paymentElement.paymentSheetFlowController
            weakEmbeddedPaymentElement = paymentElement.embeddedPaymentElement
        }

        XCTAssertNil(weakCheckout)
        XCTAssertNil(weakPaymentElement)
        XCTAssertNil(weakCurrencySelectorElement)
        XCTAssertNil(weakCurrencySelectorUIView)
        XCTAssertNil(weakFlowController)
        XCTAssertNil(weakEmbeddedPaymentElement)
    }

    private static func makeOpenSession(paymentMethodTypes: [String]) -> PaymentPagesAPIResponse {
        return PaymentPagesAPIResponse.decodedObject(
            fromAPIResponse: openSessionJSON(paymentMethodTypes: paymentMethodTypes)
        )!
    }

    private static func openSessionJSON(paymentMethodTypes: [String]) -> [AnyHashable: Any] {
        var elementsSessionJSON = CheckoutTestHelpers.minimalElementsSessionJSON
        elementsSessionJSON["payment_method_preference"] = [
            "ordered_payment_method_types": paymentMethodTypes,
        ]

        var json = CheckoutTestHelpers.openSessionJSON
        json["payment_method_types"] = paymentMethodTypes
        json["elements_session"] = elementsSessionJSON
        json["total_summary"] = [
            "subtotal": 1099,
            "total": 1099,
            "due": 1099,
        ]
        return json
    }
}

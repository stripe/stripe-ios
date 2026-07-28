//
//  PaymentElementTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 7/15/26.
//

import OHHTTPStubs
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
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
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        super.tearDown()
    }

    func testConfigurationSetsCheckoutDefaultBillingDetails() async throws {
        // Given Checkout billing defaults
        var checkoutConfiguration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        var billingDetails = Checkout.Configuration.Defaults.BillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.address = .init(
            country: "US",
            line1: "123 Main St",
            line2: "Apt 4",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105"
        )
        checkoutConfiguration.defaults.billingDetails = billingDetails

        // When Checkout creates PaymentElement
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(configuration: checkoutConfiguration)
        )
        let paymentElement = checkout.getPaymentElement()
        let paymentSheetConfiguration = paymentElement.paymentSheetFlowController.configuration
        let embeddedConfiguration = paymentElement.embeddedPaymentElement.configuration

        // Then both configurations receive the same default billing details
        XCTAssertEqual(checkout.configuration.returnURL, "stripe-ios-test://checkout-return")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.name, "Jane Doe")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.country, "US")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.line1, "123 Main St")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.line2, "Apt 4")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.city, "San Francisco")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.state, "CA")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.postalCode, "94105")

        XCTAssertEqual(embeddedConfiguration.defaultBillingDetails, paymentSheetConfiguration.defaultBillingDetails)
    }

    func testConfigurationSetsCheckoutDefaultShippingDetails() async throws {
        // Given Checkout shipping defaults
        var checkoutConfiguration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        var shippingDetails = Checkout.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Jane Doe"
        shippingDetails.address = .init(
            country: "US",
            line1: "123 Main St",
            line2: "Apt 4",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105"
        )
        checkoutConfiguration.defaults.shippingDetails = shippingDetails

        // When Checkout creates PaymentElement
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(configuration: checkoutConfiguration)
        )
        let paymentElement = checkout.getPaymentElement()
        let paymentSheetShipping = paymentElement.paymentSheetFlowController.configuration.shippingDetails()
        let embeddedShipping = paymentElement.embeddedPaymentElement.configuration.shippingDetails()

        // Then both configurations receive the same default shipping details
        XCTAssertEqual(paymentSheetShipping?.name, "Jane Doe")
        XCTAssertEqual(paymentSheetShipping?.address.country, "US")
        XCTAssertEqual(paymentSheetShipping?.address.line1, "123 Main St")
        XCTAssertEqual(paymentSheetShipping?.address.line2, "Apt 4")
        XCTAssertEqual(paymentSheetShipping?.address.city, "San Francisco")
        XCTAssertEqual(paymentSheetShipping?.address.state, "CA")
        XCTAssertEqual(paymentSheetShipping?.address.postalCode, "94105")

        XCTAssertEqual(embeddedShipping?.name, paymentSheetShipping?.name)
        XCTAssertEqual(embeddedShipping?.address.country, paymentSheetShipping?.address.country)
        XCTAssertEqual(embeddedShipping?.address.line1, paymentSheetShipping?.address.line1)
        XCTAssertEqual(embeddedShipping?.address.line2, paymentSheetShipping?.address.line2)
        XCTAssertEqual(embeddedShipping?.address.city, paymentSheetShipping?.address.city)
        XCTAssertEqual(embeddedShipping?.address.state, paymentSheetShipping?.address.state)
        XCTAssertEqual(embeddedShipping?.address.postalCode, paymentSheetShipping?.address.postalCode)
    }

    func testConfigurationSetsFullBillingAddressCollectionWhenCheckoutRequiresBillingAddress() async throws {
        // Given automatic billing address collection in PaymentElement
        let checkoutConfiguration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
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
        var checkoutConfiguration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
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

    func testInitialSavedPaymentOptionUpdatesCheckoutBillingTaxRegion() async throws {
        // Given a Checkout Session with automatic tax sourced from billing and a saved card...
        let (configuration, requestRecorder) = try stubAutomaticTaxSavedCardCheckout()

        // When Checkout loads its PaymentElement...
        let checkout = try await Checkout(configuration: configuration)

        // Then the saved card's billing address is used to update the tax region...
        let requests = requestRecorder.requests
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        let updateRequest = try XCTUnwrap(requests.first { $0.kind == .updateSession })
        XCTAssertEqual(updateRequest.params["tax_region[country]"], "US")
        XCTAssertEqual(updateRequest.params["tax_region[line1]"], "354 Oyster Point Blvd")
        XCTAssertEqual(updateRequest.params["tax_region[city]"], "South San Francisco")
        XCTAssertEqual(updateRequest.params["tax_region[state]"], "CA")
        XCTAssertEqual(updateRequest.params["tax_region[postal_code]"], "94080")

        // ...and the saved card remains selected after PaymentElement refreshes.
        XCTAssertEqual(checkout.session.paymentOption?.label, "•••• 4242")
        XCTAssertEqual(checkout.session.paymentOption?.billingDetails?.address.country, "US")
    }

    func testCheckoutSessionUpdatePreservesFlowControllerPaymentOption() async throws {
        // Given a Checkout PaymentElement with PayNow available in the real FlowController sheet UI...
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
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

    func testSelectingSavedPaymentMethodInEmbeddedViewSyncsBillingAddress() async throws {
        // Given an unselected saved payment method and a Checkout Session using billing address for automatic tax
        let didSelectPaymentOption = expectation(description: "Saved payment method selection completes")
        let (checkout, embeddedPaymentElement, savedPaymentMethodRow, requestRecorder) =
            try await makeSavedPaymentMethodSelectionFixture(
            didSelectPaymentOption: {
                didSelectPaymentOption.fulfill()
            }
        )
        let embeddedView = embeddedPaymentElement.embeddedPaymentMethodsView
        let paymentMethodID = try XCTUnwrap(savedPaymentMethodRow.type.savedPaymentMethod?.stripeId)

        // When the customer selects the saved payment method directly, without opening a sheet
        embeddedView.didTap(rowButton: savedPaymentMethodRow)

        // Then the row shows a loader and Checkout keeps the previous selection while billing syncs
        XCTAssertTrue(savedPaymentMethodRow.isLoading)
        XCTAssertNil(checkout.session.paymentOption)
        await fulfillment(of: [didSelectPaymentOption])

        // ...and the billing country is synced before selection completes
        XCTAssertFalse(savedPaymentMethodRow.isLoading)
        let currentEmbeddedView = embeddedPaymentElement.embeddedPaymentMethodsView
        XCTAssertTrue(currentEmbeddedView.isUserInteractionEnabled)
        XCTAssertEqual(currentEmbeddedView.selectedRowButton?.type.savedPaymentMethod?.stripeId, paymentMethodID)
        let requests = requestRecorder.requests
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        XCTAssertEqual(try XCTUnwrap(requests.last).params["tax_region[country]"], "US")
    }

    func testSelectingSavedPaymentMethodInEmbeddedViewRevertsSelectionAndDisplaysBillingSyncError() async throws {
        // Given PayNow is selected and the Checkout billing address update will fail
        var didSelectPaymentOption = false
        let (checkout, embeddedPaymentElement, savedPaymentMethodRow, _) =
            try await makeSavedPaymentMethodSelectionFixture(
            paymentMethodTypes: ["card", "paynow"],
            updateStatusCode: 500,
            didSelectPaymentOption: {
                didSelectPaymentOption = true
            }
        )
        let embeddedView = embeddedPaymentElement.embeddedPaymentMethodsView
        let payNowRow = try XCTUnwrap(
            embeddedView.rowButtons.first {
                $0.type == .new(paymentMethodType: .stripe(.paynow))
            }
        )
        embeddedPaymentElement.presentingViewController = UIViewController()
        embeddedView.didTap(rowButton: payNowRow)
        embeddedPaymentElement._test_paymentOption = .new(
            confirmParams: IntentConfirmParams(type: .stripe(.paynow))
        )
        embeddedPaymentElement.informDelegateIfPaymentOptionUpdated()

        // When the customer selects a saved payment method
        let errorExpectation = notNullExpectation(for: embeddedView, keyPath: \._test_displayedErrorMessage)
        embeddedView.didTap(rowButton: savedPaymentMethodRow)
        await fulfillment(of: [errorExpectation])

        // Then the previous selection is restored and the error is displayed under EPE
        XCTAssertFalse(didSelectPaymentOption)
        XCTAssertFalse(savedPaymentMethodRow.isLoading)
        XCTAssertTrue(embeddedView.isUserInteractionEnabled)
        XCTAssertEqual(
            embeddedView.selectedRowButton?.type,
            .new(paymentMethodType: .stripe(.paynow))
        )
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "paynow")
        XCTAssertFalse(try XCTUnwrap(embeddedView._test_displayedErrorMessage).isEmpty)
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
                configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(
                    apiResponse: Self.makeOpenSession(paymentMethodTypes: ["card"])
                )
            )
            let paymentElement = checkout.getPaymentElement()
            let currencySelectorElement = checkout.getCurrencySelectorElement()

            weakCheckout = checkout
            weakPaymentElement = paymentElement
            weakCurrencySelectorElement = currencySelectorElement
            weakCurrencySelectorUIView = currencySelectorElement?.uiView
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

    /// `CheckoutSession.json` already has automatic tax sourced from billing and a saved card with a full billing address.
    private func stubAutomaticTaxSavedCardCheckout() throws -> (
        configuration: Checkout.Configuration,
        requestRecorder: CheckoutSessionRequestRecorder
    ) {
        let sessionJSON = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = try XCTUnwrap(PaymentPagesAPIResponse.decodedObject(fromAPIResponse: sessionJSON))
        let requestRecorder = CheckoutSessionRequestRecorder()
        let configuration = CheckoutTestHelpers.makeConfiguration(apiResponse: session)
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: session.id,
            requestRecorder: requestRecorder,
            sessionJSON: { sessionJSON }
        )
        return (configuration, requestRecorder)
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

    private func makeSavedPaymentMethodSelectionFixture(
        paymentMethodTypes: [String] = ["card"],
        updateStatusCode: Int32 = 200,
        didSelectPaymentOption: @escaping () -> Void
    ) async throws -> (
        checkout: Checkout,
        embeddedPaymentElement: EmbeddedPaymentElement,
        savedPaymentMethodRow: RowButton,
        requestRecorder: CheckoutSessionRequestRecorder
    ) {
        let requestRecorder = CheckoutSessionRequestRecorder()
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: paymentMethodTypes,
            customerSessionData: [:],
            paymentMethods: [
                STPPaymentMethod._testCard(countryCode: "US").allResponseFields,
            ]
        )
        var sessionJSON = Self.openSessionJSON(paymentMethodTypes: paymentMethodTypes)
        sessionJSON["elements_session"] = elementsSession.allResponseFields
        sessionJSON["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.billing",
        ]
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: "cs_test_123",
            requestRecorder: requestRecorder,
            sessionJSON: { sessionJSON },
            updateStatusCode: updateStatusCode
        )

        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement.rowSelectionBehavior = .immediateAction(
            didSelectPaymentOption: didSelectPaymentOption
        )

        let checkout = try await Checkout(configuration: configuration)
        let embeddedPaymentElement = checkout.getPaymentElement().embeddedPaymentElement
        let savedPaymentMethodRow = try XCTUnwrap(
            embeddedPaymentElement.embeddedPaymentMethodsView.rowButtons.first {
                $0.type.isSaved
            }
        )
        embeddedPaymentElement.clearPaymentOption()

        return (checkout, embeddedPaymentElement, savedPaymentMethodRow, requestRecorder)
    }

}

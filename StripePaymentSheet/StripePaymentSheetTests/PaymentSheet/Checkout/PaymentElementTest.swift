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
        let expectation = expectation(description: "Load address specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            expectation.fulfill()
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
        var checkoutConfiguration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        checkoutConfiguration.defaults.email = "test@example.com"
        checkoutConfiguration.defaults.phone = "+15555550123"
        var billingDetails = CheckoutController.Configuration.Defaults.BillingDetails()
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
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(configuration: checkoutConfiguration)
        )
        let paymentElement = checkout.getPaymentElement()
        let paymentSheetConfiguration = paymentElement.paymentSheetFlowController.configuration
        let embeddedConfiguration = paymentElement.embeddedPaymentElement.configuration

        // Then both configurations receive the same default billing details
        XCTAssertEqual(checkout.configuration.returnURL, "stripe-ios-test://checkout-return")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.email, "test@example.com")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.phone, "+15555550123")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.name, "Jane Doe")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.country, "US")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.line1, "123 Main St")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.line2, "Apt 4")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.city, "San Francisco")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.state, "CA")
        XCTAssertEqual(paymentSheetConfiguration.defaultBillingDetails.address.postalCode, "94105")

        XCTAssertEqual(embeddedConfiguration.defaultBillingDetails, paymentSheetConfiguration.defaultBillingDetails)
    }

    func testConfigurationSetsCheckoutMerchantDisplayName() async throws {
        // Given Checkout merchant display name
        var checkoutConfiguration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        checkoutConfiguration.merchantDisplayName = "Configured Merchant"
        checkoutConfiguration.userInterfaceStyle = .alwaysDark

        // When Checkout creates PaymentElement
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(
                apiResponse: Self.makeOpenSession(paymentMethodTypes: ["card"], businessName: "Dashboard Merchant"),
                configuration: checkoutConfiguration
            )
        )
        let paymentElement = checkout.getPaymentElement()
        let paymentSheetConfiguration = paymentElement.paymentSheetFlowController.configuration
        let embeddedConfiguration = paymentElement.embeddedPaymentElement.configuration

        // Then both configurations use the configured merchant display name
        XCTAssertEqual(paymentSheetConfiguration.merchantDisplayName, "Configured Merchant")
        XCTAssertEqual(embeddedConfiguration.merchantDisplayName, "Configured Merchant")
        XCTAssertEqual(paymentSheetConfiguration.style, .alwaysDark)
        XCTAssertEqual(embeddedConfiguration.style, .alwaysDark)
    }

    func testConfigurationDefaultsMerchantDisplayNameToCheckoutSessionBusinessName() async throws {
        // Given Checkout Session business name
        let checkoutConfiguration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")

        // When Checkout creates PaymentElement without an explicit merchant display name
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(
                apiResponse: Self.makeOpenSession(paymentMethodTypes: ["card"], businessName: "Dashboard Merchant"),
                configuration: checkoutConfiguration
            )
        )
        let paymentElement = checkout.getPaymentElement()
        let paymentSheetConfiguration = paymentElement.paymentSheetFlowController.configuration
        let embeddedConfiguration = paymentElement.embeddedPaymentElement.configuration

        // Then both configurations use the Checkout Session business name
        XCTAssertEqual(paymentSheetConfiguration.merchantDisplayName, "Dashboard Merchant")
        XCTAssertEqual(embeddedConfiguration.merchantDisplayName, "Dashboard Merchant")
    }

    func testConfigurationSetsApplePayFromCheckoutSessionMerchantCountry() async throws {
        // Given Apple Pay configured for a Checkout Session with a non-US merchant country
        var checkoutConfiguration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        checkoutConfiguration.paymentElement.applePay = PaymentElement.ApplePayConfiguration(
            merchantId: "merchant.com.example",
            buttonType: .donate
        )
        var sessionJSON = Self.openSessionJSON(paymentMethodTypes: ["card"])
        var elementsSessionJSON = sessionJSON["elements_session"] as! [String: Any]
        elementsSessionJSON["merchant_country"] = "GB"
        sessionJSON["elements_session"] = elementsSessionJSON

        // When Checkout creates PaymentElement
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(
                apiResponse: try PaymentPagesAPIResponse.decode(fromAPIResponse: sessionJSON),
                configuration: checkoutConfiguration
            )
        )
        let paymentElement = checkout.getPaymentElement()
        let paymentSheetApplePay = try XCTUnwrap(paymentElement.paymentSheetFlowController.configuration.applePay)
        let embeddedApplePay = try XCTUnwrap(paymentElement.embeddedPaymentElement.configuration.applePay)

        // Then both presentations use the merchant-provided settings and server-provided country
        XCTAssertEqual(paymentSheetApplePay.merchantId, "merchant.com.example")
        XCTAssertEqual(paymentSheetApplePay.buttonType, .donate)
        XCTAssertEqual(paymentSheetApplePay.merchantCountryCode, "GB")
        XCTAssertEqual(embeddedApplePay.merchantId, "merchant.com.example")
        XCTAssertEqual(embeddedApplePay.buttonType, .donate)
        XCTAssertEqual(embeddedApplePay.merchantCountryCode, "GB")
        XCTAssertEqual(paymentElement.paymentSheetFlowController.paymentOption?.paymentMethodType, "apple_pay")
        XCTAssertEqual(paymentElement.embeddedPaymentElement.paymentOption?.paymentMethodType, "apple_pay")
    }

    func testConfigurationAllowsAllCheckoutPaymentMethodRequirements() async throws {
        // Given a Checkout configuration
        let checkoutConfiguration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")

        // When Checkout creates PaymentElement
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(configuration: checkoutConfiguration)
        )
        let paymentElement = checkout.getPaymentElement()
        let paymentSheetConfiguration = paymentElement.paymentSheetFlowController.configuration
        let embeddedConfiguration = paymentElement.embeddedPaymentElement.configuration

        // Then both presentations allow payment methods supported by Checkout
        XCTAssertTrue(paymentSheetConfiguration.allowsDelayedPaymentMethods)
        XCTAssertTrue(paymentSheetConfiguration.allowsPaymentMethodsRequiringShippingAddress)
        XCTAssertTrue(embeddedConfiguration.allowsDelayedPaymentMethods)
        XCTAssertTrue(embeddedConfiguration.allowsPaymentMethodsRequiringShippingAddress)
    }
    func testConfigurationSetsCheckoutDefaultShippingDetails() async throws {
        // Given Checkout shipping defaults
        var checkoutConfiguration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
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
        let checkout = try await CheckoutController(
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
        let checkoutConfiguration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        let session = CheckoutTestHelpers.makeOpenSession(billingAddressCollection: "required")

        // When Checkout requires billing address collection
        let checkout = try await CheckoutController(
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
        var checkoutConfiguration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        checkoutConfiguration.paymentElement.billingDetailsCollectionConfiguration.address = .full

        // When Checkout uses automatic billing address collection
        let checkout = try await CheckoutController(
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
        let checkout = try await CheckoutController(configuration: configuration)

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
        var configuration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        configuration.paymentElement.paymentMethodLayout = .vertical
        let checkout = try await CheckoutController(
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

        let completedSession = try PaymentPagesAPIResponse.decode(fromAPIResponse: {
            var json = Self.openSessionJSON(paymentMethodTypes: ["card", "paynow"])
            json["status"] = "complete"
            json["payment_status"] = "paid"
            return json
        }())
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
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession, .updateSession])
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
        let errorExpectation = notNullExpectation(for: embeddedView, keyPath: \.errorLabel.text)
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
        XCTAssertFalse(try XCTUnwrap(embeddedView.errorLabel.text).isEmpty)
    }

    func testCheckoutAndElementsDoNotRetainEachOther() async throws {
        weak var weakCheckout: CheckoutController?
        weak var weakPaymentElement: PaymentElement?
        weak var weakCurrencySelectorElement: CurrencySelectorElement?
        weak var weakCurrencySelectorUIView: CurrencySelectorElementUIView?
        weak var weakFlowController: PaymentSheet.FlowController?
        weak var weakEmbeddedPaymentElement: EmbeddedPaymentElement?

        do {
            let checkout = try await CheckoutController(
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
        configuration: CheckoutController.Configuration,
        requestRecorder: CheckoutSessionRequestRecorder
    ) {
        let sessionJSON = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: sessionJSON)
        let requestRecorder = CheckoutSessionRequestRecorder()
        let configuration = CheckoutTestHelpers.makeConfiguration(apiResponse: session)
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: session.sessionId,
            requestRecorder: requestRecorder,
            sessionJSON: { sessionJSON }
        )
        return (configuration, requestRecorder)
    }

    private static func makeOpenSession(paymentMethodTypes: [String], businessName: String? = nil) -> PaymentPagesAPIResponse {
        return try! PaymentPagesAPIResponse.decode(
            fromAPIResponse: openSessionJSON(paymentMethodTypes: paymentMethodTypes, businessName: businessName)
        )
    }

    private static func openSessionJSON(paymentMethodTypes: [String], businessName: String? = nil) -> [AnyHashable: Any] {
        var elementsSessionJSON = CheckoutTestHelpers.minimalElementsSessionJSON
        elementsSessionJSON["payment_method_preference"] = [
            "ordered_payment_method_types": paymentMethodTypes,
        ]
        elementsSessionJSON["business_name"] = businessName

        var json = CheckoutTestHelpers.openSessionJSON
        json["payment_method_types"] = paymentMethodTypes
        json["elements_session"] = elementsSessionJSON
        return json
    }

    private func makeSavedPaymentMethodSelectionFixture(
        paymentMethodTypes: [String] = ["card"],
        updateStatusCode: Int32 = 200,
        didSelectPaymentOption: @escaping () -> Void
    ) async throws -> (
        checkout: CheckoutController,
        embeddedPaymentElement: EmbeddedPaymentElement,
        savedPaymentMethodRow: RowButton,
        requestRecorder: CheckoutSessionRequestRecorder
    ) {
        let requestRecorder = CheckoutSessionRequestRecorder()
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: paymentMethodTypes,
            customerSessionData: [:],
            paymentMethods: [
                STPPaymentMethod._testCard(
                    line1: "123 Main St",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94105",
                    countryCode: "US"
                ).allResponseFields,
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
            updateStatusCode: { updateRequestNumber in
                // Checkout syncs the initially selected card during setup. Only fail the re-selection.
                return updateRequestNumber == 1 ? 200 : updateStatusCode
            }
        )

        var configuration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement.rowSelectionBehavior = .immediateAction(
            didSelectPaymentOption: didSelectPaymentOption
        )

        let checkout = try await CheckoutController(configuration: configuration)
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

import OHHTTPStubs
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
import UIKit
import XCTest

/// Verifies the server setup needed for merchant-saved cards, using real test-backend responses.
@MainActor
final class CheckoutSavedMethodsGuideLiveTests: XCTestCase {
    override func setUp() {
        super.setUp()
        HTTPStubs.removeAllStubs()
        LinkAccountContext.shared.account = nil
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        LinkAccountContext.shared.account = nil
        super.tearDown()
    }

    func testGuideEmailOnlyDoesNotOfferMerchantSaving() async throws {
        let checkout = try await makeCheckout()
        XCTAssertNil(checkout.session.customerId)
        XCTAssertEqual(consentBehavior(checkout), .paymentSheetWithCheckoutSessionPaymentMethodSaveDisabled)
    }

    func testExistingCustomerWithoutSaveOptionDoesNotOfferSaving() async throws {
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(email: "saved-card-audit@example.com")
        let checkout = try await makeCheckout(customerID: customerID)
        XCTAssertEqual(checkout.session.customerId, customerID)
        XCTAssertEqual(consentBehavior(checkout), .paymentSheetWithCheckoutSessionPaymentMethodSaveDisabled)
    }

    func testExistingCustomerWithSaveOptionPersistsCardForNextSession() async throws {
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(email: "saved-card-audit@example.com")
        let checkout = try await makeCheckout(customerID: customerID, saveEnabled: true)
        XCTAssertEqual(checkout.session.customerId, customerID)
        try await saveAndCheckNextSession(checkout)
    }

    func testCustomerCreationAlwaysDoesNotOfferSavingBeforeCustomerExists() async throws {
        let checkout = try await makeCheckout(saveEnabled: true, createCustomer: true)
        XCTAssertNil(checkout.session.customerId)
        XCTAssertEqual(checkout.session.savedPaymentMethodsOfferSave?.enabled, true)
        XCTAssertEqual(consentBehavior(checkout), .paymentSheetWithCheckoutSessionPaymentMethodSaveDisabled)
    }

    private func consentBehavior(_ checkout: CheckoutController) -> PaymentSheetFormFactory.SavePaymentMethodConsentBehavior {
        PaymentSheetFormFactory.makeSavePaymentMethodConsentBehavior(
            intent: .checkout(checkout.session), elementsSession: checkout.session.elementsSession
        )
    }

    private func saveAndCheckNextSession(_ checkout: CheckoutController) async throws {
        // The initial server response must enable the actual form's save-consent behavior.
        let customerID = try XCTUnwrap(checkout.session.customerId)
        XCTAssertEqual(consentBehavior(checkout), .paymentSheetWithCheckoutSessionPaymentMethodSaveEnabled)
        XCTAssertTrue(checkout.session.customer?.paymentMethods.isEmpty ?? true)
        let element = checkout.getPaymentElement()
        let params = IntentConfirmParams(type: .stripe(.card))
        params.paymentMethodParams.card = STPPaymentMethodCardParams()
        params.paymentMethodParams.card?.number = "4242424242424242"
        params.paymentMethodParams.card?.expMonth = 12
        params.paymentMethodParams.card?.expYear = 2040
        params.paymentMethodParams.card?.cvc = "123"
        params.saveForFutureUseCheckboxState = .selected
        element.embeddedPaymentElement._test_paymentOption = .new(confirmParams: params)
        element.embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: element.embeddedPaymentElement)
        let result = await checkout.confirm(from: UIViewController())
        guard case .completed(.paid) = result else {
            return XCTFail("Expected saving payment to succeed: \(result)")
        }

        // Reusing the same Customer must expose the saved card in a fresh Checkout Session.
        let nextCheckout = try await makeCheckout(customerID: customerID)
        let cards = try XCTUnwrap(nextCheckout.session.customer?.paymentMethods)
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards.first?.card?.last4, "4242")
        XCTAssertEqual(nextCheckout.session.customerId, customerID)
        XCTAssertEqual(nextCheckout.getPaymentElement().paymentSheetFlowController.viewController.savedPaymentMethods.count, 1)
    }

    private func makeCheckout(
        customerID: String? = nil,
        saveEnabled: Bool = false,
        createCustomer: Bool = false
    ) async throws -> CheckoutController {
        var parameters: [String: Any] = [
            "ui_mode": "mobile_elements",
            "currency": "usd",
            "allowed_payment_method_types": ["card"],
            "items": [
                [
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "price_data": [
                                    "currency": "usd",
                                    "unit_amount": 1000,
                                    "product_data": ["name": "Guide save-card audit"],
                                ],
                                "quantity": 1,
                            ],
                        ],
                    ],
                ],
            ],
        ]
        if let customerID {
            parameters["customer"] = customerID
        } else {
            parameters["customer_email"] = "saved-card-audit@example.com"
        }
        if createCustomer {
            parameters["customer_creation"] = "always"
        }
        if saveEnabled {
            parameters["saved_payment_method_options"] = ["payment_method_save": "enabled"]
        }
        let response = try await STPTestingAPIClient.shared.createCheckoutSession(sessionParametersOverride: parameters)
        var configuration = CheckoutController.Configuration(
            clientSecret: response.clientSecret, returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: response.publishableKey)
        configuration.paymentElement = .init()
        let checkout = try await CheckoutController(configuration: configuration)
        XCTAssertFalse(checkout.session.livemode)
        return checkout
    }
}

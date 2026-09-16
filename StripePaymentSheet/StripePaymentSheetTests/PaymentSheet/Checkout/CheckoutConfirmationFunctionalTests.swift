//
//  CheckoutConfirmationFunctionalTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import UIKit
import XCTest

@MainActor
final class CheckoutConfirmationFunctionalTests: STPNetworkStubbingTestCase {
    func test_confirm_zero_amount_with_no_payment_method_and_checkout_session_customer_email_completes_without_intent() async throws {
        // Given a $0 Checkout Session with a server email and no selected payment method
        let checkout = try await makeCheckout(
            amount: 0,
            serverEmailSource: .checkoutSession("test@example.com"),
            localDefaultEmail: nil
        )
        XCTAssertNil(checkout.session.paymentOption)

        // When the coordinator confirms the Checkout Session
        let result = await checkout.confirm(from: UIViewController())

        // Then confirmation completes without creating an Intent
        assertCompleted(result)
        XCTAssertEqual(checkout.session.status, .complete(.noPaymentRequired))
    }

    func test_confirm_zero_amount_with_card_and_local_email_completes_with_setup_intent() async throws {
        // Given a $0 Checkout Session with a local email and a selected card
        let checkout = try await makeCheckout(
            amount: 0,
            serverEmailSource: nil,
            localDefaultEmail: "test@example.com"
        )
        selectCardWithoutBillingEmail(on: checkout)

        // When the coordinator confirms the Checkout Session
        let result = await checkout.confirm(from: UIViewController())

        // Then confirmation creates and completes a SetupIntent
        assertCompleted(result)
        XCTAssertEqual(checkout.session.status, .complete(.noPaymentRequired))
    }

    func test_confirm_with_card_and_customer_object_email_completes_with_payment_intent() async throws {
        // Given a Checkout Session with Customer.email and a selected card without a billing email
        let checkout = try await makeCheckout(
            amount: 1_000,
            serverEmailSource: .customer("test@example.com"),
            localDefaultEmail: nil
        )
        selectCardWithoutBillingEmail(on: checkout)

        // When the coordinator confirms the Checkout Session
        let result = await checkout.confirm(from: UIViewController())

        // Then confirmation creates and completes a PaymentIntent
        assertCompleted(result, paymentStatus: .paid)
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }

    private func makeCheckout(
        amount: Int,
        serverEmailSource: ServerEmailSource?,
        localDefaultEmail: String?
    ) async throws -> CheckoutController {
        var customerEmail: String?
        var customerID: String?
        switch serverEmailSource {
        case .checkoutSession(let email):
            customerEmail = email
        case .customer(let email):
            customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(
                email: email
            )
        case nil:
            break
        }
        let sessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            amount: amount,
            customerID: customerID,
            returnURL: "stripe-ios-test://checkout-return",
            customerEmail: customerEmail
        )
        var configuration = CheckoutController.Configuration(
            clientSecret: sessionResponse.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: sessionResponse.publishableKey)
        configuration.defaults.email = localDefaultEmail
        configuration.paymentElement = .init()
        return try await CheckoutController(configuration: configuration)
    }

    private func selectCardWithoutBillingEmail(on checkout: CheckoutController) {
        let paymentElement = checkout.getPaymentElement()
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = 12
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(
            for: paymentElement.embeddedPaymentElement.configuration
        )
        paymentElement.embeddedPaymentElement._test_paymentOption = .new(confirmParams: confirmParams)
        paymentElement.embeddedPaymentElementDidUpdatePaymentOption(
            embeddedPaymentElement: paymentElement.embeddedPaymentElement
        )
        XCTAssertNil(confirmParams.paymentMethodParams.billingDetails?.email)
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "card")
    }

    private func assertCompleted(
        _ result: CheckoutController.ConfirmResult,
        paymentStatus expectedPaymentStatus: CheckoutController.Session.Status.PaymentStatus = .noPaymentRequired,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .completed(let paymentStatus) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)", file: file, line: line)
        }
        XCTAssertEqual(paymentStatus, expectedPaymentStatus, file: file, line: line)
    }

    private enum ServerEmailSource {
        case checkoutSession(String)
        case customer(String)
    }
}

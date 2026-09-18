//
//  CheckoutConfirmationFunctionalTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
@testable @_spi(STP) import StripeUICore
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

    // TODO: Re-enable after https://git.corp.stripe.com/stripe-internal/mint/pull/2587796 deploys
    // customer_email with no PM billing email returns checkout_email_missing.
    /*
    func test_confirm_with_card_and_checkout_session_customer_email_completes_with_payment_intent() async throws {
        // Given a Checkout Session with customer_email and a selected card without a billing email
        let checkout = try await makeCheckout(
            amount: 1_000,
            serverEmailSource: .checkoutSession("test@example.com"),
            localDefaultEmail: nil
        )
        selectCardWithoutBillingEmail(on: checkout)

        // When the coordinator confirms the Checkout Session
        let result = await checkout.confirm(from: UIViewController())

        // Then confirmation creates and completes a PaymentIntent
        assertCompleted(result, paymentStatus: .paid)
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }
    */

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

    // TODO: Re-enable after https://git.corp.stripe.com/stripe-internal/mint/pull/2587796 deploys
    // customer_email with a different PM billing email returns customer_and_confirmation_email_mismatch.
    /*
    func test_confirm_with_sepa_debit_and_different_payment_method_email_completes_with_payment_intent() async throws {
        // Given a Checkout Session with customer_email and a SEPA Debit form requiring a different email
        var defaultBillingDetails = CheckoutController.Configuration.Defaults.BillingDetails()
        defaultBillingDetails.name = "Jenny Rosen"
        defaultBillingDetails.address = .init(
            country: "DE",
            line1: "Invalidenstraße 117",
            city: "Berlin",
            postalCode: "10115"
        )
        let checkout = try await makeCheckout(
            amount: 1_000,
            serverEmailSource: .checkoutSession("checkout@example.com"),
            localDefaultEmail: nil,
            types: ["sepa_debit"],
            currency: "eur",
            merchantCountry: "de",
            defaultBillingDetails: defaultBillingDetails
        )
        let embeddedPaymentElement = checkout.getPaymentElement().embeddedPaymentElement
        let presentingViewController = UIViewController()
        embeddedPaymentElement.presentingViewController = presentingViewController
        let sepaDebitRow = try XCTUnwrap(
            embeddedPaymentElement.embeddedPaymentMethodsView.rowButtons.first {
                $0.type == .new(paymentMethodType: .stripe(.SEPADebit))
            }
        )
        embeddedPaymentElement.embeddedPaymentMethodsView.didTap(rowButton: sepaDebitRow)
        let form = try XCTUnwrap(embeddedPaymentElement.formCache[.stripe(.SEPADebit)])
        form.getTextFieldElement("Full name").setText("Jenny Rosen")
        form.getTextFieldElement("Email").setText("payment-method@example.com")
        form.getTextFieldElement("IBAN").setText("DE89370400440532013000")
        sendEventToSubviews(.viewDidAppear, from: form.view)
        guard form.validationState.isValid else {
            return XCTFail("Expected the completed SEPA Debit form to be valid")
        }
        try XCTUnwrap(embeddedPaymentElement.selectedFormViewController).didTapPrimaryButton()
        try await waitUntil {
            checkout.session.paymentOption != nil
        }
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "sepa_debit")
        XCTAssertEqual(
            checkout.session.paymentOption?.billingDetails?.email,
            "payment-method@example.com"
        )

        // When the coordinator confirms the Checkout Session
        let result = await checkout.confirm(from: UIViewController())

        // Then confirmation creates and completes a PaymentIntent
        assertCompleted(result, paymentStatus: .unpaid)
        XCTAssertEqual(checkout.session.status, .complete(.unpaid))
    }
    */

    private func makeCheckout(
        amount: Int,
        serverEmailSource: ServerEmailSource?,
        localDefaultEmail: String?,
        types: [String] = ["card"],
        currency: String = "usd",
        merchantCountry: String = "us",
        defaultBillingDetails: CheckoutController.Configuration.Defaults.BillingDetails? = nil
    ) async throws -> CheckoutController {
        var customerEmail: String?
        var customerID: String?
        switch serverEmailSource {
        case .checkoutSession(let email):
            customerEmail = email
        case .customer(let email):
            customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(
                email: email,
                merchantCountry: merchantCountry
            )
        case nil:
            break
        }
        let sessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: types,
            currency: currency,
            amount: amount,
            merchantCountry: merchantCountry,
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
        configuration.defaults.billingDetails = defaultBillingDetails
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

    // TODO: Re-enable after https://git.corp.stripe.com/stripe-internal/mint/pull/2587796 deploys
    // Helper for the disabled SEPA Debit test.
    /*
    private func waitUntil(
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline {
                XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
                throw CheckoutConfirmationFunctionalTestTimeoutError()
            }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }
    */

    private enum ServerEmailSource {
        case checkoutSession(String)
        case customer(String)
    }
}

// Used by the disabled SEPA Debit test's waitUntil helper.
// private struct CheckoutConfirmationFunctionalTestTimeoutError: Error {}

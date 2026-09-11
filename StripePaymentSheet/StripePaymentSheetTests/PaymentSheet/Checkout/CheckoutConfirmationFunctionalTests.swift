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
    func testConfirmZeroAmountWithoutPaymentMethodCompletesWithoutIntent() async throws {
        // Given a $0 Checkout Session with no selected payment method
        let checkout = try await makeZeroAmountCheckout()
        XCTAssertNil(checkout.session.paymentOption)

        // When the coordinator confirms the Checkout Session
        let result = await checkout.confirm(from: UIViewController())

        // Then confirmation completes without creating an Intent
        assertCompleted(result)
        XCTAssertEqual(checkout.session.status, .complete(.noPaymentRequired))
    }

    func testConfirmZeroAmountWithCardCompletesWithSetupIntent() async throws {
        // Given a $0 Checkout Session with a selected card
        let checkout = try await makeZeroAmountCheckout()
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
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "card")

        // When the coordinator confirms the Checkout Session
        let result = await checkout.confirm(from: UIViewController())

        // Then confirmation creates and completes a SetupIntent
        assertCompleted(result)
        XCTAssertEqual(checkout.session.status, .complete(.noPaymentRequired))
    }

    private func makeZeroAmountCheckout() async throws -> CheckoutController {
        let sessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            amount: 0,
            returnURL: "stripe-ios-test://checkout-return",
            customerEmail: "test@example.com"
        )
        var configuration = CheckoutController.Configuration(
            clientSecret: sessionResponse.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: sessionResponse.publishableKey)
        configuration.defaults.email = "test@example.com"
        configuration.paymentElement = .init()
        return try await CheckoutController(configuration: configuration)
    }

    private func assertCompleted(
        _ result: CheckoutController.ConfirmResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .completed(let paymentStatus) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)", file: file, line: line)
        }
        XCTAssertEqual(paymentStatus, .noPaymentRequired, file: file, line: line)
    }
}

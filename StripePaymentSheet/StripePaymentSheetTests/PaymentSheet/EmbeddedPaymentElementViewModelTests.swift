//
//  EmbeddedPaymentElementViewModelTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/29/25.
//

@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
import XCTest

@MainActor
class EmbeddedPaymentElementViewModelTests: XCTestCase {
    // MARK: - Test Configurations

    lazy var configuration: EmbeddedPaymentElement.Configuration = {
        var config = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }()

    let paymentIntentConfig = EmbeddedPaymentElement.IntentConfiguration(
        mode: .payment(amount: 1000, currency: "USD"),
        paymentMethodTypes: ["card", "cashapp"]
    ) { paymentMethod, _ in
        try await withCheckedThrowingContinuation { continuation in
            STPTestingAPIClient.shared.fetchPaymentIntent(
                types: ["card"],
                currency: "USD",
                paymentMethodID: paymentMethod.stripeId,
                confirm: true
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    let paymentIntentConfigUpdated = EmbeddedPaymentElement.IntentConfiguration(
        mode: .payment(amount: 1001, currency: "USD"),
        paymentMethodTypes: ["card", "cashapp"]
    ) { _, _ in
        // no-op
        return ""
    }

    let brokenPaymentIntentConfig = EmbeddedPaymentElement.IntentConfiguration(
        mode: .payment(amount: -1000, currency: "bad currency"),
        paymentMethodTypes: ["card", "cashapp"]
    ) { _, _ in
        // no-op, this should fail due to invalid amounts/currency
        return ""
    }

    // MARK: - Tests

    func testLoadSuccess() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        XCTAssertFalse(viewModel.isLoaded, "viewModel should not be loaded initially.")

        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )
        XCTAssertTrue(viewModel.isLoaded, "viewModel should be loaded after calling load().")
    }

    func testLoadThrowsOnMultipleCalls() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )

        // Trying to load again should throw
        await XCTAssertThrowsErrorAsync( try await {
            try await viewModel.load(
                intentConfiguration: self.paymentIntentConfig,
                configuration: self.configuration
            )
        }())
    }

    func testUpdateFailsIfNotLoaded() async {
        let viewModel = EmbeddedPaymentElementViewModel()
        // Attempt to update before loading
        let result = await viewModel.update(intentConfiguration: paymentIntentConfigUpdated)
        guard case let .failed(error) = result else {
            return XCTFail("Expected an update to fail if not loaded.")
        }

        XCTAssertEqual(error as? EmbeddedPaymentElementViewModel.ViewModelError, .notLoaded)
    }

    func testConfirmFailsIfNotLoaded() async {
        let viewModel = EmbeddedPaymentElementViewModel()
        // Attempt to confirm before loading
        let result = await viewModel.confirm()
        guard case let .failed(error) = result else {
            return XCTFail("Expected confirm to fail if not loaded.")
        }

        XCTAssertEqual(error as? EmbeddedPaymentElementViewModel.ViewModelError, .notLoaded)
    }

    func testLoadThenUpdate() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )

        // The update should succeed
        let result = await viewModel.update(intentConfiguration: paymentIntentConfigUpdated)
        XCTAssertEqual(result, .succeeded, "Expected .succeeded after updating with a valid config.")
        XCTAssertTrue(viewModel.isLoaded)
    }

    func testLoadThenUpdateWithBrokenConfig() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )
        XCTAssertTrue(viewModel.isLoaded)

        // The update should fail due to invalid config
        let result = await viewModel.update(intentConfiguration: brokenPaymentIntentConfig)
        guard case .failed = result else {
            return XCTFail("Expected .failed with broken config.")
        }
    }

    func testConfirmSucceedsWithValidCard() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )
        viewModel.embeddedPaymentElement?.presentingViewController = UIViewController() // typically set by the UIViewRepresentable
        XCTAssertTrue(viewModel.isLoaded)

        // Provide a valid card
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: configuration)

        viewModel.embeddedPaymentElement?._test_paymentOption = .new(confirmParams: confirmParams)

        let result = await viewModel.confirm()
        switch result {
        case .completed:
            // Success
            break
        case .failed(let error):
            XCTFail("Expected confirm to succeed, but failed with error: \(error)")
        case .canceled:
            XCTFail("Expected confirm to succeed, but it was canceled")
        }
    }

    func testConfirmFailsWithInvalidCard() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )
        viewModel.embeddedPaymentElement?.presentingViewController = UIViewController() // typically set by the UIViewRepresentable
        XCTAssertTrue(viewModel.isLoaded)

        // Provide an invalid card
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "1234567890123456" // Invalid card number
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: configuration)

        viewModel.embeddedPaymentElement?._test_paymentOption = .new(confirmParams: confirmParams)

        let result = await viewModel.confirm()
        switch result {
        case .failed(let error):
            XCTAssertTrue(error.nonGenericDescription.contains("Your card number is incorrect."),
                          "Expected card number incorrect error.")
        default:
            XCTFail("Expected confirm to fail with invalid card.")
        }
    }

    func testClearPaymentOption() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )
        XCTAssertTrue(viewModel.isLoaded)

        // Simulate user selecting a payment method
        let embeddedView = viewModel.embeddedPaymentElement!.embeddedPaymentMethodsView
        embeddedView.didTap(rowButton: embeddedView.getRowButton(accessibilityIdentifier: "Cash App Pay"))
        XCTAssertNotNil(viewModel.paymentOption, "Expected a payment option after user selection.")

        // Clear
        viewModel.clearPaymentOption()
        XCTAssertNil(viewModel.paymentOption, "Expected payment option to be nil after clear.")
    }

    func testClearPaymentOptionWhenNoneSelectedDoesNothing() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )
        XCTAssertTrue(viewModel.isLoaded)
        XCTAssertNil(viewModel.paymentOption, "No option should be selected initially.")

        // Clearing when none is selected should be safe/no-op
        viewModel.clearPaymentOption()
        XCTAssertNil(viewModel.paymentOption)
    }

    func testConfirmThenUpdateFails() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )
        viewModel.embeddedPaymentElement?.presentingViewController = UIViewController() // typically set by the UIViewRepresentable
        XCTAssertTrue(viewModel.isLoaded)

        // Confirm a payment
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: configuration)

        viewModel.embeddedPaymentElement?._test_paymentOption = .new(confirmParams: confirmParams)
        let confirmResult = await viewModel.confirm()
        XCTAssertEqual(confirmResult, .completed)

        // After confirming, an update should fail
        let updateResult = await viewModel.update(intentConfiguration: paymentIntentConfigUpdated)
        guard case let .failed(error) = updateResult else {
            return XCTFail("Expected update to fail after a successful confirmation.")
        }
        XCTAssertEqual(
            (error as! PaymentSheetError).debugDescription,
            PaymentSheetError.embeddedPaymentElementAlreadyConfirmedIntent.debugDescription
        )
    }

    func testConfirmTwiceFails() async throws {
        let viewModel = EmbeddedPaymentElementViewModel()
        try await viewModel.load(
            intentConfiguration: paymentIntentConfig,
            configuration: configuration
        )
        viewModel.embeddedPaymentElement?.presentingViewController = UIViewController() // typically set by the UIViewRepresentable
        XCTAssertTrue(viewModel.isLoaded)

        // Confirm a payment
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: configuration)

        viewModel.embeddedPaymentElement?._test_paymentOption = .new(confirmParams: confirmParams)
        let firstConfirm = await viewModel.confirm()
        XCTAssertEqual(firstConfirm, .completed)

        // Confirm again should fail
        let secondConfirm = await viewModel.confirm()
        guard case let .failed(error) = secondConfirm else {
            return XCTFail("Expected second confirm to fail after the intent is already confirmed.")
        }
        XCTAssertEqual(
            (error as! PaymentSheetError).debugDescription,
            PaymentSheetError.embeddedPaymentElementAlreadyConfirmedIntent.debugDescription
        )
    }
}

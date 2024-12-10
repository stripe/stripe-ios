//
//  EmbeddedPaymentElementTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 10/14/24.
//

@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePaymentsTestUtils
import XCTest

@_spi(EmbeddedPaymentElementPrivateBeta) @_spi(STP) @testable import StripePaymentSheet

@MainActor
// https://jira.corp.stripe.com/browse/MOBILESDK-2607 Make these STPNetworkStubbingTestCase; blocked on getting them to record image requests
class EmbeddedPaymentElementTest: XCTestCase {
    lazy var configuration: EmbeddedPaymentElement.Configuration = {
        var config = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }()
    let paymentIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card", "cashapp"]) { _, _, _ in
        // These tests don't confirm, so this is unused
    }
    let paymentIntentConfigWithConfirmHandler = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card", "cashapp"]) {paymentMethod, _, intentCreationCallback in
        STPTestingAPIClient.shared.fetchPaymentIntent(types: ["card"],
                                currency: "USD",
                                paymentMethodID: paymentMethod.stripeId,
                                confirm: true) { result in
            switch result {
            case .success(let clientSecret):
                intentCreationCallback(.success(clientSecret))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
    let paymentIntentConfig2 = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 999, currency: "USD"), paymentMethodTypes: ["card", "cashapp"]) { _, _, _ in
        // These tests don't confirm, so this is unused
    }
    let setupIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: ["card", "cashapp"]) { _, _, _ in
        // These tests don't confirm, so this is unused
    }
    var delegateDidUpdatePaymentOptionCalled = false
    var delegateDidUpdateHeightCalled = false

    // MARK: - `update` tests

    func testUpdate() async throws {
        STPAnalyticsClient.sharedClient._testLogHistory = []
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)

        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        // ...with cash app selected...
        let cashAppPayRowButton = sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Cash App Pay")
        sut.embeddedPaymentMethodsView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))
        delegateDidUpdatePaymentOptionCalled = false // This gets set to true when we select cash app ^
        XCTAssertNil(sut.paymentOption?.mandateText)
        // ...its intent should match the initial intent config...
        XCTAssertEqual(sut.intent.amount, 1000)
        // ...and updating the amount should succeed...
        let update1Result = await sut.update(intentConfiguration: paymentIntentConfig2
        )
        XCTAssertEqual(update1Result, .succeeded)
        XCTAssertEqual(sut.intent.amount, 999)
        // ...without invoking the delegate (since neither height nor payment option updated)
        XCTAssertFalse(delegateDidUpdateHeightCalled)
        XCTAssertFalse(delegateDidUpdatePaymentOptionCalled)
        // ...and preserve the cash app pay selection
        XCTAssertEqual(sut.paymentOption?.label, "Cash App Pay")

        // Updating the intent config from payment to setup...
        // ...(using the completion block based API this time)...
        let secondUpdateExpectation = expectation(description: "Second update completes")
        // ...(and resetting the delegate trackers)...
        delegateDidUpdatePaymentOptionCalled = false
        delegateDidUpdatePaymentOptionCalled = false
        sut.update(intentConfiguration: setupIntentConfig) { update2Result in
            // ...should succeed.
            XCTAssertEqual(update2Result, .succeeded)
            XCTAssertFalse(sut.intent.isPaymentIntent)
            // ...and preserve the cash app pay selection
            XCTAssertEqual(sut.paymentOption?.label, "Cash App Pay")
            // ...and invoke both delegate methods since cash app now has a mandate
            XCTAssertNotNil(sut.paymentOption?.mandateText)
            XCTAssertTrue(self.delegateDidUpdateHeightCalled)
            XCTAssertTrue(self.delegateDidUpdatePaymentOptionCalled)

            // Sanity check that the analytics...
            let analytics = STPAnalyticsClient.sharedClient._testLogHistory
            let loadStartedEvents = analytics.filter { $0["event"] as? String == "mc_load_started" }
            let loadSucceededEvents = analytics.filter { $0["event"] as? String == "mc_load_succeeded" }
            // ...have the expected # of start and succeeded events...
            XCTAssertEqual(loadStartedEvents.count, 3)
            XCTAssertEqual(loadSucceededEvents.count, 3)
            // ..and all have the same session id...
            let sessionID = analytics.first?["session_id"] as? String
            (loadStartedEvents + loadSucceededEvents).map { $0["session_id"] as? String }.forEach {
                XCTAssertEqual($0, sessionID)
            }

            secondUpdateExpectation.fulfill()
        }
        await fulfillment(of: [secondUpdateExpectation])
    }

    func testUpdateFails() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        // ...updating w/ an invalid intent config should fail...
        var intentConfig = paymentIntentConfig
        intentConfig.mode = .setup(currency: "Invalid currency", setupFutureUsage: .offSession)
        let updateResult = await sut.update(intentConfiguration: intentConfig)
        switch updateResult {
        case .failed:
            break
        default:
            XCTFail()
        }

        // Updating should succeed after failing to update...
        let secondUpdateExpectation = expectation(description: "Second update succeeds")
        intentConfig.mode = .setup(currency: "USD", setupFutureUsage: .offSession)
        // ...(using the completion block based API this time)...
        sut.update(intentConfiguration: intentConfig) { update2Result in
            XCTAssertEqual(update2Result, .succeeded)
            secondUpdateExpectation.fulfill()
        }
        await fulfillment(of: [secondUpdateExpectation])
    }

    func testUpdateCancelsInFlightUpdate() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        // ...updating...
        async let _updateResult = sut.update(intentConfiguration: paymentIntentConfig)
        // ...and immediately updating again, before the 1st update finishes...
        async let _updateResult2 = sut.update(intentConfiguration: setupIntentConfig)
        let updateResult = await _updateResult // Unfortunate workaround b/c XCTAssertEqual doesn't support concurrency
        let updateResult2 = await _updateResult2
        // ...should cancel the 1st update
        XCTAssertEqual(updateResult, .canceled)
        XCTAssertEqual(updateResult2, .succeeded)
        XCTAssertTrue(sut.intent.isSettingUp)
    }

    func testConfirmHandlesInflightUpdateThatSucceeds() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfigWithConfirmHandler, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        
        // Create test confirmParams with valid card details
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: sut.configuration)
        
        // ...updating...
        async let _updateResult = sut.update(intentConfiguration: paymentIntentConfig)
        // ...and immediately calling confirm, before the 1st update finishes...
        // Inject the test payment option
        sut._test_paymentOption = .new(confirmParams: confirmParams)
        let confirmResult = await sut.confirm()
        // ...should make the confirm call wait for the update and then
        switch confirmResult {
        case .completed:
            break
        default:
            XCTFail("Expected confirm to succeed")
        }
    }

    func testConfirmHandlesInflightUpdateThatFails() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        // ...updating w/ a broken config...
        let brokenConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: -1000, currency: "bad currency"), confirmHandler: { _, _, _ in })
        async let _ = sut.update(intentConfiguration: brokenConfig)
        // ...and immediately calling confirm, before the 1st update finishes...
        async let confirmResult = sut.confirm() // Note: If this is `await`, it runs *before* the `update` call above is run.
        // ...should make the confirm call wait for the update and then fail b/c the update failed
        switch await confirmResult {
        case let .failed(error: error):
            XCTAssertEqual(error.nonGenericDescription.prefix(101), "An error occurred in PaymentSheet. The amount in `PaymentSheet.IntentConfiguration` must be non-zero!")
        default:
            XCTFail("Expected confirm to fail")
        }
    }

    func testConfirmHandlesCompletedUpdateThatFailed() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        // ...updating w/ a broken config...
        let brokenConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: -1000, currency: "bad currency"), confirmHandler: { _, _, _ in })
        _ = await sut.update(intentConfiguration: brokenConfig)
        // ...and calling confirm, after the update finishes...
        async let confirmResult = sut.confirm()
        switch await confirmResult {
        case let .failed(error: error):
            // ...should make the confirm call fail b/c the update failed
            XCTAssertEqual(error.nonGenericDescription.prefix(101), "An error occurred in PaymentSheet. The amount in `PaymentSheet.IntentConfiguration` must be non-zero!")
        default:
            XCTFail("Expected confirm to fail")
        }
    }
    
    func testConfirmCard() async throws {
        // Given an EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfigWithConfirmHandler, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        
        // Create test confirmParams with valid card details
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: sut.configuration)
        
        // Inject the test payment option
        sut._test_paymentOption = .new(confirmParams: confirmParams)
        
        // Call confirm() and verify the result
        let result = await sut.confirm()
        switch result {
        case .completed:
            break // Success
        case .failed(let error):
            XCTFail("Expected confirm to succeed, but failed with error: \(error)")
        case .canceled:
            XCTFail("Expected confirm to succeed, but it was canceled")
        }
    }

    func testConfirmWithInvalidCard() async throws {
        // Given an EmbeddedPaymentElement instance
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfigWithConfirmHandler, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        
        // Create test confirmParams with invalid card details
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "1234567890123456" // Invalid card number
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: sut.configuration)
        
        // Inject the test payment option
        sut._test_paymentOption = .new(confirmParams: confirmParams)
        
        // Call confirm() and verify that it fails
        let result = await sut.confirm()
        switch result {
        case .completed:
            XCTFail("Expected confirm to fail, but it succeeded")
        case .failed(let error):
            XCTAssertTrue(error.nonGenericDescription.contains("Your card number is incorrect."))
        case .canceled:
            XCTFail("Expected confirm to fail, but it was canceled")
        }
    }
    
    func testClearPaymentOptionAfterSelection() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)

        // Initially, no paymentOption should be selected
        XCTAssertNil(sut.paymentOption)

        // Select the "Card" payment method
        sut.embeddedPaymentMethodsView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))
        // The delegate should have been notified
        XCTAssertTrue(delegateDidUpdatePaymentOptionCalled)
        XCTAssertNotNil(sut.paymentOption)

        // Reset flags
        delegateDidUpdatePaymentOptionCalled = false
        delegateDidUpdateHeightCalled = false

        // Reset the selection
        sut.clearPaymentOption()

        // The paymentOption should now be nil after reset
        XCTAssertNil(sut.paymentOption)

        // The delegate should have been notified again after reset
        XCTAssertTrue(delegateDidUpdatePaymentOptionCalled)
    }

    func testClearPaymentOptionWhenNoSelection() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)

        // Initially, no paymentOption should be selected
        XCTAssertNil(sut.paymentOption)

        // Reset flags
        delegateDidUpdatePaymentOptionCalled = false
        delegateDidUpdateHeightCalled = false

        // Call reset when no selection is made
        sut.clearPaymentOption()

        // Confirm that paymentOption is still nil and no delegate calls were made
        XCTAssertNil(sut.paymentOption)
        XCTAssertFalse(delegateDidUpdatePaymentOptionCalled)
        XCTAssertFalse(delegateDidUpdateHeightCalled)
    }
    
    func testConfirmThenUpdateFails() async throws {
        // Given an EmbeddedPaymentElement that can confirm
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfigWithConfirmHandler, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)

        // Create test confirmParams with valid card details
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: sut.configuration)
        
        // Inject the test payment option and confirm the payment successfully
        sut._test_paymentOption = .new(confirmParams: confirmParams)
        let confirmResult = await sut.confirm()
        XCTAssertEqual(confirmResult, .completed)

        // Now that the payment is confirmed, attempting to update should fail
        let updateResult = await sut.update(intentConfiguration: paymentIntentConfig2)
        guard case let .failed(error) = updateResult else {
            XCTFail("Expected the update to fail after confirming the intent.")
            return
        }
        
        XCTAssertEqual((error as! PaymentSheetError).debugDescription, PaymentSheetError.embeddedPaymentElementAlreadyConfirmedIntent.debugDescription)
    }

    func testConfirmThenClearPaymentOptionDoesNothing() async throws {
        // Given an EmbeddedPaymentElement that can confirm
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfigWithConfirmHandler, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)

        // Create test confirmParams with valid card details
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: sut.configuration)
        
        // Inject the test payment option and confirm the payment successfully
        sut._test_paymentOption = .new(confirmParams: confirmParams)
        let confirmResult = await sut.confirm()
        XCTAssertEqual(confirmResult, .completed)

        // Once confirmed, attempting to clear the payment option should do nothing
        let previousPaymentOption = sut.paymentOption
        sut.clearPaymentOption()
        XCTAssertEqual(sut.paymentOption, previousPaymentOption, "Clearing payment option after confirmation should have no effect.")
    }

    func testConfirmTwiceFails() async throws {
        // Given an EmbeddedPaymentElement that can confirm
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfigWithConfirmHandler, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)

        // Create test confirmParams with valid card details
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: sut.configuration)
        
        // Inject the test payment option and confirm the payment successfully once
        sut._test_paymentOption = .new(confirmParams: confirmParams)
        let firstConfirmResult = await sut.confirm()
        XCTAssertEqual(firstConfirmResult, .completed)
        
        // Attempting to confirm again should fail
        let secondConfirmResult = await sut.confirm()
        guard case let .failed(error) = secondConfirmResult else {
            XCTFail("Expected second confirm to fail after the intent has already been confirmed.")
            return
        }
        XCTAssertEqual((error as! PaymentSheetError).debugDescription, PaymentSheetError.embeddedPaymentElementAlreadyConfirmedIntent.debugDescription)
    }

}

extension EmbeddedPaymentElementTest: EmbeddedPaymentElementDelegate {
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        delegateDidUpdateHeightCalled = true
    }

    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        delegateDidUpdatePaymentOptionCalled = true
    }
}

extension EmbeddedPaymentElement.UpdateResult: Equatable {
    public static func == (lhs: StripePaymentSheet.EmbeddedPaymentElement.UpdateResult, rhs: StripePaymentSheet.EmbeddedPaymentElement.UpdateResult) -> Bool {
        switch (lhs, rhs) {
        case (.succeeded, .succeeded): return true
        case let (.failed(lhsError), .failed(rhsError)): return lhsError.nonGenericDescription == rhsError.nonGenericDescription
        case (.canceled, .canceled): return true
        default: return false
        }
    }
}

extension EmbeddedPaymentMethodsView {
    var rowButtons: [RowButton] {
        return stackView.arrangedSubviews.compactMap { $0 as? RowButton }
    }

    func getRowButton(accessibilityIdentifier: String) -> RowButton {
        return rowButtons.first { $0.accessibilityIdentifier == accessibilityIdentifier }!
    }
}

extension PaymentSheetResult: Equatable {
    public static func == (lhs: StripePaymentSheet.PaymentSheetResult, rhs: StripePaymentSheet.PaymentSheetResult) -> Bool {
        switch (lhs, rhs) {
        case (.completed, .completed): return true
        case let (.failed(lhsError), .failed(rhsError)): return lhsError.nonGenericDescription == rhsError.nonGenericDescription
        case (.canceled, .canceled): return true
        default: return false
        }
    }
}

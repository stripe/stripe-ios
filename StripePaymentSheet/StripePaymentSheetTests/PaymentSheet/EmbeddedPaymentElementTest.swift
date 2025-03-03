//
//  EmbeddedPaymentElementTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 10/14/24.
//

@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

@_spi(EmbeddedPaymentElementPrivateBeta) @_spi(STP) @testable import StripePaymentSheet

@MainActor
// https://jira.corp.stripe.com/browse/MOBILESDK-2607 Make these STPNetworkStubbingTestCase; blocked on getting them to record image requests
class EmbeddedPaymentElementTest: XCTestCase {
    var delegatePaymentOption: EmbeddedPaymentElement.PaymentOptionDisplayData?

    lazy var configuration: EmbeddedPaymentElement.Configuration = {
        var config = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }()
    let paymentIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card", "cashapp"]) { _, _, _ in
        // These tests don't confirm, so this is unused
        XCTFail("paymentIntentConfig confirm handler should not be called.")
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
        XCTFail("paymentIntentConfig2 confirm handler should not be called.")
    }
    let setupIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: ["card", "cashapp", "amazon_pay"]) { _, _, _ in
        // These tests don't confirm, so this is unused
        XCTFail("setupIntentConfig confirm handler should not be called.")
    }
    var delegateDidUpdatePaymentOptionCalled = false
    var delegateDidUpdateHeightCalled = false
    var delegateWillPresentCalled = false

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
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Cash App Pay"))
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
            let loadStartedEvents = analytics.filter { $0["event"] as? String == "mc_load_started" && $0["integration_shape"] as? String == "embedded" }
            let loadSucceededEvents = analytics.filter { $0["event"] as? String == "mc_load_succeeded" && $0["integration_shape"] as? String == "embedded" }
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

    func testUpdateFailsWhenFormPresented() async throws {
        // Set up a test window so the view controllers "present"
        let testWindow = UIWindow(frame: .zero)
        testWindow.isHidden = false
        testWindow.rootViewController = UIViewController()

        STPAnalyticsClient.sharedClient._testLogHistory = []
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)

        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = testWindow.rootViewController
        sut.view.autosizeHeight(width: 320)

        // Tap card to present the form
        let cardRowButton = sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card")
        sut.embeddedPaymentMethodsView.didTap(rowButton: cardRowButton)

        // Assert the form is shown
        XCTAssertTrue(delegateWillPresentCalled)

        // Updates should fail while the form is presented
        async let _updateResult = sut.update(intentConfiguration: setupIntentConfig)
        let updateResult = await _updateResult // Unfortunate workaround b/c XCTAssertEqual doesn't support concurrency
        XCTAssertEqual(updateResult, .failed(error: PaymentSheetError.embeddedPaymentElementUpdateWithFormPresented))
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
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: sut.configuration)

        // ...updating...
        async let _firstUpdateResult = sut.update(intentConfiguration: paymentIntentConfig)
        // ...and immediately calling confirm, before the 1st update finishes...
        // Inject the test payment option
        sut._test_paymentOption = .new(confirmParams: confirmParams)
        let confirmResult = await sut.confirm()
        // ...should make the confirm call wait for the update before completing
        switch confirmResult {
        case .completed:
            break
        default:
            XCTFail("Expected confirm to succeed")
        }
        let firstUpdateResult = await _firstUpdateResult
        XCTAssertEqual(firstUpdateResult, .succeeded)
    }

    func testConfirmHandlesInflightUpdateThatFails() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Cash App Pay"))
        // ...updating w/ a broken config...
        let brokenConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: -1000, currency: "bad currency"), confirmHandler: { _, _, _ in })
        async let _ = sut.update(intentConfiguration: brokenConfig)
        // ...and immediately calling confirm, before the 1st update finishes...
        async let confirmResult = sut.confirm() // Note: If this is `await`, it runs *before* the `update` call above is run.
        // ...should make the confirm call fail b/c the update is in progress
        switch await confirmResult {
        case let .failed(error: error):
            XCTAssertEqual(error.nonGenericDescription, "An error occurred in PaymentSheet. There's a problem with your integration. confirm was called when an update task is in progress. This is not allowed, wait for updates to complete before calling confirm.")
        default:
            XCTFail("Expected confirm to fail")
        }
    }

    func testConfirmHandlesCompletedUpdateThatFailed() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Cash App Pay"))
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
        confirmParams.paymentMethodParams.card?.expYear = 2040
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

        // Check our confirm analytics
        let analytics = STPAnalyticsClient.sharedClient._testLogHistory
        let confirmEvents = analytics.filter { $0["event"] as? String == "mc_embedded_confirm" }
        // ...have the expected # of confirm events...
        XCTAssertEqual(confirmEvents.count, 1)
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
        confirmParams.paymentMethodParams.card?.expYear = 2040
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

    func testPaymentOptionDisplayData() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: setupIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)

        // Initially, no paymentOption should be selected
        XCTAssertNil(sut.paymentOption)

        // Select the "Cash App Pay" payment method
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Cash App Pay"))
        // The delegate should have been notified with proper data
        XCTAssertEqual(delegatePaymentOption?.label, "Cash App Pay")
        XCTAssertEqual(delegatePaymentOption?.paymentMethodType, "cashapp")
        XCTAssertTrue(delegatePaymentOption?.mandateText?.string.contains("Cash App") ?? false)

        // Tap another row, payment option data should be updated
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Amazon Pay"))
        // The delegate should have been notified with proper data
        XCTAssertEqual(delegatePaymentOption?.label, "Amazon Pay")
        XCTAssertEqual(delegatePaymentOption?.paymentMethodType, "amazon_pay")
        XCTAssertTrue(delegatePaymentOption?.mandateText?.string.contains("Amazon Pay") ?? false)
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
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Cash App Pay"))
        // The delegate should have been notified
        XCTAssertTrue(delegateDidUpdatePaymentOptionCalled)
        XCTAssertEqual(sut.paymentOption?.label, "Cash App Pay")

        // Reset flags
        delegateDidUpdatePaymentOptionCalled = false
        delegateDidUpdateHeightCalled = false

        // Reset the selection
        sut.clearPaymentOption()

        // The paymentOption should now be nil after reset
        XCTAssertNil(sut.paymentOption)
        XCTAssertNil(sut.selectedFormViewController)

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
        confirmParams.paymentMethodParams.card?.expYear = 2040
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
        confirmParams.paymentMethodParams.card?.expYear = 2040
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
        confirmParams.paymentMethodParams.card?.expYear = 2040
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

    func testCorrectLast4ForInstantBankPaymentsInPassthroughMode() async throws {
        // Given an EmbeddedPaymentElement that can confirm
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfigWithConfirmHandler, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)

        // Create test confirmParams with valid Link card brand details
        let confirmParams = IntentConfirmParams(type: .linkCardBrand)
        confirmParams.instantDebitsLinkedBank = InstantDebitsLinkedBank(
            paymentMethod: .init(id: "pm_1234"),
            bankName: "Stripe Bank",
            last4: "6789",
            linkMode: nil,
            incentiveEligible: false,
            linkAccountSessionId: "fcsess_"
        )

        // Inject the test payment option and assert the label
        sut._test_paymentOption = .saved(paymentMethod: ._testCard(), confirmParams: confirmParams)
        XCTAssertEqual(sut.paymentOption?.label, "••••6789")
    }

    func testChangeButtonStateRespectsCardBrandChoice() async throws {
        // Given an EmbeddedPaymentElement w/ CBC enabled...
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _, _ in }
        let elementsSession = STPElementsSession._testValue(cardBrandChoice: ._testValue())
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)]
        )
        let sut = EmbeddedPaymentElement(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        await AddressSpecProvider.shared.loadAddressSpecs()
        await FormSpecProvider.shared.load()
        // ...with card selected...
        let cardRowButton = sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card")
        sut.embeddedPaymentMethodsView.didTap(rowButton: cardRowButton)
        // ...and filling out the form using a CBC-enabled card...
        let cardForm = sut.formCache[.stripe(.card)]!
        cardForm.getTextFieldElement("Card number").setText("4000002500001001")
        cardForm.getTextFieldElement("MM / YY").setText("1232")
        cardForm.getTextFieldElement("CVC").setText("123")
        cardForm.getTextFieldElement("ZIP").setText("65432")
        sut.selectedFormViewController?.didTapPrimaryButton()
        // ...the change button state label (the label that appears on the selected row) should read ****1001 w/o a network (b/c no network was selected)...
        var changeButtonState = sut.getChangeButtonState(for: .new(paymentMethodType: .stripe(.card)))
        XCTAssertEqual(changeButtonState.sublabel, "•••• 1001")
        // ...and setting a preferred network (ie what happens if you select a brand from the dropdown)...
        // Hack: Since the dropdown field isn't properly hooked up to the Element hierarchy, we can't access it via `cardForm.getDropdownFieldElement`
        // TODO(https://jira.corp.stripe.com/browse/MOBILESDK-3088): Make the CBC dropdown field participate in the Element hierarchy correctly!
        let cbcDropdown = (cardForm.getTextFieldElement("Card number").configuration as! TextFieldElement.PANConfiguration).cardBrandDropDown
        cbcDropdown?.selectedIndex = 1
        // ...the label should read "Cartes Bancaire ****1001"
        changeButtonState = sut.getChangeButtonState(for: .new(paymentMethodType: .stripe(.card)))
        XCTAssertEqual(changeButtonState.sublabel, "Cartes Bancaires •••• 1001")
    }
}

extension EmbeddedPaymentElementTest: EmbeddedPaymentElementDelegate {
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        delegateDidUpdateHeightCalled = true
    }

    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        delegatePaymentOption = embeddedPaymentElement.paymentOption
        delegateDidUpdatePaymentOptionCalled = true
    }

    func embeddedPaymentElementWillPresent(embeddedPaymentElement: EmbeddedPaymentElement) {
        delegateWillPresentCalled = true
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

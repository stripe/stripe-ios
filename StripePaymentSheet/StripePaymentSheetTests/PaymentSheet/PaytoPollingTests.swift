// Copyright © 2026 Stripe, Inc. All rights reserved.

import SafariServices
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable @_spi(InternalOnlyAPI) import StripeUICore
import XCTest

@MainActor
class PaytoPollingTests: XCTestCase, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController { UIViewController() }

    func testTransientRetrievalErrorsRemainRetryableForPaymentAndSetup() {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        let actions = makeProcessingActions(client: client)
        let errors = [
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut),
            NSError(domain: STPError.stripeDomain, code: STPErrorCode.connectionError.rawValue),
            NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue, userInfo: [STPError.stripeErrorCodeKey: "lock_timeout"]),
            NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue, userInfo: [STPError.stripeErrorCodeKey: "rate_limit"]),
            NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue, userInfo: [STPError.stripeErrorTypeKey: "rate_limit_error"]),
            NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue, userInfo: [STPError.httpStatusCodeKey: 429]),
        ]
        for action in actions {
            for error in errors {
                client.error = error
                var didComplete = false
                action.retrievePollingResult {
                    didComplete = true
                    XCTAssertNil($0, "Expected a retry for \(error)")
                }
                XCTAssertTrue(didComplete)
            }
        }
    }

    func testPermanentRetrievalErrorsFailPaymentAndSetupWhileProcessing() throws {
        // Given payment and setup intents that have already entered processing
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        let actions = makeProcessingActions(client: client)
        let errors = [
            NSError(domain: STPError.stripeDomain, code: STPErrorCode.authenticationError.rawValue),
            NSError(domain: STPError.stripeDomain, code: STPErrorCode.invalidRequestError.rawValue),
            NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue),
        ]
        for action in actions {
            for error in errors {
                // When retrieving the intent fails with a permanent API error
                client.error = error
                var result: STPPaymentHandlerPollingResult?
                action.retrievePollingResult { result = $0 }

                // Then polling receives a terminal failure instead of retrying forever
                XCTAssertEqual(try XCTUnwrap(result).status, .failed)
            }
        }
    }

    func testCancelDeadlineIgnoresLateApproval() throws {
        // Given a final status request that never responds
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        client.automaticallyCompletes = false
        let context = PaytoPollingAuthenticationContext()
        let canceled = expectation(description: "Cancellation finishes despite the stalled request")
        let action = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: client, authenticationContext: context, threeDSCustomizationSettings: .init(),
            paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .requiresAction, nextAction: .paytoAwaitAuthorization),
            returnURL: nil, completion: { status, _, _ in
                XCTAssertEqual(status, .canceled)
                canceled.fulfill()
            }
        )
        let controller = PollingViewController(currentAction: action, viewModel: FastPaytoPollingViewModel(), appearance: .default)
        controller.viewDidAppear(false)
        defer { controller.viewDidDisappear(false) }

        // When the customer taps Cancel, including a repeated tap
        controller.didTapCancel()
        let lateResponse = try XCTUnwrap(client.paymentIntentCompletion)
        controller.didTapCancel()

        // Then the final-check deadline expires and dismisses only once
        wait(for: [canceled], timeout: 1)
        XCTAssertEqual(context.dismissCount, 1)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 1)

        // ...and a late approval cannot restart polling or mutate the canceled action
        lateResponse(STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .processing), nil)
        XCTAssertEqual(action.paymentIntent.status, .requiresAction)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 1)
        XCTAssertEqual(context.dismissCount, 1)
    }

    func testFinalCheckAcceptsApprovalBeforeTimeoutOnlyOnce() {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        client.paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .processing)
        let action = makeProcessingActions(client: client)[0]
        var completions = 0

        // When authorization is observed before the final-check deadline
        action.retrievePollingResult(timeout: 0.05) { result in
            completions += 1
            XCTAssertEqual(result?.status, .processing)
        }

        // Then approval wins and the canceled timeout cannot complete again
        let deadlinePassed = expectation(description: "Final-check deadline has passed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { deadlinePassed.fulfill() }
        wait(for: [deadlinePassed], timeout: 1)
        XCTAssertEqual(completions, 1)
    }

    func testPermanentErrorStopsPollingAfterAuthorization() throws {
        // Given a customer who taps Cancel just as the bank authorizes the payment
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        client.automaticallyCompletes = false
        let context = PaytoPollingAuthenticationContext()
        let failed = expectation(description: "Permanent retrieval error ends the action")
        let action = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: client, authenticationContext: context, threeDSCustomizationSettings: .init(),
            paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .requiresAction, nextAction: .paytoAwaitAuthorization),
            returnURL: nil, completion: { status, _, _ in
                XCTAssertEqual(status, .canceled)
                failed.fulfill()
            }
        )
        let controller = PollingViewController(currentAction: action, viewModel: FastPaytoPollingViewModel(), appearance: .default)
        controller.viewDidAppear(false)
        defer { controller.viewDidDisappear(false) }
        controller.didTapCancel()
        try XCTUnwrap(client.paymentIntentCompletion)(STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .processing), nil)
        XCTAssertEqual(action.paymentIntent.status, .processing)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 2)

        // When the subsequent poll fails with a permanent API error
        try XCTUnwrap(client.paymentIntentCompletion)(nil, NSError(domain: STPError.stripeDomain, code: STPErrorCode.authenticationError.rawValue))

        // Then the existing failure flow completes and no further poll is scheduled
        wait(for: [failed], timeout: 1)
        let nextPollPassed = expectation(description: "Next polling interval has passed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { nextPollPassed.fulfill() }
        wait(for: [nextPollPassed], timeout: 2)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 2)
        withExtendedLifetime(controller) {}
    }

    func testCancellationCannotRestartPollingOnForeground() throws {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        client.automaticallyCompletes = false
        let context = PaytoPollingAuthenticationContext()
        let canceled = expectation(description: "Final check times out")
        let action = makePendingAction(client: client, context: context) { status, _, _ in
            XCTAssertEqual(status, .canceled)
            canceled.fulfill()
        }
        let controller = PollingViewController(currentAction: action, viewModel: FastPaytoPollingViewModel(), appearance: .default)
        controller.viewDidAppear(false)
        defer { controller.viewDidDisappear(false) }

        // Cancel while startup and foreground polling are still queued.
        controller.didBecomeActive(Notification(name: UIApplication.didBecomeActiveNotification))
        controller.didTapCancel()
        wait(for: [canceled], timeout: 1)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 1)

        // A subsequent foreground event must not revive the completed flow.
        controller.didBecomeActive(Notification(name: UIApplication.didBecomeActiveNotification))
        let settled = expectation(description: "Queued startup delay has elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { settled.fulfill() }
        wait(for: [settled], timeout: 1)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 1)
        XCTAssertEqual(context.dismissCount, 1)
    }

    func testBackgroundCancelsQueuedPollingAndForegroundResumes() {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        client.automaticallyCompletes = false
        let action = makePendingAction(client: client, context: PaytoPollingAuthenticationContext()) { _, _, _ in
            XCTFail("Backgrounding must not complete the action")
        }
        let controller = PollingViewController(currentAction: action, viewModel: FastPaytoPollingViewModel(), appearance: .default)
        controller.viewDidAppear(false)
        defer { controller.viewDidDisappear(false) }
        controller.didEnterBackground(Notification(name: UIApplication.didEnterBackgroundNotification))
        let settled = expectation(description: "Queued startup delay has elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { settled.fulfill() }
        wait(for: [settled], timeout: 1)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 0)

        let retrieved = expectation(description: "Foreground resumes polling")
        client.onPaymentIntentRetrieval = { retrieved.fulfill() }
        controller.didBecomeActive(Notification(name: UIApplication.didBecomeActiveNotification))
        wait(for: [retrieved], timeout: 1)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 1)
    }

    func testProcessingAtDeadlineContinuesUntilSuccess() throws {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        client.automaticallyCompletes = false
        let context = PaytoPollingAuthenticationContext()
        let succeeded = expectation(description: "Payment succeeds after the authorization deadline")
        let action = makePendingAction(client: client, context: context) { status, _, _ in
            XCTAssertEqual(status, .succeeded)
            succeeded.fulfill()
        }
        let model = FastPaytoPollingViewModel()
        model.deadline = Date().addingTimeInterval(-1)
        let controller = PollingViewController(currentAction: action, viewModel: model, appearance: .default)
        controller.viewDidAppear(false)
        defer { controller.viewDidDisappear(false) }
        let finalCheck = expectation(description: "Final status check")
        client.onPaymentIntentRetrieval = { finalCheck.fulfill() }
        controller.updateTimer()
        wait(for: [finalCheck], timeout: 1)
        client.onPaymentIntentRetrieval = nil

        // Processing at the deadline must resume polling instead of showing failure.
        try XCTUnwrap(client.paymentIntentCompletion)(STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .processing), nil)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 2)
        controller.updateTimer()
        controller.didTapCancel()
        XCTAssertEqual(context.dismissCount, 0)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 2)
        try XCTUnwrap(client.paymentIntentCompletion)(STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .succeeded), nil)
        wait(for: [succeeded], timeout: 1)
        XCTAssertEqual(context.dismissCount, 1)
    }

    func testBackgroundDefersExpiredDeadlineCheckUntilForeground() {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        client.automaticallyCompletes = false
        let action = makePendingAction(client: client, context: PaytoPollingAuthenticationContext()) { _, _, _ in
            XCTFail("No status has been received yet")
        }
        let model = FastPaytoPollingViewModel()
        model.deadline = Date().addingTimeInterval(-1)
        let controller = PollingViewController(currentAction: action, viewModel: model, appearance: .default)
        controller.viewDidAppear(false)
        defer { controller.viewDidDisappear(false) }
        controller.didEnterBackground(Notification(name: UIApplication.didEnterBackgroundNotification))
        controller.updateTimer()
        let settled = expectation(description: "Final-check delay has elapsed in the background")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { settled.fulfill() }
        wait(for: [settled], timeout: 1)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 0)

        let retrieved = expectation(description: "Foreground performs the final check")
        client.onPaymentIntentRetrieval = { retrieved.fulfill() }
        controller.didBecomeActive(Notification(name: UIApplication.didBecomeActiveNotification))
        wait(for: [retrieved], timeout: 1)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 1)
    }

    func testHandlerResumesProcessingPaymentAndSetupIntents() {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        let context = PaytoPollingAuthenticationContext()
        let handler = STPPaymentHandler(apiClient: client)
        var completionCount = 0
        handler._handleNextAction(
            forPayment: STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .processing),
            with: context, returnURL: nil
        ) { _, _, _ in completionCount += 1 }
        XCTAssertEqual(context.presentedPollingStatuses, [.processing])
        XCTAssertEqual(completionCount, 0)
        let setupHandler = STPPaymentHandler(apiClient: client)
        setupHandler._handleNextAction(
            for: STPFixtures.setupIntent(paymentMethodTypes: ["payto"], status: .processing),
            with: context, returnURL: nil
        ) { _, _, _ in completionCount += 1 }
        XCTAssertEqual(context.presentedPollingStatuses, [.processing, .processing])
        XCTAssertEqual(completionCount, 0)
    }

    func testInitiallyProcessingIntentShowsProcessingAndCannotBeCanceled() {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        let context = PaytoPollingAuthenticationContext()
        let succeeded = expectation(description: "Processing intent reaches success")
        let action = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: client, authenticationContext: context, threeDSCustomizationSettings: .init(),
            paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .processing),
            returnURL: nil, completion: { status, _, _ in
                XCTAssertEqual(status, .succeeded)
                succeeded.fulfill()
            }
        )
        let controller = PollingViewController(currentAction: action, viewModel: FastPaytoPollingViewModel(), appearance: .default)
        controller.loadViewIfNeeded()
        controller.viewDidAppear(false)
        defer { controller.viewDidDisappear(false) }
        let labels = controller.formStackView.arrangedSubviews.compactMap { ($0 as? UILabel)?.text }
        XCTAssertTrue(labels.contains(String.Localized.payto_processing))
        XCTAssertFalse(labels.contains(String.Localized.payto_authorize_payment))
        XCTAssertTrue(controller.formStackView.arrangedSubviews.compactMap { $0 as? UIButton }.allSatisfy(\.isHidden))
        controller.didTapCancel()
        XCTAssertEqual(context.dismissCount, 0)
        XCTAssertEqual(client.paymentIntentRetrievalCount, 0)
        client.paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .succeeded)
        wait(for: [succeeded], timeout: 1)
        XCTAssertEqual(context.dismissCount, 1)
    }

    private func makePendingAction(client: STPAPIClient, context: STPAuthenticationContext, completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock) -> STPPaymentHandlerPaymentIntentActionParams {
        STPPaymentHandlerPaymentIntentActionParams(
            apiClient: client, authenticationContext: context, threeDSCustomizationSettings: .init(),
            paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .requiresAction, nextAction: .paytoAwaitAuthorization),
            returnURL: nil, completion: completion
        )
    }

    private func makeProcessingActions(client: STPAPIClient) -> [STPPaymentHandlerActionParams] {
        [
            STPPaymentHandlerPaymentIntentActionParams(
                apiClient: client, authenticationContext: self, threeDSCustomizationSettings: .init(),
                paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["payto"], status: .processing),
                returnURL: nil, completion: { _, _, _ in }
            ),
            STPPaymentHandlerSetupIntentActionParams(
                apiClient: client, authenticationContext: self, threeDSCustomizationSettings: .init(),
                setupIntent: STPFixtures.setupIntent(paymentMethodTypes: ["payto"], status: .processing),
                returnURL: nil, completion: { _, _, _ in }
            ),
        ]
    }

    func testPaymentPollingWaitsThroughProcessingAndAcceptsFinalStatus() throws {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        let action = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: client, authenticationContext: self,
            threeDSCustomizationSettings: .init(),
            paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["card", "payto"], nextAction: .paytoAwaitAuthorization),
            returnURL: nil, completion: { _, _, _ in }
        )
        for (status, expected) in [(STPPaymentIntentStatus.processing, STPPaymentHandlerPollingStatus.processing), (.succeeded, .succeeded), (.requiresCapture, .succeeded), (.requiresPaymentMethod, .failed), (.canceled, .failed)] {
            client.paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["card", "payto"], status: status)
            var result: STPPaymentHandlerPollingResult?
            action.retrievePollingResult { result = $0 }
            XCTAssertEqual(try XCTUnwrap(result).status, expected)
            result?.updateActionIntent()
            XCTAssertEqual(action.paymentIntent.status, status)
        }
    }

    func testSetupPollingWaitsThroughProcessingAndAcceptsFinalStatus() throws {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_payto")
        let action = STPPaymentHandlerSetupIntentActionParams(
            apiClient: client, authenticationContext: self,
            threeDSCustomizationSettings: .init(),
            setupIntent: STPFixtures.setupIntent(paymentMethodTypes: ["card", "payto"], nextAction: .paytoAwaitAuthorization),
            returnURL: nil, completion: { _, _, _ in }
        )
        for (status, expected) in [(STPSetupIntentStatus.processing, STPPaymentHandlerPollingStatus.processing), (.succeeded, .succeeded), (.requiresPaymentMethod, .failed), (.canceled, .failed)] {
            client.setupIntent = STPFixtures.setupIntent(paymentMethodTypes: ["card", "payto"], status: status)
            var result: STPPaymentHandlerPollingResult?
            action.retrievePollingResult { result = $0 }
            XCTAssertEqual(try XCTUnwrap(result).status, expected)
            result?.updateActionIntent()
            XCTAssertEqual(action.setupIntent.status, status)
        }
    }

    func testOtherPaymentMethodsKeepExistingProcessingBehavior() throws {
        let client = PaytoPollingAPIClient(publishableKey: "pk_test_bizum")
        let action = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: client, authenticationContext: self,
            threeDSCustomizationSettings: .init(),
            paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["bizum"], nextAction: .awaitAuthorization),
            returnURL: nil, completion: { _, _, _ in }
        )
        client.paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["bizum"], status: .processing)
        var result: STPPaymentHandlerPollingResult?
        action.retrievePollingResult { result = $0 }
        XCTAssertEqual(try XCTUnwrap(result).status, .failed)

        client.paymentIntent = nil
        client.error = NSError(domain: STPError.stripeDomain, code: STPErrorCode.authenticationError.rawValue)
        action.retrievePollingResult { XCTAssertNil($0) }
    }
}

private class PaytoPollingAPIClient: STPAPIClient {
    var paymentIntent: STPPaymentIntent?
    var setupIntent: STPSetupIntent?
    var error: NSError?
    var automaticallyCompletes = true
    var paymentIntentCompletion: STPPaymentIntentCompletionBlock?
    var paymentIntentRetrievalCount = 0
    var onPaymentIntentRetrieval: (() -> Void)?

    override func retrievePaymentIntent(withClientSecret secret: String, expand: [String]?, timeout: NSNumber?, completion: @escaping STPPaymentIntentCompletionBlock) {
        paymentIntentRetrievalCount += 1
        paymentIntentCompletion = completion
        onPaymentIntentRetrieval?()
        if automaticallyCompletes {
            completion(paymentIntent, error)
        }
    }

    override func retrieveSetupIntent(withClientSecret secret: String, expand: [String]?, timeout: NSNumber?, completion: @escaping STPSetupIntentCompletionBlock) {
        completion(setupIntent, error)
    }
}

private class PaytoPollingAuthenticationContext: NSObject, PaymentSheetAuthenticationContext {
    var dismissCount = 0
    var presentedPollingStatuses: [STPPaymentHandlerPollingStatus] = []

    func authenticationPresentingViewController() -> UIViewController { UIViewController() }

    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {
        completion()
    }

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        dismissCount += 1
        completion?()
    }

    func presentPollingVCForAction(action: STPPaymentHandlerActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        XCTAssertEqual(type, .payto)
        presentedPollingStatuses.append(action.pollingStatus)
    }
}

private class FastPaytoPollingViewModel: PollingViewModel {
    override var initialPollDelay: TimeInterval { 0.03 }
    override var retryInterval: TimeInterval { 0.03 }
    override var finalPollDelay: TimeInterval { 0.03 }
    override var cancellationCheckTimeout: TimeInterval { 0.03 }

    init() {
        super.init(paymentMethodType: .payto)
    }
}

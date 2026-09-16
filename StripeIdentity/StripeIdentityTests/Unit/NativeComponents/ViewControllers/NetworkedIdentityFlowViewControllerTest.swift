//
//  NetworkedIdentityFlowViewControllerTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit
import XCTest

@testable import StripeIdentity

@MainActor
final class NetworkedIdentityFlowViewControllerTest: XCTestCase {
    private struct AccessibilityScreenChange {
        weak var focusView: UIView?
    }

    private var apiClient: NetworkedIdentityAPIClientTestMock!
    private var coordinator: NetworkedIdentityCoordinator!
    private var viewController: NetworkedIdentityFlowViewController!
    // swiftlint:disable:next weak_delegate
    private var delegate: NetworkedIdentityFlowViewControllerDelegateSpy!
    private var otpBodyPhoneNumbers: [String] = []
    private var otpSendingBodyPhoneNumbers: [String] = []
    private var accessibilityScreenChanges: [AccessibilityScreenChange] = []

    override func setUp() {
        super.setUp()
        setUpFlow()
    }

    private func setUpFlow(
        providedEmailAddress: String? = nil,
        identityAPIClient: IdentityAPIClient? = nil
    ) {
        accessibilityScreenChanges = []
        apiClient = NetworkedIdentityAPIClientTestMock()
        coordinator = NetworkedIdentityCoordinator(
            apiClient: apiClient,
            documentRequirements: .init(
                allowedDocumentTypes: [.passport, .drivingLicense, .idCard],
                requiresLiveCapture: false
            ),
            identityAPIClient: identityAPIClient,
            verificationSessionClientSecrets: ["vs_client_secret"]
        )
        viewController = NetworkedIdentityFlowViewController(
            coordinator: coordinator,
            content: makeContent(),
            providedEmailAddress: providedEmailAddress,
            postAccessibilityNotification: { [weak self] notification, argument in
                if notification == .screenChanged, let focusView = argument as? UIView {
                    self?.accessibilityScreenChanges.append(.init(focusView: focusView))
                }
            }
        )
        delegate = NetworkedIdentityFlowViewControllerDelegateSpy()
        viewController.delegate = delegate
        viewController.loadViewIfNeeded()
    }

    func testProvidedEmailStartsLookupOnceWhenFlowAppears() {
        // Given a merchant supplied a valid email, with incidental whitespace
        setUpFlow(providedEmailAddress: "  consumer@example.com\n")
        XCTAssertEqual(coordinator.state, .collectEmail)
        XCTAssertTrue(apiClient.lookup.requestHistory.isEmpty)

        // When the screen appears more than once
        viewController.viewDidAppear(false)
        viewController.viewDidAppear(false)

        // Then the supplied email is used without another user submission
        XCTAssertEqual(coordinator.state, .lookupPending)
        XCTAssertEqual(
            apiClient.lookup.requestHistory,
            [.init(emailAddress: "consumer@example.com", verificationSessionClientSecrets: ["vs_client_secret"])]
        )
        XCTAssertFalse(viewController.emailView.isUserInteractionEnabled)
    }

    func testMissingOrInvalidProvidedEmailStaysEditable() {
        let emailAddresses: [String?] = [nil, " \n ", "not-an-email"]
        for emailAddress in emailAddresses {
            // Given the supplied email cannot be used for lookup
            setUpFlow(providedEmailAddress: emailAddress)

            // When the screen appears
            viewController.viewDidAppear(false)

            // Then normal email entry remains available without a network request
            XCTAssertEqual(coordinator.state, .collectEmail)
            XCTAssertTrue(apiClient.lookup.requestHistory.isEmpty)
            XCTAssertTrue(viewController.emailView.isUserInteractionEnabled)
            XCTAssertFalse(viewController.emailView.hasValidEmailAddress)
        }
    }

    func testProvidedEmailDoesNotStartLookupAfterCancellation() {
        // Given the host cancels before showing the screen
        setUpFlow(providedEmailAddress: "consumer@example.com")
        viewController.cancel()

        // When an appearance callback arrives afterward
        viewController.viewDidAppear(false)

        // Then the ended flow cannot restart lookup
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(apiClient.lookup.requestHistory.isEmpty)
        XCTAssertEqual(delegate.cancelCount, 1)
    }

    func testSanitizedProvidedEmailRequiresExplicitSubmission() {
        for emailAddress in ["john doe@example.com", "john\ndoe@example.com"] {
            // Given input sanitization would change the supplied address into a valid one
            setUpFlow(providedEmailAddress: emailAddress)
            XCTAssertTrue(viewController.emailView.hasValidEmailAddress)
            XCTAssertNotEqual(viewController.emailView.emailAddress, emailAddress)

            // When the screen appears
            viewController.viewDidAppear(false)

            // Then the consumer must explicitly review and submit the changed address
            XCTAssertEqual(coordinator.state, .collectEmail)
            XCTAssertTrue(apiClient.lookup.requestHistory.isEmpty)
            XCTAssertTrue(viewController.emailView.isUserInteractionEnabled)
        }
    }

    func testProvidedEmailDoesNotAutomaticallyRetryAfterSessionExpiry() {
        // Given automatic lookup has started verification
        setUpFlow(providedEmailAddress: "consumer@example.com")
        viewController.viewDidAppear(false)
        waitForState(.otpStartPending) {
            apiClient.lookup.respondToNext(with: .success(existingConsumerLookupResponse()))
        }

        // When that session expires and the screen appears again
        waitForState(.reauthenticationRequired) {
            apiClient.startVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_session_expired"))
            )
        }
        viewController.viewDidAppear(false)

        // Then sign-in stays explicit instead of looping through automatic lookup
        XCTAssertEqual(coordinator.state, .reauthenticationRequired)
        XCTAssertEqual(apiClient.lookup.requestHistory.count, 1)
        XCTAssertTrue(viewController.emailView.isUserInteractionEnabled)
    }

    func testResendDisablesInputAndReplacesTheOTPControl() throws {
        // Given the consumer has started entering a code
        beginExistingConsumerFlow()
        let originalOTPView = try XCTUnwrap(viewController.phoneOtpView)
        let originalCodeField = try XCTUnwrap(
            originalOTPView.descendants(ofType: OneTimeCodeTextField.self).first
        )
        originalCodeField.value = "123"
        let resendButton = try XCTUnwrap(
            viewController.view.descendants(ofType: StripeUICore.Button.self).first {
                $0.title == String.Localized.resend_code
            }
        )
        XCTAssertTrue(resendButton.isEnabled)

        // When they resend the code
        let buttonTarget = try XCTUnwrap(resendButton.allTargets.first as? NSObject)
        let buttonAction = try XCTUnwrap(
            resendButton.actions(forTarget: buttonTarget, forControlEvent: .touchUpInside)?.first
        )
        buttonTarget.perform(NSSelectorFromString(buttonAction), with: resendButton)

        // Then the old code is cleared and further resend/submission is disabled
        XCTAssertEqual(coordinator.state, .otpStartPending)
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 2)
        XCTAssertEqual(apiClient.startVerification.requestHistory.last?.request.isResendingSMSCode, true)
        XCTAssertEqual(originalCodeField.value, "")
        XCTAssertFalse(originalOTPView === viewController.phoneOtpView)
        XCTAssertEqual(viewController.phoneOtpView?.viewModel, .SubmittingOTP(""))
        XCTAssertFalse(
            try XCTUnwrap(viewController.view.descendants(ofType: StripeUICore.Button.self).first {
                $0.title == String.Localized.resend_code
            }).isEnabled
        )

        // When Link resends within the same active verification session
        waitForState(.awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(consumerSessionResponse(clientSecret: "cs_resent", verificationSessionState: .started))
            )
        }

        // Then code entry and resend become available again
        XCTAssertEqual(viewController.phoneOtpView?.viewModel, .InputtingOTP)
        XCTAssertTrue(
            try XCTUnwrap(viewController.view.descendants(ofType: StripeUICore.Button.self).first {
                $0.title == String.Localized.resend_code
            }).isEnabled
        )
    }

    func testValidEmailStartsLookupAndDisablesDuplicateInput() {
        // Given the email screen has valid input
        viewController.emailView.emailElement.setText("consumer@example.com")

        // When the field is submitted
        viewController.emailView.continueToNextField(
            element: viewController.emailView.emailElement
        )
        viewController.emailView.continueToNextField(
            element: viewController.emailView.emailElement
        )

        // Then lookup starts once and the email form is disabled while it is pending
        XCTAssertEqual(coordinator.state, .lookupPending)
        XCTAssertEqual(
            apiClient.lookup.requestHistory,
            [
                .init(
                    emailAddress: "consumer@example.com",
                    verificationSessionClientSecrets: ["vs_client_secret"]
                ),
            ]
        )
        XCTAssertFalse(viewController.emailView.isUserInteractionEnabled)
        XCTAssertFalse(viewController.emailView.emailElement.view.isUserInteractionEnabled)
        XCTAssertEqual(viewController.visibleStep, .email)
    }

    func testExistingConsumerMovesToOTPUsingOnlyRedactedPhoneNumber() {
        // Given lookup is pending for a valid email
        startLookup()

        // When an existing Link consumer is returned
        waitForState(.otpStartPending) {
            apiClient.lookup.respondToNext(with: .success(existingConsumerLookupResponse()))
        }

        // Then the SMS screen receives the display-safe phone number
        XCTAssertEqual(viewController.visibleStep, .otp)
        XCTAssertEqual(otpSendingBodyPhoneNumbers.last, "+1 *** *** 0123")
        XCTAssertEqual(viewController.phoneOtpView?.viewModel, .SubmittingOTP(""))
    }

    func testInvalidOTPReturnsToEditableErrorState() {
        // Given a fresh SMS code is ready for entry
        beginExistingConsumerFlow()

        // When the consumer submits an invalid code
        viewController.didInputFullOtp(newOtp: "111111")
        XCTAssertEqual(viewController.phoneOtpView?.viewModel, .SubmittingOTP(""))
        waitForState(.awaitingOTP) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(
                    NSError(
                        domain: "NetworkedIdentityFlowViewControllerTest",
                        code: 0,
                        userInfo: [
                            STPError.stripeErrorCodeKey:
                                "consumer_verification_code_invalid",
                        ]
                    )
                )
            )
        }

        // Then the existing OTP control exposes its inline invalid-code state
        XCTAssertEqual(viewController.visibleStep, .otp)
        XCTAssertEqual(viewController.phoneOtpView?.viewModel, .ErrorOTP)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 1)
    }

    func testExpiredConsumerSessionReturnsToEmailAndUsesFreshOTPView() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // Given the consumer is entering an SMS code
        beginExistingConsumerFlow()
        weak var expiredSessionOTPView = viewController.phoneOtpView

        // When Link reports that the consumer session expired
        viewController.didInputFullOtp(newOtp: "111111")
        waitForState(.reauthenticationRequired) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(
                    consumerError(code: "consumer_session_expired")
                )
            )
        }

        // Then the flow requires another explicit lookup
        XCTAssertEqual(viewController.visibleStep, .email)
        XCTAssertTrue(viewController.emailView.isUserInteractionEnabled)
        XCTAssertTrue(viewController.emailView.emailElement.view.isUserInteractionEnabled)
        XCTAssertTrue(viewController.emailView.emailElement.isEditing)
        XCTAssertNil(expiredSessionOTPView)
        viewController.emailView.continueToNextField(
            element: viewController.emailView.emailElement
        )
        XCTAssertEqual(coordinator.state, .lookupPending)

        // When lookup succeeds again, the expired code-entry control is not reused
        waitForState(.otpStartPending) {
            apiClient.lookup.respondToNext(with: .success(existingConsumerLookupResponse()))
        }
        XCTAssertNotNil(viewController.phoneOtpView)
    }

    func testVerifiedConsumerCanSelectAndChangeSavedDocument() {
        // Given a freshly verified consumer has two reusable documents
        beginExistingConsumerFlow()
        weak var authenticatedOTPView = viewController.phoneOtpView
        viewController.didInputFullOtp(newOtp: "123456")
        waitForState(.documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_confirmed",
                        verificationSessionState: .verified
                    )
                )
            )
        }
        XCTAssertEqual(viewController.visibleStep, .documents)
        XCTAssertNil(authenticatedOTPView)
        XCTAssertTrue(viewController.documentSelectionView.isLoading)
        XCTAssertTrue(
            viewController.view.descendants(ofType: ActivityIndicator.self).contains {
                $0.isAnimating
            }
        )
        let firstDocument = identityDocument(id: "id_doc_first")
        let secondDocument = identityDocument(
            id: "id_doc_second",
            documentType: .passport
        )
        waitForState(.selectDocument) {
            apiClient.documentList.respondToNext(
                with: .success(.init(data: [firstDocument, secondDocument]))
            )
        }

        // When they select the second document and then change to the first
        var documentRows = viewController.view.descendants(ofType: ListItemView.self)
        XCTAssertEqual(documentRows.count, 2)
        XCTAssertTrue(documentRows[1].accessibilityActivate())
        documentRows = viewController.view.descendants(ofType: ListItemView.self)
        XCTAssertTrue(documentRows[0].accessibilityActivate())

        // Then the UI preserves server order and the coordinator retains the latest selection
        XCTAssertEqual(viewController.visibleStep, .documents)
        XCTAssertFalse(viewController.documentSelectionView.isLoading)
        XCTAssertFalse(
            viewController.view.descendants(ofType: ActivityIndicator.self).contains {
                $0.isAnimating
            }
        )
        XCTAssertEqual(
            viewController.documentSelectionView.documents.map(\.id),
            ["id_doc_first", "id_doc_second"]
        )
        XCTAssertEqual(coordinator.state, .selectedDocument)
        XCTAssertEqual(coordinator.selectedDocument, firstDocument)
        XCTAssertEqual(
            viewController.documentSelectionView.selectedDocumentID,
            firstDocument.id
        )
        documentRows = viewController.view.descendants(ofType: ListItemView.self)
        XCTAssertTrue(documentRows[0].accessibilityTraits.contains(.selected))
        XCTAssertFalse(documentRows[1].accessibilityTraits.contains(.selected))
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 0)
    }

    func testContinueAttachesSelectedDocumentAndNotifiesHostOnce() throws {
        // Given a v8 flow has a reusable document, but the consumer has not selected it
        let identityAPI = IdentityAPIClientTestMock(verificationSessionId: "vs_123")
        identityAPI.supportsNetworkedIdentity = true
        setUpFlow(identityAPIClient: identityAPI)
        beginExistingConsumerFlow()
        viewController.didInputFullOtp(newOtp: "123456")
        waitForState(.documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(consumerSessionResponse(clientSecret: "cs_confirmed", verificationSessionState: .verified))
            )
        }
        let document = identityDocument(id: "id_doc_123")
        waitForState(.selectDocument) {
            apiClient.documentList.respondToNext(with: .success(.init(data: [document])))
        }
        let continueButton = try XCTUnwrap(
            viewController.view.descendants(ofType: StripeUICore.Button.self).first {
                $0.title == String.Localized.continue
            }
        )
        XCTAssertFalse(continueButton.isEnabled)

        // When they select the document and explicitly continue
        coordinator.selectDocument(document)
        XCTAssertTrue(continueButton.isEnabled)
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        viewController.viewDidAppear(false)
        accessibilityScreenChanges = []
        let target = try XCTUnwrap(continueButton.allTargets.first as? NSObject)
        let action = try XCTUnwrap(continueButton.actions(forTarget: target, forControlEvent: .touchUpInside)?.first)
        target.perform(NSSelectorFromString(action), with: continueButton)

        // Then the pending screen prevents another attach or manual-capture race
        XCTAssertEqual(coordinator.state, .attachmentPending)
        XCTAssertTrue(viewController.documentSelectionView.isLoading)
        XCTAssertTrue(delegate.completionResults.isEmpty)
        XCTAssertEqual(accessibilityScreenChanges.count, 1)
        XCTAssertTrue(accessibilityScreenChanges.first?.focusView?.isAccessibilityElement == true)
        XCTAssertEqual(accessibilityScreenChanges.first?.focusView?.accessibilityLabel, "Reusing your identity document")
        let attachRequested = expectation(description: "Selected document attachment starts")
        identityAPI.attachNetworkedIdentityDocument.callBackOnRequest { attachRequested.fulfill() }
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "single_use_token")))
        wait(for: [attachRequested], timeout: 1)

        // When attachment returns the remaining Identity requirements
        let pageData = StripeAPI.VerificationPageData(
            id: "vs_123", requirements: .init(errors: [], missing: [.face]),
            status: .requiresInput, submitted: false, closed: false
        )
        waitForState(.completed) {
            identityAPI.attachNetworkedIdentityDocument.respondToNext(with: .success(pageData))
        }
        viewController.cancel()

        // Then the host receives requirements once, not a successful-verification signal
        XCTAssertEqual(delegate.completionResults.count, 1)
        XCTAssertEqual(try delegate.completionResults.first?.get(), pageData)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItem?.isEnabled, false)
        XCTAssertEqual(delegate.cancelCount, 0)
        XCTAssertTrue(delegate.fallbackReasons.isEmpty)
    }

    func testExplicitManualCaptureWaitsForSkipBeforeCompleting() throws {
        // Given the v8 flow is still on email entry
        let identityAPI = IdentityAPIClientTestMock(verificationSessionId: "vs_123")
        identityAPI.supportsNetworkedIdentity = true
        setUpFlow(identityAPIClient: identityAPI)

        // When the consumer chooses manual capture twice
        viewController.chooseManualCapture()
        viewController.chooseManualCapture()

        // Then only one skip is sent, and no navigation occurs until it finishes
        XCTAssertEqual(coordinator.state, .skipPending)
        XCTAssertEqual(identityAPI.networkedIdentitySkip.requestHistory.count, 1)
        XCTAssertTrue(delegate.completionResults.isEmpty)
        XCTAssertTrue(delegate.fallbackReasons.isEmpty)
        let pageData = StripeAPI.VerificationPageData(
            id: "vs_123", requirements: .init(errors: [], missing: [.idDocumentFront]),
            status: .requiresInput, submitted: false, closed: false
        )
        waitForState(.completed) {
            identityAPI.networkedIdentitySkip.respondToNext(with: .success(pageData))
        }
        XCTAssertEqual(delegate.completionResults.count, 1)
        XCTAssertEqual(try delegate.completionResults.first?.get(), pageData)
    }

    func testSkipWhileLoadingDocumentsAnnouncesNewAccessibleStatus() {
        // Given document loading has already been announced to VoiceOver
        let identityAPI = IdentityAPIClientTestMock(verificationSessionId: "vs_123")
        identityAPI.supportsNetworkedIdentity = true
        setUpFlow(identityAPIClient: identityAPI)
        beginExistingConsumerFlow()
        viewController.didInputFullOtp(newOtp: "123456")
        waitForState(.documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(consumerSessionResponse(clientSecret: "cs_confirmed", verificationSessionState: .verified))
            )
        }
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        viewController.viewDidAppear(false)
        XCTAssertEqual(accessibilityScreenChanges.count, 1)
        accessibilityScreenChanges = []

        // When the consumer switches to manual capture while document loading is pending
        viewController.chooseManualCapture()

        // Then the new skip status is announced, with a nonempty accessible focus target
        XCTAssertEqual(coordinator.state, .skipPending)
        XCTAssertEqual(accessibilityScreenChanges.count, 1)
        XCTAssertTrue(accessibilityScreenChanges.first?.focusView?.isAccessibilityElement == true)
        XCTAssertEqual(accessibilityScreenChanges.first?.focusView?.accessibilityLabel, "Continuing without Link")
    }

    func testManualCaptureNotifiesHostOnce() throws {
        // When manual verification is selected more than once
        let manualCaptureButton = try XCTUnwrap(
            viewController.view.descendants(ofType: StripeUICore.Button.self).first {
                $0.title == "Verify another way"
            }
        )
        XCTAssertTrue(manualCaptureButton.isEnabled)
        let buttonTarget = try XCTUnwrap(
            manualCaptureButton.allTargets.first as? NSObject
        )
        let buttonAction = try XCTUnwrap(
            manualCaptureButton.actions(
                forTarget: buttonTarget,
                forControlEvent: .touchUpInside
            )?.first
        )
        buttonTarget.perform(NSSelectorFromString(buttonAction), with: manualCaptureButton)
        buttonTarget.perform(NSSelectorFromString(buttonAction), with: manualCaptureButton)

        // Then the host receives one fallback request with the explicit reason
        XCTAssertEqual(delegate.fallbackReasons, [.userSelectedManualCapture])
        XCTAssertEqual(delegate.cancelCount, 0)
    }

    func testCancellationNotifiesHostOnce() throws {
        // When cancellation is requested more than once
        let cancelButton = try XCTUnwrap(viewController.navigationItem.rightBarButtonItem)
        let cancelTarget = try XCTUnwrap(cancelButton.target as? NSObject)
        let cancelAction = try XCTUnwrap(cancelButton.action)
        cancelTarget.perform(cancelAction, with: cancelButton)
        cancelTarget.perform(cancelAction, with: cancelButton)

        // Then the host receives one cancellation and no fallback request
        XCTAssertEqual(delegate.cancelCount, 1)
        XCTAssertTrue(delegate.fallbackReasons.isEmpty)
    }

    func testInteractivePopIsDisabledOnlyWhileFlowIsVisible() {
        // Given the flow is pushed onto a navigation stack with swipe-back enabled
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(viewController, animated: false)
        navigationController.interactivePopGestureRecognizer?.isEnabled = true

        // When the Networked Identity flow appears
        viewController.viewWillAppear(false)

        // Then swipe-back is disabled so cancellation cannot bypass Link cleanup
        XCTAssertEqual(navigationController.interactivePopGestureRecognizer?.isEnabled, false)

        // When the flow leaves the stack, the prior navigation behavior is restored
        viewController.viewWillDisappear(false)
        XCTAssertEqual(navigationController.interactivePopGestureRecognizer?.isEnabled, true)
    }
}

private extension NetworkedIdentityFlowViewControllerTest {
    func makeContent() -> NetworkedIdentityFlowViewController.Content {
        .init(
            email: .init(
                title: "Verify your identity",
                body: "Enter your email",
                reauthenticationTitle: "Sign in again",
                reauthenticationBody: "Your session expired",
                continueButtonText: "Continue"
            ),
            otp: .init(
                title: "Check your phone",
                sendingBody: { [weak self] phoneNumber in
                    self?.otpSendingBodyPhoneNumbers.append(phoneNumber)
                    return "Sending a code to \(phoneNumber)"
                },
                body: { [weak self] phoneNumber in
                    self?.otpBodyPhoneNumbers.append(phoneNumber)
                    return "Enter the code sent to \(phoneNumber)"
                },
                invalidCodeMessage: "That code wasn't right"
            ),
            documents: .init(
                title: "Choose a saved ID",
                body: "Select an ID to continue",
                loadingTitle: "Loading saved IDs",
                loadingBody: "Finding your saved IDs",
                label: { document in
                    "\(document.documentType.rawValue) \(document.redactedDocumentNumber ?? "")"
                },
                accessibilityLabel: { document, isSelected in
                    "\(document.id)\(isSelected ? ", selected" : "")"
                }
            ),
            manualCaptureButtonText: "Verify another way",
            cancelButtonText: "Cancel"
        )
    }

    func startLookup() {
        viewController.emailView.emailElement.setText("consumer@example.com")
        viewController.emailView.continueToNextField(
            element: viewController.emailView.emailElement
        )
        XCTAssertEqual(coordinator.state, .lookupPending)
    }

    func beginExistingConsumerFlow() {
        startLookup()
        waitForState(.otpStartPending) {
            apiClient.lookup.respondToNext(with: .success(existingConsumerLookupResponse()))
        }
        waitForState(.awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_started",
                        verificationSessionState: .started
                    )
                )
            )
        }
        XCTAssertEqual(viewController.phoneOtpView?.viewModel, .InputtingOTP)
        XCTAssertEqual(otpBodyPhoneNumbers.last, "+1 *** *** 0123")
    }

    func waitForState(
        _ expectedState: NetworkedIdentityState,
        action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        action()
        let stateChanged = expectation(description: "State becomes \(expectedState)")
        let deadline = Date().addingTimeInterval(0.9)

        func checkState() {
            if coordinator.state == expectedState {
                stateChanged.fulfill()
            } else if Date() < deadline {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.01,
                    execute: checkState
                )
            }
        }
        DispatchQueue.main.async(execute: checkState)
        wait(for: [stateChanged], timeout: 1)
        XCTAssertEqual(coordinator.state, expectedState, file: file, line: line)
    }

    func existingConsumerLookupResponse() -> NetworkedIdentityLookupResponse {
        .found(
            .init(
                consumerSession: consumerSession(
                    clientSecret: "cs_lookup",
                    verificationSessionID: "cvs_old",
                    verificationSessionState: .verified
                ),
                publishableKey: "pk_consumer_lookup",
                accountID: "acct_123",
                authSessionClientSecret: nil,
                emailOTPRequiresAdditionalInfo: nil,
                emailOTPVerifyPhoneDespiteSMSOTP: nil,
                experiments: []
            )
        )
    }

    func consumerSessionResponse(
        clientSecret: String,
        verificationSessionState: NetworkedIdentityVerificationSessionState
    ) -> NetworkedIdentityConsumerSessionResponse {
        .init(
            consumerSession: consumerSession(
                clientSecret: clientSecret,
                verificationSessionID: "cvs_fresh",
                verificationSessionState: verificationSessionState
            ),
            authSessionClientSecret: nil
        )
    }

    func consumerSession(
        clientSecret: String,
        verificationSessionID: String,
        verificationSessionState: NetworkedIdentityVerificationSessionState
    ) -> NetworkedIdentityConsumerSession {
        .init(
            clientSecret: clientSecret,
            emailAddress: "consumer@example.com",
            redactedPhoneNumber: "(***) *** 0123",
            redactedFormattedPhoneNumber: "+1 *** *** 0123",
            unredactedPhoneNumber: "+14155550123",
            phoneNumberCountry: "US",
            verificationSessions: [
                .init(
                    id: verificationSessionID,
                    state: verificationSessionState,
                    type: .sms,
                    verificationToken: nil
                ),
            ]
        )
    }

    func identityDocument(
        id: String,
        documentType: NetworkedIdentityDocumentType = .drivingLicense
    ) -> NetworkedIdentityDocument {
        .init(
            id: id,
            documentType: documentType,
            created: 1_700_000_000,
            country: "US",
            region: "CA",
            redactedDocumentNumber: "***1234",
            expirationDate: 1_900_000_000,
            liveCaptured: true
        )
    }

    func consumerError(code: String) -> Error {
        NSError(
            domain: "NetworkedIdentityFlowViewControllerTest",
            code: 0,
            userInfo: [STPError.stripeErrorCodeKey: code]
        )
    }
}

private extension UIView {
    func descendants<View: UIView>(ofType type: View.Type) -> [View] {
        subviews.flatMap { subview in
            let matchingSubview = (subview as? View).map { [$0] } ?? []
            return matchingSubview + subview.descendants(ofType: type)
        }
    }
}

@MainActor
private final class NetworkedIdentityFlowViewControllerDelegateSpy:
    NetworkedIdentityFlowViewControllerDelegate
{
    private(set) var cancelCount = 0
    private(set) var fallbackReasons: [NetworkedIdentityFallbackReason] = []
    private(set) var completionResults: [Result<StripeAPI.VerificationPageData, Error>] = []

    func networkedIdentityFlowViewController(
        _ viewController: NetworkedIdentityFlowViewController,
        didCompleteWith result: Result<StripeAPI.VerificationPageData, Error>
    ) {
        completionResults.append(result)
    }

    func networkedIdentityFlowViewControllerDidCancel(
        _ viewController: NetworkedIdentityFlowViewController
    ) {
        cancelCount += 1
    }

    func networkedIdentityFlowViewController(
        _ viewController: NetworkedIdentityFlowViewController,
        didRequestFullCapture reason: NetworkedIdentityFallbackReason
    ) {
        fallbackReasons.append(reason)
    }
}

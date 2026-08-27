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
    private var apiClient: NetworkedIdentityAPIClientTestMock!
    private var coordinator: NetworkedIdentityCoordinator!
    private var viewController: NetworkedIdentityFlowViewController!
    // swiftlint:disable:next weak_delegate
    private var delegate: NetworkedIdentityFlowViewControllerDelegateSpy!
    private var otpBodyPhoneNumbers: [String] = []
    private var otpSendingBodyPhoneNumbers: [String] = []

    override func setUp() {
        super.setUp()
        apiClient = NetworkedIdentityAPIClientTestMock()
        coordinator = NetworkedIdentityCoordinator(
            apiClient: apiClient,
            verificationSessionClientSecrets: ["vs_client_secret"]
        )
        viewController = NetworkedIdentityFlowViewController(
            coordinator: coordinator,
            content: makeContent()
        )
        delegate = NetworkedIdentityFlowViewControllerDelegateSpy()
        viewController.delegate = delegate
        viewController.loadViewIfNeeded()
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

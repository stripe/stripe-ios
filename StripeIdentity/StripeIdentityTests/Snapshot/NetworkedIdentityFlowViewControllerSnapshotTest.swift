//
//  NetworkedIdentityFlowViewControllerSnapshotTest.swift
//  StripeIdentityTests
//

import iOSSnapshotTestCase
@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) import StripeUICore

@testable import StripeIdentity

@MainActor
final class NetworkedIdentityFlowViewControllerSnapshotTest: STPSnapshotTestCase {
    private static let snapshotFrame = CGRect(x: 0, y: 0, width: 375, height: 812)

    private lazy var apiClient = NetworkedIdentityAPIClientTestMock()
    private lazy var coordinator = NetworkedIdentityCoordinator(
        apiClient: apiClient,
        documentRequirements: .init(
            allowedDocumentTypes: [.passport, .drivingLicense, .idCard],
            requiresLiveCapture: false
        ),
        verificationSessionClientSecrets: ["vs_client_secret"],
        currentTime: { 1_800_000_000 }
    )
    private lazy var viewController: NetworkedIdentityFlowViewController = {
        let viewController = NetworkedIdentityFlowViewController(
            coordinator: coordinator
        )
        viewController.loadViewIfNeeded()
        return viewController
    }()
    private lazy var navigationController = UINavigationController(
        rootViewController: viewController
    )
    private lazy var window: UIWindow = {
        let window = UIWindow(frame: Self.snapshotFrame)
        window.rootViewController = navigationController
        window.isHidden = false
        return window
    }()

    func testEmailEntry() {
        verifyView()
    }

    func testEmailEntryWithValidEmail() {
        // When the consumer enters a valid email address
        viewController.emailView.emailElement.setText("jane.diaz@example.com")

        // Then the Link primary action uses its enabled treatment
        XCTAssertTrue(viewController.emailView.hasValidEmailAddress)
        verifyView()
    }

    func testAwaitingOTP() {
        // Given a fresh SMS code is ready for entry
        beginExistingConsumerFlow()

        // Then the standard Link verification state is visible
        XCTAssertEqual(coordinator.state, .awaitingOTP)
        XCTAssertEqual(viewController.phoneOtpView?.viewModel, .InputtingOTP)
        verifyView()
    }

    func testInvalidOTP() {
        // Given the consumer is entering the fresh SMS code
        beginExistingConsumerFlow()

        // When Link rejects the code
        viewController.didInputFullOtp(newOtp: "111111")
        waitForState(.awaitingOTP) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(
                    consumerError(code: "consumer_verification_code_invalid")
                )
            )
        }

        // Then the invalid-code UI remains visible and editable
        verifyView()
    }

    func testSelectedSavedDocument() {
        // Given a verified consumer has two reusable documents
        beginExistingConsumerFlow()
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
        let drivingLicense = identityDocument(
            id: "id_doc_license",
            documentType: .drivingLicense,
            redactedDocumentNumber: "•••• 4242"
        )
        let passport = identityDocument(
            id: "id_doc_passport",
            documentType: .passport,
            redactedDocumentNumber: "•••• 6789"
        )
        waitForState(.selectDocument) {
            apiClient.documentList.respondToNext(
                with: .success(.init(data: [drivingLicense, passport]))
            )
        }

        // When the consumer selects their passport
        coordinator.selectDocument(passport)

        // Then the selected state is visible in the saved-document list
        XCTAssertEqual(coordinator.state, .selectedDocument)
        verifyView()
    }
}

private extension NetworkedIdentityFlowViewControllerSnapshotTest {
    func verifyView(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        _ = window
        window.layoutIfNeeded()
        navigationController.view.layoutIfNeeded()
        XCTAssertEqual(navigationController.view.bounds, Self.snapshotFrame)
        STPSnapshotVerifyView(navigationController.view, file: file, line: line)
    }

    func beginExistingConsumerFlow() {
        viewController.emailView.emailElement.setText("consumer@example.com")
        viewController.emailView.continueToNextField(
            element: viewController.emailView.emailElement
        )
        waitForState(.otpStartPending) {
            apiClient.lookup.respondToNext(
                with: .success(existingConsumerLookupResponse())
            )
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
            redactedPhoneNumber: "(***) *** **34",
            redactedFormattedPhoneNumber: "(***) *** **34",
            unredactedPhoneNumber: nil,
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
        documentType: NetworkedIdentityDocumentType,
        redactedDocumentNumber: String
    ) -> NetworkedIdentityDocument {
        .init(
            id: id,
            documentType: documentType,
            created: 1_700_000_000,
            country: "US",
            region: "CA",
            redactedDocumentNumber: redactedDocumentNumber,
            expirationDate: 1_900_000_000,
            liveCaptured: true
        )
    }

    func consumerError(code: String) -> Error {
        NSError(
            domain: "NetworkedIdentityFlowViewControllerSnapshotTest",
            code: 0,
            userInfo: [STPError.stripeErrorCodeKey: code]
        )
    }
}

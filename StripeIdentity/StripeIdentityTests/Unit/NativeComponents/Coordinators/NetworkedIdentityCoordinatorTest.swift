//
//  NetworkedIdentityCoordinatorTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
import XCTest

@testable import StripeIdentity

@MainActor
final class NetworkedIdentityCoordinatorTest: XCTestCase {
    private var apiClient: NetworkedIdentityAPIClientTestMock!
    private var credentialStore: NetworkedIdentityCredentialStore!
    private var coordinator: NetworkedIdentityCoordinator!
    // swiftlint:disable:next weak_delegate
    private var delegate: NetworkedIdentityCoordinatorDelegateSpy!

    override func setUp() {
        super.setUp()
        setUpCoordinator()
    }

    private func setUpCoordinator(
        identityAPIClient: IdentityAPIClient? = nil,
        currentTime: @escaping () -> TimeInterval = { 1_800_000_000 }
    ) {
        apiClient = NetworkedIdentityAPIClientTestMock()
        credentialStore = NetworkedIdentityCredentialStore(
            verificationSessionClientSecrets: ["vs_client_secret"]
        )
        coordinator = NetworkedIdentityCoordinator(
            apiClient: apiClient,
            documentRequirements: .init(
                allowedDocumentTypes: [.passport, .drivingLicense, .idCard],
                requiresLiveCapture: false
            ),
            identityAPIClient: identityAPIClient,
            credentialStore: credentialStore,
            currentTime: currentTime
        )
        delegate = NetworkedIdentityCoordinatorDelegateSpy()
        coordinator.delegate = delegate
    }

    func testExistingConsumerAuthenticatesFreshAndSelectsDocument() {
        // Given an existing consumer whose previous SMS verification is already verified
        beginExistingConsumerFlow()
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 1)
        XCTAssertEqual(
            apiClient.startVerification.requestHistory.first?.request.type,
            .sms
        )

        // When the fresh SMS code is confirmed and saved documents load
        coordinator.submitOTP("123456")
        XCTAssertEqual(coordinator.state, .otpConfirmPending)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 1)
        XCTAssertEqual(
            apiClient.confirmVerification.requestHistory.first?.request.code,
            "123456"
        )
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_confirmed",
                        verificationState: .verified
                    )
                )
            )
        }
        XCTAssertEqual(
            apiClient.documentList.requestHistory.first?.consumerSessionClientSecret,
            "cs_confirmed"
        )

        let document = identityDocument(id: "id_doc_123")
        waitForTransition(to: .selectDocument) {
            apiClient.documentList.respondToNext(
                with: .success(.init(data: [document]))
            )
        }

        // Then selection waits for the user to explicitly continue before requesting reuse
        coordinator.selectDocument(identityDocument(id: document.id, country: "CA"))
        XCTAssertEqual(coordinator.state, .selectedDocument)
        XCTAssertEqual(coordinator.selectedDocument, document)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 0)
    }

    func testContinueRequiresV8ClientAndExplicitDocumentSelection() {
        // Given the existing standalone flow has no Identity mutation client
        beginSelectedDocumentFlow()
        coordinator.continueWithSelectedDocument()
        XCTAssertFalse(coordinator.supportsDocumentAttachment)
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)

        // When a v7 Identity client is present, attachment remains disabled
        let identityClient = IdentityAPIClientTestMock(verificationSessionId: "vs_target")
        setUpCoordinator(identityAPIClient: identityClient)
        beginSelectedDocumentFlow()
        coordinator.continueWithSelectedDocument()
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)

        // Then even v8 cannot request a token before the consumer has selected a document
        identityClient.supportsNetworkedIdentity = true
        setUpCoordinator(identityAPIClient: identityClient)
        coordinator.continueWithSelectedDocument()
        XCTAssertEqual(coordinator.state, .collectEmail)
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)
    }

    func testContinueMintsTokenThenAttachesWithConfirmedCredentialsAndCleansUp() throws {
        let identityClient = enableDocumentAttachment()
        beginSelectedDocumentFlow()
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)

        // When Continue is tapped repeatedly, or manual capture is tapped while attaching
        coordinator.continueWithSelectedDocument()
        coordinator.continueWithSelectedDocument()
        coordinator.chooseManualCapture()

        // Then one token is minted for the actual selected document and latest confirmed secret
        XCTAssertEqual(coordinator.state, .attachmentPending)
        XCTAssertEqual(apiClient.associationToken.requestHistory, [
            .init(
                identityDocumentID: "id_doc_selected",
                consumerSessionClientSecret: "cs_confirmed",
                consumerPublishableKey: "pk_consumer_lookup"
            ),
        ])
        XCTAssertTrue(identityClient.networkedIdentitySkip.requestHistory.isEmpty)
        XCTAssertTrue(identityClient.attachNetworkedIdentityDocument.requestHistory.isEmpty)

        respondWithAssociationToken(identityClient: identityClient)
        XCTAssertEqual(identityClient.attachNetworkedIdentityDocument.requestHistory, ["reuse_token"])
        let pageData = actionPageData()
        waitForTransition(to: .completed) {
            identityClient.attachNetworkedIdentityDocument.respondToNext(with: .success(pageData))
        }

        XCTAssertEqual(try delegate.completions.first?.get(), pageData)
        XCTAssertEqual(delegate.completions.count, 1)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 0)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertNil(coordinator.selectedDocument)
        XCTAssertNil(coordinator.emailAddress)
        XCTAssertTrue(coordinator.availableDocuments.isEmpty)
        XCTAssertEqual(apiClient.logOut.requestHistory.first?.consumerSessionClientSecret, "cs_confirmed")
        coordinator.continueWithSelectedDocument()
        coordinator.chooseManualCapture()
        coordinator.cancel()
        XCTAssertEqual(coordinator.state, .completed)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 1)
    }

    func testContinueRechecksDocumentExpirationBeforeMintingToken() {
        // Given a selected document was eligible when it was listed
        let identityClient = IdentityAPIClientTestMock(verificationSessionId: "vs_target")
        identityClient.supportsNetworkedIdentity = true
        var now: TimeInterval = 1_800_000_000
        setUpCoordinator(identityAPIClient: identityClient, currentTime: { now })
        beginSelectedDocumentFlow()

        // When that document expires while the consumer is deciding whether to continue
        now = 1_900_000_000
        coordinator.continueWithSelectedDocument()

        // Then manual capture resumes without minting or attaching an expired document
        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 1)
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)
        XCTAssertTrue(identityClient.attachNetworkedIdentityDocument.requestHistory.isEmpty)
        XCTAssertTrue(identityClient.networkedIdentitySkip.requestHistory.isEmpty)
        XCTAssertTrue(credentialStore.isEmpty)
    }

    func testEmptyOrFailedAssociationTokenNeverAttaches() {
        let tokenResults: [Result<NetworkedIdentityAssociationTokenResponse, Error>] = [
            .success(.init(associationToken: "")),
            .failure(consumerError(code: "css_sensitive")),
        ]
        for result in tokenResults {
            let identityClient = enableDocumentAttachment()
            beginSelectedDocumentFlow()
            coordinator.continueWithSelectedDocument()
            waitForTransition(to: .completed) {
                apiClient.associationToken.respondToNext(with: result)
            }

            XCTAssertTrue(identityClient.attachNetworkedIdentityDocument.requestHistory.isEmpty)
            XCTAssertTrue(identityClient.networkedIdentitySkip.requestHistory.isEmpty)
            XCTAssertEqual(delegate.actionErrors, [.tokenUnavailable])
            XCTAssertTrue(credentialStore.isEmpty)
        }
    }

    func testAttachFailureIsSanitizedAndDoesNotReplayOrSkip() {
        let identityClient = enableDocumentAttachment()
        beginSelectedDocumentFlow()
        coordinator.continueWithSelectedDocument()
        respondWithAssociationToken(identityClient: identityClient)

        // When redemption fails with a potentially sensitive backend error
        waitForTransition(to: .completed) {
            identityClient.attachNetworkedIdentityDocument.respondToNext(
                with: .failure(consumerError(code: "css_sensitive_reuse_token"))
            )
        }
        coordinator.continueWithSelectedDocument()
        coordinator.chooseManualCapture()

        // Then no possibly consumed capability is replayed, and only a safe error reaches the host
        XCTAssertEqual(delegate.actionErrors, [.attachmentFailed])
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertEqual(identityClient.attachNetworkedIdentityDocument.requestHistory.count, 1)
        XCTAssertTrue(identityClient.networkedIdentitySkip.requestHistory.isEmpty)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 0)
        XCTAssertTrue(credentialStore.isEmpty)
    }

    func testAttachRejectsResponseForAnotherVerificationSession() {
        let identityClient = enableDocumentAttachment()
        beginSelectedDocumentFlow()
        coordinator.continueWithSelectedDocument()
        respondWithAssociationToken(identityClient: identityClient)
        waitForTransition(to: .completed) {
            identityClient.attachNetworkedIdentityDocument.respondToNext(
                with: .success(actionPageData(id: "vs_unrelated"))
            )
        }
        XCTAssertEqual(delegate.actionErrors, [.unexpectedSession])
        XCTAssertTrue(credentialStore.isEmpty)
    }

    func testAttachmentUnavailableFallsBackWithoutRetryingOrPersistingSkip() {
        let identityClient = enableDocumentAttachment()
        beginSelectedDocumentFlow()
        coordinator.continueWithSelectedDocument()
        respondWithAssociationToken(identityClient: identityClient)

        // When the backend explicitly says Networked Identity is unavailable
        waitForTransition(to: .fullCaptureFallback) {
            identityClient.attachNetworkedIdentityDocument.respondToNext(
                with: .failure(consumerError(code: "networked_identity_unavailable"))
            )
        }

        // Then normal capture resumes without replaying the token or saving an explicit skip
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 1)
        XCTAssertTrue(delegate.completions.isEmpty)
        XCTAssertTrue(identityClient.networkedIdentitySkip.requestHistory.isEmpty)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertEqual(identityClient.attachNetworkedIdentityDocument.requestHistory.count, 1)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 1)
    }

    func testCancelPendingTokenPreventsAttachment() {
        let identityClient = enableDocumentAttachment()
        beginSelectedDocumentFlow()
        coordinator.continueWithSelectedDocument()
        coordinator.cancel()
        processPendingResponse {
            apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "late_token")))
        }
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(identityClient.attachNetworkedIdentityDocument.requestHistory.isEmpty)
        XCTAssertTrue(identityClient.networkedIdentitySkip.requestHistory.isEmpty)
        XCTAssertTrue(delegate.completions.isEmpty)
        XCTAssertTrue(credentialStore.isEmpty)
    }

    func testCancelPendingAttachmentIgnoresCompletionWithoutUndoingIt() {
        let identityClient = enableDocumentAttachment()
        beginSelectedDocumentFlow()
        coordinator.continueWithSelectedDocument()
        respondWithAssociationToken(identityClient: identityClient)
        coordinator.cancel()
        processPendingResponse {
            identityClient.attachNetworkedIdentityDocument.respondToNext(with: .success(actionPageData()))
        }
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(delegate.completions.isEmpty)
        XCTAssertTrue(identityClient.networkedIdentitySkip.requestHistory.isEmpty)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 1)
    }

    func testExplicitManualCaptureSkipsOnceAndReturnsServerRequirements() throws {
        let identityClient = enableDocumentAttachment()
        beginExistingConsumerFlow()
        coordinator.chooseManualCapture()
        coordinator.chooseManualCapture()
        coordinator.continueWithSelectedDocument()
        XCTAssertEqual(coordinator.state, .skipPending)
        XCTAssertEqual(identityClient.networkedIdentitySkip.requestHistory.count, 1)
        let pageData = actionPageData()
        waitForTransition(to: .completed) {
            identityClient.networkedIdentitySkip.respondToNext(with: .success(pageData))
        }
        XCTAssertEqual(try delegate.completions.first?.get(), pageData)
        XCTAssertEqual(delegate.completions.count, 1)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 0)
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertEqual(apiClient.logOut.requestHistory.first?.consumerSessionClientSecret, "cs_started")
    }

    func testSkipFailureIsSanitizedAndNotRetriedOrReportedAsFallback() {
        let identityClient = enableDocumentAttachment()
        coordinator.chooseManualCapture()
        waitForTransition(to: .completed) {
            identityClient.networkedIdentitySkip.respondToNext(
                with: .failure(consumerError(code: "css_sensitive"))
            )
        }
        coordinator.chooseManualCapture()
        XCTAssertEqual(delegate.actionErrors, [.skipFailed])
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 0)
        XCTAssertEqual(identityClient.networkedIdentitySkip.requestHistory.count, 1)
        XCTAssertTrue(credentialStore.isEmpty)
    }

    func testCancelPendingSkipIgnoresLateServerResult() {
        let identityClient = enableDocumentAttachment()
        coordinator.chooseManualCapture()
        coordinator.cancel()
        processPendingResponse {
            identityClient.networkedIdentitySkip.respondToNext(with: .success(actionPageData()))
        }
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(delegate.completions.isEmpty)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 0)
        XCTAssertEqual(identityClient.networkedIdentitySkip.requestHistory.count, 1)
    }

    func testAutomaticNoAccountFallbackDoesNotPersistAnExplicitSkip() {
        let identityClient = enableDocumentAttachment()
        coordinator.start(emailAddress: "new@example.com")
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.lookup.respondToNext(with: .success(.notFound(.init(errorMessage: "No account found"))))
        }
        XCTAssertEqual(coordinator.fallbackReason, .noLinkAccount)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 1)
        XCTAssertTrue(identityClient.networkedIdentitySkip.requestHistory.isEmpty)
        XCTAssertTrue(delegate.completions.isEmpty)
    }

    func testSkipPendingLogsOutLateRotatedCredentialsBeforeSkipResolves() {
        let identityClient = enableDocumentAttachment()
        beginExistingConsumerLookup()
        coordinator.chooseManualCapture()
        XCTAssertEqual(coordinator.state, .skipPending)
        let lateCredentialsLoggedOut = expectation(description: "Late credentials cleaned up while skip is pending")
        apiClient.logOut.callBackOnRequest {
            lateCredentialsLoggedOut.fulfill()
        }

        // When the pending SMS request returns fresh credentials before skip completes
        apiClient.startVerification.respondToNext(
            with: .success(
                consumerSessionResponse(
                    clientSecret: "cs_late_start",
                    authSessionClientSecret: "auth_late_start"
                )
            )
        )
        wait(for: [lateCredentialsLoggedOut], timeout: 1)

        // Then they are not left alive while waiting on the separate Identity request
        XCTAssertEqual(coordinator.state, .skipPending)
        XCTAssertEqual(apiClient.logOut.requestHistory.first?.consumerSessionClientSecret, "cs_late_start")
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_late_start"]
        )
        XCTAssertTrue(delegate.completions.isEmpty)
        XCTAssertEqual(identityClient.networkedIdentitySkip.pendingRequestCount, 1)
    }

    func testCanChangeSelectedDocumentBeforeReuse() {
        // Given the consumer has two reusable documents
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_confirmed",
                        verificationState: .verified
                    )
                )
            )
        }
        let firstDocument = identityDocument(id: "id_doc_first")
        let secondDocument = identityDocument(id: "id_doc_second", documentType: .passport)
        waitForTransition(to: .selectDocument) {
            apiClient.documentList.respondToNext(
                with: .success(.init(data: [firstDocument, secondDocument]))
            )
        }

        // When the consumer changes their selection before reuse
        coordinator.selectDocument(firstDocument)
        coordinator.selectDocument(secondDocument)

        // Then the latest reusable document is retained without making a reuse request
        XCTAssertEqual(coordinator.state, .selectedDocument)
        XCTAssertEqual(coordinator.selectedDocument, secondDocument)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 0)
    }

    func testNotFoundConsumerFallsBackBeforeCreatingLinkAccount() {
        // Given lookup does not find a Link consumer
        coordinator.start(emailAddress: "new@example.com")
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.lookup.respondToNext(
                with: .success(.notFound(.init(errorMessage: "not found")))
            )
        }

        // Then the selected co-branded journey uses manual verification before Save ID
        XCTAssertEqual(coordinator.fallbackReason, .noLinkAccount)
        XCTAssertEqual(apiClient.signUp.requestHistory.count, 0)
        XCTAssertTrue(credentialStore.isEmpty)
    }

    func testInvalidOTPReturnsToEntryAndAllowsRetry() {
        // Given the coordinator is awaiting a fresh SMS code
        beginExistingConsumerFlow()

        // When confirmation reports an invalid code
        coordinator.submitOTP("111111")
        waitForTransition(to: .awaitingOTP) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_verification_code_invalid"))
            )
        }

        // Then the inline error is exposed and another submission is allowed
        XCTAssertEqual(coordinator.lastOTPError, .invalidCode)
        coordinator.submitOTP("222222")
        XCTAssertEqual(coordinator.state, .otpConfirmPending)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 2)
    }

    func testRetainsDisplayMetadataUntilFlowIsCleared() {
        // Given an existing consumer is waiting for SMS verification
        beginExistingConsumerFlow()

        // Then UI-safe account details are available to the presentation layer
        XCTAssertEqual(coordinator.emailAddress, "consumer@example.com")
        XCTAssertEqual(
            coordinator.redactedFormattedPhoneNumber,
            "+1 *** *** 0123"
        )

        // When the flow is cancelled
        coordinator.cancel()

        // Then account details are cleared with the credentials
        XCTAssertNil(coordinator.emailAddress)
        XCTAssertNil(coordinator.redactedFormattedPhoneNumber)
    }

    func testResendRequestsOneReplacementAndConfirmsTheNewSession() {
        // Given the user entered an invalid code for the first fresh SMS session
        beginExistingConsumerFlow()
        XCTAssertEqual(apiClient.startVerification.requestHistory.first?.request.isResendingSMSCode, false)
        coordinator.submitOTP("111111")
        waitForTransition(to: .awaitingOTP) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_verification_code_invalid"))
            )
        }

        // When resend is tapped twice and confirmation is attempted while it is pending
        coordinator.resendOTP()
        coordinator.resendOTP()
        coordinator.submitOTP("222222")

        // Then only one replacement request is sent using the current credentials
        XCTAssertEqual(coordinator.state, .otpStartPending)
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 2)
        XCTAssertEqual(apiClient.startVerification.pendingRequestCount, 1)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 1)
        XCTAssertEqual(apiClient.startVerification.requestHistory.last?.request.isResendingSMSCode, true)
        XCTAssertEqual(apiClient.startVerification.requestHistory.last?.request.consumerSessionClientSecret, "cs_started")

        // When the replacement SMS session is returned and then verified
        waitForTransition(to: .awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_resent",
                        verificationSessions: [
                            verificationSession(id: "cvs_fresh", state: .started),
                            verificationSession(id: "cvs_resent", state: .started),
                        ]
                    )
                )
            )
        }
        XCTAssertNil(coordinator.lastOTPError)
        coordinator.submitOTP("333333")
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.last?.request.consumerSessionClientSecret, "cs_resent")
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_resent_confirmed",
                        verificationSessionID: "cvs_resent",
                        verificationState: .verified
                    )
                )
            )
        }

        // Then only the verified replacement session unlocks document listing
        XCTAssertEqual(apiClient.documentList.requestHistory.count, 1)
        XCTAssertEqual(apiClient.documentList.requestHistory.first?.consumerSessionClientSecret, "cs_resent_confirmed")
    }

    func testResendRejectsConfirmationOfThePreviousSession() {
        // Given resend replaced the original SMS verification session
        beginExistingConsumerFlow()
        coordinator.resendOTP()
        waitForTransition(to: .awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_resent",
                        verificationSessionID: "cvs_resent"
                    )
                )
            )
        }

        // When only the old SMS session is verified
        coordinator.submitOTP("111111")
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_old_confirmed",
                        verificationSessions: [
                            verificationSession(id: "cvs_fresh", state: .verified),
                            verificationSession(id: "cvs_resent", state: .started),
                        ]
                    )
                )
            )
        }

        // Then the superseded code cannot authenticate document reuse
        XCTAssertEqual(apiClient.documentList.requestHistory.count, 0)
        XCTAssertTrue(credentialStore.isEmpty)
    }

    func testResendCanRetainTheActiveSMSID() {
        // Given the current SMS session was freshly started by this flow
        beginExistingConsumerFlow()
        coordinator.resendOTP()

        // When resend retains that active session in its started state
        waitForTransition(to: .awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(consumerSessionResponse(clientSecret: "cs_resent_same_id"))
            )
        }
        XCTAssertEqual(apiClient.documentList.requestHistory.count, 0)

        // Then confirmation must still verify the active session before documents can load
        coordinator.submitOTP("123456")
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_same_id_confirmed",
                        verificationState: .verified
                    )
                )
            )
        }
        XCTAssertEqual(apiClient.documentList.requestHistory.count, 1)
    }

    func testResendCannotAdoptAnUnrelatedHistoricalSMSID() {
        // Given this flow already has a fresh active SMS session
        beginExistingConsumerFlow()
        coordinator.resendOTP()

        // When resend returns only the unrelated session originally seen at lookup
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_historical_resend",
                        verificationSessionID: "cvs_old"
                    )
                )
            )
        }

        // Then accepting the same active ID never permits an unrelated historical ID
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 0)
        XCTAssertTrue(credentialStore.isEmpty)
    }

    func testResendSessionExpiryRequiresReauthentication() {
        // Given the user requests another SMS code
        beginExistingConsumerFlow()
        coordinator.resendOTP()

        // When the consumer session has expired
        waitForTransition(to: .reauthenticationRequired) {
            apiClient.startVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_session_expired"))
            )
        }

        // Then the user must sign in again without an automatic lookup loop
        XCTAssertEqual(coordinator.lastOTPError, .sessionExpired)
        XCTAssertFalse(credentialStore.hasConsumerCredentials)
        XCTAssertEqual(apiClient.lookup.requestHistory.count, 1)
    }

    func testResendFailureFallsBackAndClearsCredentials() {
        // Given the user requests another SMS code
        beginExistingConsumerFlow()
        coordinator.resendOTP()

        // When the replacement code cannot be sent
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.startVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_verification_max_attempts_exceeded"))
            )
        }

        // Then manual capture remains available and the Link credentials are cleared
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 1)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 1)
    }

    func testCancellationLogsOutSecretReturnedByPendingResend() {
        // Given resend is in flight when the user cancels
        beginExistingConsumerFlow()
        coordinator.resendOTP()
        let rotatedSecretLoggedOut = expectation(description: "Late resend credentials are logged out")
        apiClient.logOut.callBackOnRequest {
            if self.apiClient.logOut.requestHistory.count == 2 {
                rotatedSecretLoggedOut.fulfill()
            }
        }

        // When resend returns new credentials after cancellation
        coordinator.cancel()
        coordinator.resendOTP()
        apiClient.startVerification.respondToNext(
            with: .success(
                consumerSessionResponse(
                    clientSecret: "cs_resent_after_cancel",
                    verificationSessionID: "cvs_resent",
                    authSessionClientSecret: "auth_resent_after_cancel"
                )
            )
        )
        wait(for: [rotatedSecretLoggedOut], timeout: 1)

        // Then the late response cannot reopen the flow and both credential sets are logged out
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 2)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 2)
        XCTAssertEqual(apiClient.logOut.requestHistory.last?.consumerSessionClientSecret, "cs_resent_after_cancel")
        XCTAssertEqual(
            apiClient.logOut.requestHistory.last?.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_resent_after_cancel"]
        )
    }

    func testRetainsAuthSessionClientSecretsAcrossRequestsAndLogout() {
        // Given lookup returns a new auth-session secret
        coordinator.start(emailAddress: "consumer@example.com")
        waitForTransition(to: .otpStartPending) {
            apiClient.lookup.respondToNext(
                with: .success(
                    .found(
                        .init(
                            consumerSession: consumerSession(
                                clientSecret: "cs_lookup",
                                verificationSessionID: "cvs_old",
                                verificationState: .verified
                            ),
                            publishableKey: "pk_consumer_lookup",
                            accountID: "acct_123",
                            authSessionClientSecret: "auth_lookup",
                            emailOTPRequiresAdditionalInfo: nil,
                            emailOTPVerifyPhoneDespiteSMSOTP: nil,
                            experiments: []
                        )
                    )
                )
            )
        }
        XCTAssertEqual(
            apiClient.startVerification.requestHistory.first?.request.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_lookup"]
        )

        // When start and confirm each return another auth-session secret
        waitForTransition(to: .awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_started",
                        verificationSessionID: "cvs_fresh",
                        authSessionClientSecret: "auth_start"
                    )
                )
            )
        }
        coordinator.submitOTP("123456")
        XCTAssertEqual(
            apiClient.confirmVerification.requestHistory.first?.request.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_lookup", "auth_start"]
        )
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_confirmed",
                        verificationState: .verified,
                        authSessionClientSecret: "auth_confirm"
                    )
                )
            )
        }

        // Then logout receives every secret retained during this flow
        coordinator.cancel()
        XCTAssertEqual(
            apiClient.logOut.requestHistory.last?.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_lookup", "auth_start", "auth_confirm"]
        )
    }

    func testAuthSessionClientSecretRetentionIgnoresEmptyAndDuplicateValues() {
        credentialStore.retainAuthSessionClientSecret(nil)
        credentialStore.retainAuthSessionClientSecret("")
        credentialStore.retainAuthSessionClientSecret("vs_client_secret")
        credentialStore.retainAuthSessionClientSecret("auth_new")
        credentialStore.retainAuthSessionClientSecret("auth_new")

        XCTAssertEqual(
            credentialStore.readVerificationSessionClientSecrets { $0 },
            ["vs_client_secret", "auth_new"]
        )
    }

    func testExpiredOTPRequestsFreshSessionAndRejectsOldVerification() {
        // Given the coordinator is awaiting a fresh SMS code
        beginExistingConsumerFlow()

        // When confirmation reports that code expired
        coordinator.submitOTP("111111")
        waitForTransition(to: .otpStartPending) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_verification_expired"))
            )
        }

        // Then it requests a new SMS verification without accepting duplicate actions
        XCTAssertEqual(coordinator.lastOTPError, .verificationExpired)
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 2)
        waitForTransition(to: .awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_refreshed_otp",
                        verificationSessionID: "cvs_refreshed"
                    )
                )
            )
        }
        XCTAssertNil(coordinator.lastOTPError)

        // When an old session is verified but the replacement session is not
        coordinator.submitOTP("222222")
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_confirmed_old_session",
                        verificationSessions: [
                            verificationSession(id: "cvs_fresh", state: .verified),
                            verificationSession(id: "cvs_refreshed", state: .started),
                        ]
                    )
                )
            )
        }

        // Then the old verification cannot authenticate the replacement OTP request
        XCTAssertEqual(apiClient.documentList.requestHistory.count, 0)
    }

    func testSessionExpiredRequiresExplicitReauthentication() {
        // Given the coordinator is awaiting a fresh SMS code
        beginExistingConsumerFlow()
        credentialStore.retainAuthSessionClientSecret("auth_before_reauthentication")

        // When confirmation reports that the consumer session expired
        coordinator.submitOTP("111111")
        waitForTransition(to: .reauthenticationRequired) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_session_expired"))
            )
        }

        // Then credentials are cleared and lookup does not loop automatically
        XCTAssertEqual(coordinator.lastOTPError, .sessionExpired)
        XCTAssertFalse(credentialStore.hasConsumerCredentials)
        XCTAssertEqual(apiClient.lookup.requestHistory.count, 1)

        coordinator.start(emailAddress: "consumer@example.com")
        XCTAssertEqual(coordinator.state, .lookupPending)
        XCTAssertEqual(apiClient.lookup.requestHistory.count, 2)
        XCTAssertEqual(
            apiClient.lookup.requestHistory.last?.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_before_reauthentication"]
        )
    }

    func testSessionExpiredWhileStartingVerificationRequiresReauthentication() {
        // Given lookup found an existing consumer and SMS verification is starting
        beginExistingConsumerLookup()

        // When starting verification reports that the consumer session expired
        waitForTransition(to: .reauthenticationRequired) {
            apiClient.startVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_session_expired"))
            )
        }

        // Then credentials are cleared and the user must explicitly sign in again
        XCTAssertEqual(coordinator.lastOTPError, .sessionExpired)
        XCTAssertFalse(credentialStore.hasConsumerCredentials)
        XCTAssertEqual(apiClient.lookup.requestHistory.count, 1)
    }

    func testMaximumOTPAttemptsFallsBackToFullCapture() {
        // Given the coordinator is awaiting a fresh SMS code
        beginExistingConsumerFlow()

        // When the maximum-attempt error is returned
        coordinator.submitOTP("111111")
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(
                    consumerError(code: "consumer_verification_max_attempts_exceeded")
                )
            )
        }

        // Then local credentials are cleared and manual capture is requested
        XCTAssertEqual(coordinator.lastOTPError, .maxAttemptsExceeded)
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 1)
    }

    func testEmptyDocumentListFallsBackToFullCapture() {
        // Given a freshly authenticated consumer
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_confirmed",
                        verificationState: .verified
                    )
                )
            )
        }

        // When no reusable documents are returned
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.documentList.respondToNext(with: .success(.init(data: [])))
        }

        // Then Networked Identity fails safely into manual capture
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertEqual(coordinator.fallbackReason, .noReusableDocuments)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 1)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_confirmed"
        )
    }

    func testUnverifiedOTPResponseFallsBackWithoutListingDocuments() {
        // Given the coordinator is awaiting a fresh SMS code
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")

        // When the success response does not contain a verified SMS session
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.confirmVerification.respondToNext(
                with: .success(consumerSessionResponse(clientSecret: "cs_unverified"))
            )
        }

        // Then document metadata is not requested without verified authentication
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertEqual(apiClient.documentList.requestHistory.count, 0)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_unverified"
        )
    }

    func testHistoricalVerifiedSMSSessionDoesNotAuthenticateFreshSession() {
        // Given the coordinator is awaiting the fresh SMS session returned by start verification
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")

        // When confirmation returns an old verified SMS session but not the fresh one
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_historical_verification",
                        verificationSessions: [
                            verificationSession(id: "cvs_old", state: .verified),
                            verificationSession(id: "cvs_fresh", state: .started),
                        ]
                    )
                )
            )
        }

        // Then document metadata is not requested without proof of fresh authentication
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertEqual(apiClient.documentList.requestHistory.count, 0)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_historical_verification"
        )
    }

    func testStartVerificationWithoutSessionIDFallsBack() {
        // Given lookup found an existing consumer
        beginExistingConsumerLookup()

        // When start verification does not identify the fresh SMS session
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_missing_session_id",
                        verificationSessionID: nil
                    )
                )
            )
        }

        // Then the coordinator fails closed instead of accepting an older verification
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 0)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_missing_session_id"
        )
    }

    func testStartVerificationDoesNotReuseHistoricalStartedSession() {
        // Given lookup already returned a started SMS verification session
        beginExistingConsumerLookup(verificationState: .started)

        // When start verification echoes that same session instead of creating a fresh one
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_reused_session",
                        verificationSessionID: "cvs_old"
                    )
                )
            )
        }

        // Then the historical session cannot be treated as fresh authentication
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 0)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_reused_session"
        )
    }

    func testStartVerificationWithAmbiguousSMSSessionsFallsBack() {
        // Given lookup found an existing consumer
        beginExistingConsumerLookup()

        // When start verification returns more than one possible fresh SMS session
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_ambiguous_sessions",
                        verificationSessions: [
                            verificationSession(id: "cvs_first", state: .started),
                            verificationSession(id: "cvs_second", state: .started),
                        ]
                    )
                )
            )
        }

        // Then the coordinator cannot bind confirmation to the wrong session
        XCTAssertEqual(coordinator.fallbackReason, .unavailable)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 0)
    }

    func testUnsupportedAndExpiredDocumentsFallBack() {
        // Given a freshly authenticated consumer
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_confirmed",
                        verificationState: .verified
                    )
                )
            )
        }

        // When every returned document is either unknown or expired
        waitForTransition(to: .fullCaptureFallback) {
            apiClient.documentList.respondToNext(
                with: .success(
                    .init(data: [
                        identityDocument(
                            id: "id_doc_unknown",
                            documentType: .unparsable
                        ),
                        identityDocument(
                            id: "id_doc_expired",
                            expirationDate: 1_700_000_000
                        ),
                    ])
                )
            )
        }

        // Then unusable metadata never reaches document selection
        XCTAssertEqual(coordinator.fallbackReason, .noReusableDocuments)
        XCTAssertTrue(coordinator.availableDocuments.isEmpty)
    }

    func testFiltersDocumentsUsingVerificationSessionRequirements() {
        // Given this VerificationSession only accepts live-captured passports
        coordinator = NetworkedIdentityCoordinator(
            apiClient: apiClient,
            documentRequirements: .init(
                allowedDocumentTypes: [.passport],
                requiresLiveCapture: true
            ),
            credentialStore: credentialStore,
            currentTime: { 1_800_000_000 }
        )
        coordinator.delegate = delegate
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_confirmed",
                        verificationState: .verified
                    )
                )
            )
        }
        let reusablePassport = identityDocument(
            id: "id_doc_reusable",
            documentType: .passport,
            liveCaptured: true
        )

        // When Link returns documents that do and do not meet those requirements
        waitForTransition(to: .selectDocument) {
            apiClient.documentList.respondToNext(
                with: .success(
                    .init(data: [
                        identityDocument(
                            id: "id_doc_wrong_type",
                            documentType: .drivingLicense,
                            liveCaptured: true
                        ),
                        identityDocument(
                            id: "id_doc_not_live",
                            documentType: .passport,
                            liveCaptured: false
                        ),
                        identityDocument(
                            id: "id_doc_expired",
                            documentType: .passport,
                            expirationDate: 1_700_000_000,
                            liveCaptured: true
                        ),
                        reusablePassport,
                    ]))
            )
        }

        // Then only the matching reusable document reaches selection
        XCTAssertEqual(coordinator.availableDocuments, [reusablePassport])
    }

    func testDuplicateOTPSubmissionWhilePendingIsIgnored() {
        // Given resend is unavailable until the coordinator is awaiting a fresh SMS code
        coordinator.resendOTP()
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 0)
        beginExistingConsumerFlow()

        // When submit and resend are tapped before the first confirmation completes
        coordinator.submitOTP("123456")
        coordinator.submitOTP("123456")
        coordinator.resendOTP()

        // Then only one confirmation request is in flight
        XCTAssertEqual(coordinator.state, .otpConfirmPending)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 1)
        XCTAssertEqual(apiClient.confirmVerification.pendingRequestCount, 1)
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 1)
    }

    func testUserCanChooseManualCapture() {
        // Given the consumer is waiting for SMS verification
        beginExistingConsumerFlow()

        // When they choose the manual verification path more than once
        coordinator.chooseManualCapture()
        coordinator.chooseManualCapture()

        // Then the Link session is cleared and manual capture is requested once
        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(coordinator.fallbackReason, .userSelectedManualCapture)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 1)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 1)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_started"
        )
    }

    func testAbandonmentSilentlyCleansUpAuthenticatedSession() {
        // Given the flow is waiting for an OTP with an authenticated consumer session
        beginExistingConsumerFlow()
        delegate.onTransition = { state in
            XCTFail("Abandonment unexpectedly emitted the \(state) transition")
        }

        // When the flow owner disappears without using a completion action
        coordinator.abandon()

        // Then Link is logged out and credentials are cleared without notifying the host
        XCTAssertEqual(
            apiClient.logOut.requestHistory,
            [
                .init(
                    consumerSessionClientSecret: "cs_started",
                    verificationSessionClientSecrets: ["vs_client_secret"],
                    consumerPublishableKey: "pk_consumer_lookup"
                ),
            ]
        )
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 0)
        delegate.onTransition = nil
    }

    func testManualCaptureLogsOutSecretReturnedByPendingLookup() {
        // Given lookup is in flight when the consumer chooses manual verification
        coordinator.start(emailAddress: "consumer@example.com")
        let returnedSecretLoggedOut = expectation(
            description: "Consumer session returned after manual fallback is logged out"
        )
        apiClient.logOut.callBackOnRequest {
            returnedSecretLoggedOut.fulfill()
        }

        // When the stale lookup later returns a consumer session
        coordinator.chooseManualCapture()
        apiClient.lookup.respondToNext(
            with: .success(
                .found(
                    .init(
                        consumerSession: consumerSession(
                            clientSecret: "cs_lookup_after_manual_fallback"
                        ),
                        publishableKey: "pk_consumer_lookup",
                        accountID: "acct_123",
                        authSessionClientSecret: "auth_lookup_after_manual_fallback",
                        emailOTPRequiresAdditionalInfo: nil,
                        emailOTPVerifyPhoneDespiteSMSOTP: nil,
                        experiments: []
                    )
                )
            )
        )
        wait(for: [returnedSecretLoggedOut], timeout: 1)

        // Then the stale result cannot restart Link authentication and its secret is logged out
        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(coordinator.fallbackReason, .userSelectedManualCapture)
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 0)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_lookup_after_manual_fallback"
        )
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_lookup_after_manual_fallback"]
        )
    }

    func testPendingLookupCleanupSurvivesCoordinatorRelease() {
        // Given lookup is in flight when the host starts manual capture
        coordinator.start(emailAddress: "consumer@example.com")
        coordinator.chooseManualCapture()
        weak var retainedForCleanup = coordinator
        coordinator = nil
        XCTAssertNil(retainedForCleanup)
        let returnedSecretLoggedOut = expectation(
            description: "Pending lookup cleanup survives coordinator release"
        )
        apiClient.logOut.callBackOnRequest {
            returnedSecretLoggedOut.fulfill()
        }

        // When lookup returns a consumer secret after presentation has been released
        apiClient.lookup.respondToNext(
            with: .success(
                .found(
                    .init(
                        consumerSession: consumerSession(
                            clientSecret: "cs_lookup_after_release"
                        ),
                        publishableKey: "pk_consumer_lookup",
                        accountID: "acct_123",
                        authSessionClientSecret: "auth_lookup_after_release",
                        emailOTPRequiresAdditionalInfo: nil,
                        emailOTPVerifyPhoneDespiteSMSOTP: nil,
                        experiments: []
                    )
                )
            )
        )
        wait(for: [returnedSecretLoggedOut], timeout: 1)

        // Then the late secret is still logged out
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_lookup_after_release"
        )
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_lookup_after_release"]
        )
    }

    func testPendingStartVerificationCleanupSurvivesCoordinatorRelease() {
        // Given start verification is in flight when the host starts manual capture
        beginExistingConsumerLookup()
        coordinator.chooseManualCapture()
        weak var retainedForCleanup = coordinator
        coordinator = nil
        XCTAssertNil(retainedForCleanup)
        let returnedSecretLoggedOut = expectation(
            description: "Pending start-verification cleanup survives coordinator release"
        )
        apiClient.logOut.callBackOnRequest {
            if self.apiClient.logOut.requestHistory.count == 2 {
                returnedSecretLoggedOut.fulfill()
            }
        }

        // When start verification rotates the secret after presentation has been released
        apiClient.startVerification.respondToNext(
            with: .success(
                consumerSessionResponse(
                    clientSecret: "cs_start_after_release",
                    verificationSessionID: "cvs_fresh",
                    authSessionClientSecret: "auth_start_after_release"
                )
            )
        )
        wait(for: [returnedSecretLoggedOut], timeout: 1)

        // Then both the current and late secrets are logged out
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 2)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.last?.consumerSessionClientSecret,
            "cs_start_after_release"
        )
        XCTAssertEqual(
            apiClient.logOut.requestHistory.last?.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_start_after_release"]
        )
    }

    func testPendingConfirmationCleanupSurvivesCoordinatorRelease() {
        // Given OTP confirmation is in flight when the host starts manual capture
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")
        coordinator.chooseManualCapture()
        weak var retainedForCleanup = coordinator
        coordinator = nil
        XCTAssertNil(retainedForCleanup)
        let returnedSecretLoggedOut = expectation(
            description: "Pending confirmation cleanup survives coordinator release"
        )
        apiClient.logOut.callBackOnRequest {
            if self.apiClient.logOut.requestHistory.count == 2 {
                returnedSecretLoggedOut.fulfill()
            }
        }

        // When confirmation rotates the secret after presentation has been released
        apiClient.confirmVerification.respondToNext(
            with: .success(
                consumerSessionResponse(
                    clientSecret: "cs_confirm_after_release",
                    verificationState: .verified,
                    authSessionClientSecret: "auth_confirm_after_release"
                )
            )
        )
        wait(for: [returnedSecretLoggedOut], timeout: 1)

        // Then both the current and late secrets are logged out
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 2)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.last?.consumerSessionClientSecret,
            "cs_confirm_after_release"
        )
        XCTAssertEqual(
            apiClient.logOut.requestHistory.last?.verificationSessionClientSecrets,
            ["vs_client_secret", "auth_confirm_after_release"]
        )
    }

    func testCancellationLogsOutWhenPossibleAndAlwaysClearsCredentials() {
        // Given the coordinator holds authenticated consumer credentials
        beginExistingConsumerFlow()
        coordinator.submitOTP("111111")
        waitForTransition(to: .awaitingOTP) {
            apiClient.confirmVerification.respondToNext(
                with: .failure(consumerError(code: "consumer_verification_code_invalid"))
            )
        }
        XCTAssertTrue(credentialStore.hasConsumerCredentials)
        XCTAssertEqual(coordinator.lastOTPError, .invalidCode)

        // When the flow is cancelled twice
        coordinator.cancel()
        coordinator.cancel()

        // Then logout is attempted once and local state is cleared immediately
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(credentialStore.isEmpty)
        XCTAssertNil(coordinator.lastOTPError)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 1)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first,
            .init(
                consumerSessionClientSecret: "cs_started",
                verificationSessionClientSecrets: ["vs_client_secret"],
                consumerPublishableKey: "pk_consumer_lookup"
            )
        )
        XCTAssertTrue(coordinator.availableDocuments.isEmpty)
        XCTAssertNil(coordinator.selectedDocument)
    }

    func testCancellationLogsOutSecretReturnedByPendingConfirmation() {
        // Given OTP confirmation is in flight when the user cancels
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")
        let rotatedSecretLoggedOut = expectation(
            description: "Rotated consumer session secret is logged out"
        )
        apiClient.logOut.callBackOnRequest {
            if self.apiClient.logOut.requestHistory.count == 2 {
                rotatedSecretLoggedOut.fulfill()
            }
        }

        // When cancellation logs out the current secret and confirmation returns a new one
        coordinator.cancel()
        apiClient.confirmVerification.respondToNext(
            with: .success(
                consumerSessionResponse(
                    clientSecret: "cs_rotated_after_cancel",
                    verificationState: .verified
                )
            )
        )
        wait(for: [rotatedSecretLoggedOut], timeout: 1)

        // Then the stale response cannot reactivate the flow and its secret is also logged out
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 2)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.last?.consumerSessionClientSecret,
            "cs_rotated_after_cancel"
        )
    }

    func testCancellationLogsOutSecretReturnedByPendingLookup() {
        // Given consumer lookup is in flight when the user cancels
        coordinator.start(emailAddress: "consumer@example.com")
        let returnedSecretLoggedOut = expectation(
            description: "Consumer session returned by lookup is logged out"
        )
        apiClient.logOut.callBackOnRequest {
            returnedSecretLoggedOut.fulfill()
        }

        // When cancellation occurs before lookup returns a consumer session
        coordinator.cancel()
        apiClient.lookup.respondToNext(
            with: .success(
                .found(
                    .init(
                        consumerSession: consumerSession(
                            clientSecret: "cs_lookup_after_cancel",
                            verificationSessionID: "cvs_old",
                            verificationState: .verified
                        ),
                        publishableKey: "pk_consumer_lookup",
                        accountID: "acct_123",
                        authSessionClientSecret: nil,
                        emailOTPRequiresAdditionalInfo: nil,
                        emailOTPVerifyPhoneDespiteSMSOTP: nil,
                        experiments: []
                    )
                )
            )
        )
        wait(for: [returnedSecretLoggedOut], timeout: 1)

        // Then the stale response cannot reactivate the flow and its secret is logged out
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(apiClient.startVerification.requestHistory.count, 0)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 1)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.first?.consumerSessionClientSecret,
            "cs_lookup_after_cancel"
        )
    }

    func testCancellationLogsOutSecretReturnedByPendingStartVerification() {
        // Given start verification is in flight when the user cancels
        beginExistingConsumerLookup()
        let rotatedSecretLoggedOut = expectation(
            description: "Consumer session returned by start verification is logged out"
        )
        apiClient.logOut.callBackOnRequest {
            if self.apiClient.logOut.requestHistory.count == 2 {
                rotatedSecretLoggedOut.fulfill()
            }
        }

        // When cancellation logs out the current secret and start verification returns a new one
        coordinator.cancel()
        apiClient.startVerification.respondToNext(
            with: .success(
                consumerSessionResponse(
                    clientSecret: "cs_started_after_cancel",
                    verificationSessionID: "cvs_fresh"
                )
            )
        )
        wait(for: [rotatedSecretLoggedOut], timeout: 1)

        // Then the stale response cannot reactivate the flow and its secret is also logged out
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(apiClient.logOut.requestHistory.count, 2)
        XCTAssertEqual(
            apiClient.logOut.requestHistory.last?.consumerSessionClientSecret,
            "cs_started_after_cancel"
        )
    }

    func testReentrantCancellationSuppressesFullCaptureRequest() {
        // Given the presentation delegate cancels as soon as fallback begins
        let cancelled = expectation(description: "Networked Identity is cancelled")
        delegate.onTransition = { [unowned self] state in
            switch state {
            case .fullCaptureFallback:
                coordinator.cancel()
            case .cancelled:
                cancelled.fulfill()
            default:
                break
            }
        }

        // When lookup fails and enters the fallback transition
        coordinator.start(emailAddress: "consumer@example.com")
        apiClient.lookup.respondToNext(with: .failure(TestError.lookupFailed))
        wait(for: [cancelled], timeout: 1)

        // Then dismissal wins and manual capture is not requested afterward
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(delegate.fullCaptureFallbackCount, 0)
    }
}

private extension NetworkedIdentityCoordinatorTest {
    func enableDocumentAttachment() -> IdentityAPIClientTestMock {
        let identityClient = IdentityAPIClientTestMock(verificationSessionId: "vs_target")
        identityClient.supportsNetworkedIdentity = true
        setUpCoordinator(identityAPIClient: identityClient)
        return identityClient
    }

    func beginSelectedDocumentFlow() {
        beginExistingConsumerFlow()
        coordinator.submitOTP("123456")
        waitForTransition(to: .documentsPending) {
            apiClient.confirmVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(clientSecret: "cs_confirmed", verificationState: .verified)
                )
            )
        }
        let document = identityDocument(id: "id_doc_selected")
        waitForTransition(to: .selectDocument) {
            apiClient.documentList.respondToNext(with: .success(.init(data: [document])))
        }
        coordinator.selectDocument(document)
    }

    func respondWithAssociationToken(identityClient: IdentityAPIClientTestMock) {
        let attachmentRequested = expectation(description: "Token is exchanged for document attachment")
        identityClient.attachNetworkedIdentityDocument.callBackOnRequest {
            attachmentRequested.fulfill()
        }
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "reuse_token")))
        wait(for: [attachmentRequested], timeout: 1)
    }

    func actionPageData(id: String = "vs_target") -> StripeAPI.VerificationPageData {
        .init(
            id: id,
            requirements: .init(errors: [], missing: [.face]),
            status: .requiresInput,
            submitted: false,
            closed: false
        )
    }

    func processPendingResponse(_ action: () -> Void) {
        let unexpectedTransition = expectation(description: "Cancelled flow ignores the queued response")
        unexpectedTransition.isInverted = true
        delegate.onTransition = { _ in
            unexpectedTransition.fulfill()
        }
        action()
        // Futures first dispatch through their private queue before reaching the main queue.
        wait(for: [unexpectedTransition], timeout: 0.1)
        delegate.onTransition = nil
    }

    func beginExistingConsumerFlow() {
        beginExistingConsumerLookup()

        waitForTransition(to: .awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(
                    consumerSessionResponse(
                        clientSecret: "cs_started",
                        verificationSessionID: "cvs_fresh"
                    )
                )
            )
        }
    }

    func beginExistingConsumerLookup(
        verificationState: NetworkedIdentityVerificationSessionState = .verified
    ) {
        coordinator.start(emailAddress: "consumer@example.com")
        XCTAssertEqual(coordinator.state, .lookupPending)
        XCTAssertEqual(
            apiClient.lookup.requestHistory.first,
            .init(
                emailAddress: "consumer@example.com",
                verificationSessionClientSecrets: ["vs_client_secret"]
            )
        )

        waitForTransition(to: .otpStartPending) {
            apiClient.lookup.respondToNext(
                with: .success(
                    .found(
                        .init(
                            consumerSession: consumerSession(
                                clientSecret: "cs_lookup",
                                verificationSessionID: "cvs_old",
                                verificationState: verificationState
                            ),
                            publishableKey: "pk_consumer_lookup",
                            accountID: "acct_123",
                            authSessionClientSecret: nil,
                            emailOTPRequiresAdditionalInfo: nil,
                            emailOTPVerifyPhoneDespiteSMSOTP: nil,
                            experiments: []
                        )
                    )
                )
            )
        }
        XCTAssertEqual(
            apiClient.startVerification.requestHistory.first,
            .init(
                request: .init(
                    consumerSessionClientSecret: "cs_lookup",
                    type: .sms,
                    locale: Locale.current.toLanguageTag(),
                    accountPhoneNumber: nil,
                    verificationSessionClientSecrets: ["vs_client_secret"]
                ),
                consumerPublishableKey: "pk_consumer_lookup"
            )
        )
    }

    func waitForTransition(
        to expectedState: NetworkedIdentityState,
        action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(
            description: "Networked Identity transitions to \(expectedState)"
        )
        delegate.onTransition = { state in
            guard state == expectedState else {
                return
            }
            expectation.fulfill()
        }

        action()
        wait(for: [expectation], timeout: 1)
        delegate.onTransition = nil
        XCTAssertEqual(coordinator.state, expectedState, file: file, line: line)
    }

    func consumerSession(
        clientSecret: String,
        verificationSessionID: String? = "cvs_fresh",
        verificationState: NetworkedIdentityVerificationSessionState = .started
    ) -> NetworkedIdentityConsumerSession {
        consumerSession(
            clientSecret: clientSecret,
            verificationSessions: [
                verificationSession(
                    id: verificationSessionID,
                    state: verificationState
                ),
            ]
        )
    }

    func consumerSession(
        clientSecret: String,
        verificationSessions: [NetworkedIdentityVerificationSession]
    ) -> NetworkedIdentityConsumerSession {
        .init(
            clientSecret: clientSecret,
            emailAddress: "consumer@example.com",
            redactedPhoneNumber: "(***) *** 0123",
            redactedFormattedPhoneNumber: "+1 *** *** 0123",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: "US",
            verificationSessions: verificationSessions
        )
    }

    func consumerSessionResponse(
        clientSecret: String,
        verificationSessionID: String? = "cvs_fresh",
        verificationState: NetworkedIdentityVerificationSessionState = .started,
        authSessionClientSecret: String? = nil
    ) -> NetworkedIdentityConsumerSessionResponse {
        .init(
            consumerSession: consumerSession(
                clientSecret: clientSecret,
                verificationSessionID: verificationSessionID,
                verificationState: verificationState
            ),
            authSessionClientSecret: authSessionClientSecret
        )
    }

    func consumerSessionResponse(
        clientSecret: String,
        verificationSessions: [NetworkedIdentityVerificationSession],
        authSessionClientSecret: String? = nil
    ) -> NetworkedIdentityConsumerSessionResponse {
        .init(
            consumerSession: consumerSession(
                clientSecret: clientSecret,
                verificationSessions: verificationSessions
            ),
            authSessionClientSecret: authSessionClientSecret
        )
    }

    func verificationSession(
        id: String?,
        state: NetworkedIdentityVerificationSessionState,
        type: NetworkedIdentityVerificationSessionType = .sms
    ) -> NetworkedIdentityVerificationSession {
        .init(
            id: id,
            state: state,
            type: type,
            verificationToken: nil
        )
    }

    func identityDocument(
        id: String,
        documentType: NetworkedIdentityDocumentType = .drivingLicense,
        country: String = "US",
        expirationDate: Int = 1_900_000_000,
        liveCaptured: Bool? = true
    ) -> NetworkedIdentityDocument {
        .init(
            id: id,
            documentType: documentType,
            created: 1_700_000_000,
            country: country,
            region: "CA",
            redactedDocumentNumber: "***1234",
            expirationDate: expirationDate,
            liveCaptured: liveCaptured
        )
    }

    func consumerError(code: String) -> Error {
        NSError(
            domain: "NetworkedIdentityCoordinatorTest",
            code: 0,
            userInfo: [STPError.stripeErrorCodeKey: code]
        )
    }
}

@MainActor
private final class NetworkedIdentityCoordinatorDelegateSpy:
    NetworkedIdentityCoordinatorDelegate
{
    var onTransition: ((NetworkedIdentityState) -> Void)?
    private(set) var fullCaptureFallbackCount = 0
    private(set) var completions: [Result<StripeAPI.VerificationPageData, Error>] = []

    var actionErrors: [NetworkedIdentityActionError] {
        completions.compactMap { result in
            guard case .failure(let error) = result else { return nil }
            return error as? NetworkedIdentityActionError
        }
    }

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    ) {
        onTransition?(state)
    }

    func networkedIdentityCoordinatorDidRequestFullCaptureFallback(
        _ coordinator: NetworkedIdentityCoordinator
    ) {
        fullCaptureFallbackCount += 1
    }

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didCompleteWith result: Result<StripeAPI.VerificationPageData, Error>
    ) {
        completions.append(result)
    }
}

private enum TestError: Error {
    case lookupFailed
}

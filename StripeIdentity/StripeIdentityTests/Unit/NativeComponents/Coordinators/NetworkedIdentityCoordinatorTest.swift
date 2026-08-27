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
        apiClient = NetworkedIdentityAPIClientTestMock()
        credentialStore = NetworkedIdentityCredentialStore(
            verificationSessionClientSecrets: ["vs_client_secret"]
        )
        coordinator = NetworkedIdentityCoordinator(
            apiClient: apiClient,
            credentialStore: credentialStore,
            currentTime: { 1_800_000_000 }
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

        // Then selection stops before the currently undefined consent and clone work
        coordinator.selectDocument(identityDocument(id: document.id, country: "CA"))
        XCTAssertEqual(coordinator.state, .selectedDocument)
        XCTAssertEqual(coordinator.selectedDocument, document)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 0)
    }

    func testCanChangeSelectedDocumentBeforeConsent() {
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

        // When the consumer changes their selection before consent
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

    func testDuplicateOTPSubmissionWhilePendingIsIgnored() {
        // Given the coordinator is awaiting a fresh SMS code
        beginExistingConsumerFlow()

        // When submit is tapped twice before the first request completes
        coordinator.submitOTP("123456")
        coordinator.submitOTP("123456")

        // Then only one confirmation request is in flight
        XCTAssertEqual(coordinator.state, .otpConfirmPending)
        XCTAssertEqual(apiClient.confirmVerification.requestHistory.count, 1)
        XCTAssertEqual(apiClient.confirmVerification.pendingRequestCount, 1)
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
                        authSessionClientSecret: nil,
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
                        authSessionClientSecret: nil,
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
                    verificationSessionID: "cvs_fresh"
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
                    verificationState: .verified
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
                    locale: nil,
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
        verificationState: NetworkedIdentityVerificationSessionState = .started
    ) -> NetworkedIdentityConsumerSessionResponse {
        .init(
            consumerSession: consumerSession(
                clientSecret: clientSecret,
                verificationSessionID: verificationSessionID,
                verificationState: verificationState
            ),
            authSessionClientSecret: nil
        )
    }

    func consumerSessionResponse(
        clientSecret: String,
        verificationSessions: [NetworkedIdentityVerificationSession]
    ) -> NetworkedIdentityConsumerSessionResponse {
        .init(
            consumerSession: consumerSession(
                clientSecret: clientSecret,
                verificationSessions: verificationSessions
            ),
            authSessionClientSecret: nil
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
        expirationDate: Int = 1_900_000_000
    ) -> NetworkedIdentityDocument {
        .init(
            id: id,
            documentType: documentType,
            created: 1_700_000_000,
            country: country,
            region: "CA",
            redactedDocumentNumber: "***1234",
            expirationDate: expirationDate,
            liveCaptured: true
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
}

private enum TestError: Error {
    case lookupFailed
}

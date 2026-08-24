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

    func testExpiredOTPRequestsOneFreshCode() {
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
                with: .success(consumerSessionResponse(clientSecret: "cs_refreshed_otp"))
            )
        }
        XCTAssertNil(coordinator.lastOTPError)
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

        waitForTransition(to: .awaitingOTP) {
            apiClient.startVerification.respondToNext(
                with: .success(consumerSessionResponse(clientSecret: "cs_started"))
            )
        }
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
        verificationState: NetworkedIdentityVerificationSessionState = .started
    ) -> NetworkedIdentityConsumerSession {
        .init(
            clientSecret: clientSecret,
            emailAddress: "consumer@example.com",
            redactedPhoneNumber: "(***) *** 0123",
            redactedFormattedPhoneNumber: "+1 *** *** 0123",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: "US",
            verificationSessions: [
                .init(
                    id: "cvs_123",
                    state: verificationState,
                    type: .sms,
                    verificationToken: nil
                ),
            ]
        )
    }

    func consumerSessionResponse(
        clientSecret: String,
        verificationState: NetworkedIdentityVerificationSessionState = .started
    ) -> NetworkedIdentityConsumerSessionResponse {
        .init(
            consumerSession: consumerSession(
                clientSecret: clientSecret,
                verificationState: verificationState
            ),
            authSessionClientSecret: nil
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

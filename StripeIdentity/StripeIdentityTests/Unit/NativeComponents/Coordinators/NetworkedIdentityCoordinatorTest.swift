//
//  NetworkedIdentityCoordinatorTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
import XCTest

@_spi(STP) @testable import StripeIdentity

@MainActor
final class NetworkedIdentityCoordinatorTest: XCTestCase {
    private var linkSession: NetworkedIdentityLinkSessionTestMock!
    private var apiClient: NetworkedIdentityAPIClientTestMock!
    private var actions: NetworkedIdentityActionsTestMock!
    // swiftlint:disable:next weak_delegate
    private var delegate: NetworkedIdentityCoordinatorDelegateSpy!
    private var coordinator: NetworkedIdentityCoordinator!

    override func setUp() {
        super.setUp()
        linkSession = NetworkedIdentityLinkSessionTestMock()
        apiClient = NetworkedIdentityAPIClientTestMock()
        actions = NetworkedIdentityActionsTestMock()
        delegate = NetworkedIdentityCoordinatorDelegateSpy()
        makeCoordinator()
    }

    func testNothingStartsWithoutAnExplicitStart() {
        // When an email is submitted before the user starts
        coordinator.submitEmail("person@example.com")

        // Then nothing happens
        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertTrue(linkSession.lookup.requestHistory.isEmpty)
    }

    func testStartWithoutMerchantPublishableKeyFallsBack() async {
        // Given no merchant publishable key
        makeCoordinator(config: makeConfig(merchantPublishableKey: nil))

        // When the user starts
        coordinator.startReuse()
        await settle()

        // Then the flow falls back to capture
        XCTAssertEqual(coordinator.state, .fullCaptureFallback(.unavailable))
        XCTAssertEqual(delegate.outcomes, [.fallback(.unavailable)])
        // An automatic fallback isn't the user's choice, so it isn't recorded as a skip.
        XCTAssertEqual(actions.skipCount, 0)
    }

    func testLinkConfigurationFailureFallsBack() async {
        // Given the user started
        coordinator.startReuse()
        await settle()
        XCTAssertEqual(linkSession.configure.requestHistory, ["pk_test_merchant"])

        // When Link can't be configured
        linkSession.configure.respondToNext(with: .failure(TestError.failed))
        await settle()

        // Then the flow falls back to capture
        XCTAssertEqual(coordinator.state, .fullCaptureFallback(.unavailable))
    }

    func testWithoutHandoffOrKnownEmailTheUserEntersAnEmail() async {
        await startAndConfigure()

        XCTAssertEqual(coordinator.state, .collectEmail)
    }

    func testKnownMerchantEmailIsLookedUpWithoutAsking() async {
        // Given the merchant provided an email
        makeCoordinator(config: makeConfig(merchantEmail: "merchant@example.com"))

        // When the user starts
        await startAndConfigure()

        // Then it's looked up directly
        XCTAssertEqual(coordinator.state, .lookupPending)
        XCTAssertEqual(linkSession.lookup.requestHistory, ["merchant@example.com"])
    }

    func testHandoffIsNotUsedBeforeTheUserStarts() async {
        makeCoordinator(handoff: makeHandoff())
        await settle()

        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertTrue(linkSession.restore.requestHistory.isEmpty)
    }

    func testVerifiedHandoffSkipsSigningInAndLoadsDocuments() async {
        // Given a handed-in session
        makeCoordinator(handoff: makeHandoff())
        await startAndConfigure()
        XCTAssertEqual(
            linkSession.restore.requestHistory,
            [.init(publishableKey: "pk_consumer_handoff", sessionClientSecret: "handoff_secret")]
        )

        // When the session is already verified
        linkSession.restore.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()

        // Then documents load with the restored credentials
        XCTAssertEqual(coordinator.state, .documentsPending)
        XCTAssertEqual(apiClient.documentList.requestHistory.first?.consumerSessionClientSecret, "session_secret")
    }

    func testUnverifiedHandoffSendsACodeWithoutAskingForTheEmail() async {
        makeCoordinator(handoff: makeHandoff())
        await startAndConfigure()

        linkSession.restore.respondToNext(with: .success(niAccount(isVerified: false)))
        await settle()

        XCTAssertEqual(coordinator.state, .otpStartPending)
        XCTAssertEqual(linkSession.startVerification.requestHistory, [false])
    }

    func testExpiredHandoffFallsBackToLookingUpItsEmail() async {
        makeCoordinator(handoff: makeHandoff())
        await startAndConfigure()

        linkSession.restore.respondToNext(with: .failure(TestError.failed))
        await settle()

        XCTAssertEqual(linkSession.lookup.requestHistory, ["person@example.com"])
    }

    func testReuseWithoutLinkAccountFallsBack() async {
        await startAndConfigure()

        await signInWithEmail(account: nil)

        XCTAssertEqual(coordinator.state, .fullCaptureFallback(.noLinkAccount))
        XCTAssertEqual(delegate.outcomes, [.fallback(.noLinkAccount)])
    }

    func testCodeIsSentAndConfirmedBeforeDocumentsLoad() async {
        await startAndConfigure()
        await signInWithEmail()
        await completeCodeSent()
        XCTAssertEqual(coordinator.state, .awaitingOTP(invalidCode: false))
        XCTAssertEqual(coordinator.redactedFormattedPhoneNumber, "(***) ***-1234")

        await confirmCode()

        XCTAssertEqual(linkSession.confirmVerification.requestHistory, ["123456"])
        XCTAssertEqual(coordinator.state, .documentsPending)
    }

    func testMalformedCodeIsNotSubmitted() async {
        await startAndConfigure()
        await signInWithEmail()
        await completeCodeSent()

        coordinator.submitOTP("12a456")
        coordinator.submitOTP("123")

        XCTAssertTrue(linkSession.confirmVerification.requestHistory.isEmpty)
        XCTAssertEqual(coordinator.state, .awaitingOTP(invalidCode: false))
    }

    func testInvalidCodeKeepsTheUserOnTheCodeStep() async {
        await startAndConfigure()
        await signInWithEmail()
        await completeCodeSent()
        coordinator.submitOTP("123456")
        await settle()

        linkSession.confirmVerification.respondToNext(with: .failure(consumerError("consumer_verification_code_invalid")))
        await settle()

        XCTAssertEqual(coordinator.state, .awaitingOTP(invalidCode: true))
    }

    func testExpiredCodeSendsANewOne() async {
        await startAndConfigure()
        await signInWithEmail()
        await completeCodeSent()
        coordinator.submitOTP("123456")
        await settle()

        linkSession.confirmVerification.respondToNext(with: .failure(consumerError("consumer_verification_expired")))
        await settle()

        XCTAssertEqual(linkSession.startVerification.requestHistory, [false, false])
    }

    func testExpiredSessionAsksToSignInAgain() async {
        await startAndConfigure()
        await signInWithEmail()
        await completeCodeSent()
        coordinator.submitOTP("123456")
        await settle()

        linkSession.confirmVerification.respondToNext(with: .failure(consumerError("consumer_session_expired")))
        await settle()

        XCTAssertEqual(coordinator.state, .reauthenticationRequired)
    }

    func testResendRequestsANewCode() async {
        await startAndConfigure()
        await signInWithEmail()
        await completeCodeSent()

        coordinator.resendOTP()
        await settle()

        XCTAssertEqual(linkSession.startVerification.requestHistory, [false, true])
    }

    func testSingleEligibleDocumentIsPreselectedButNotShared() async {
        await reachDocuments([makeDocument(id: "doc_1")])

        XCTAssertEqual(coordinator.state, .selectDocument(documents: [makeDocument(id: "doc_1")], selectedDocumentID: "doc_1"))
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)
    }

    func testSeveralDocumentsNeedASelectionBeforeSharing() async {
        await reachDocuments([makeDocument(id: "doc_1"), makeDocument(id: "doc_2")])

        coordinator.shareSelectedDocument()
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)
        coordinator.selectDocument(makeDocument(id: "doc_2"))

        guard case .selectDocument(_, let selectedID) = coordinator.state else {
            return XCTFail("Expected document selection, got \(String(describing: coordinator.state))")
        }
        XCTAssertEqual(selectedID, "doc_2")
    }

    func testSharingAttachesTheSelectedDocumentAndWaitsForContinue() async {
        await reachDocuments([makeDocument(id: "doc_1")])

        // When the user shares the preselected document
        coordinator.shareSelectedDocument()
        XCTAssertEqual(coordinator.state, .sharingDocument(makeDocument(id: "doc_1")))
        await settle()
        XCTAssertEqual(apiClient.associationToken.requestHistory.first?.identityDocumentID, "doc_1")
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1"])
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        // Then it waits for the user to continue
        XCTAssertEqual(coordinator.state, .documentShared(makeDocument(id: "doc_1")))
        XCTAssertTrue(delegate.outcomes.isEmpty)

        coordinator.continueAfterSuccess()

        XCTAssertEqual(delegate.outcomes, [.documentShared(makeDocument(id: "doc_1"), attached: niActionPageData())])
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testNoEligibleDocumentsFallsBack() async {
        await reachDocuments([makeDocument(id: "doc_1", liveCaptured: false)])

        XCTAssertEqual(coordinator.state, .fullCaptureFallback(.noReusableDocuments))
    }

    func testSaveForNewAccountCollectsPhoneAndSignsUp() async {
        makeCoordinator(config: makeConfig(route: .save))
        await startAndConfigure(mode: .save)
        await signInWithEmail(account: nil)
        XCTAssertEqual(coordinator.state, .collectPhone(email: "person@example.com", error: nil))

        coordinator.submitPhone(phoneNumber: "+15555551234", country: "US")
        await settle()
        XCTAssertEqual(
            linkSession.signUp.requestHistory,
            [.init(email: "person@example.com", phoneNumber: "+15555551234", country: "US", name: nil)]
        )
        linkSession.signUp.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()
        XCTAssertEqual(
            apiClient.saveAssociationToken.requestHistory,
            [.init(verificationSessionID: "vs_target", consumerSessionClientSecret: "session_secret", consumerPublishableKey: "pk_consumer")]
        )
        apiClient.saveAssociationToken.respondToNext(with: .success(.init(associationToken: "save_token")))
        await settle()
        XCTAssertEqual(actions.prepareDocumentSave.requestHistory, ["save_token"])
        actions.prepareDocumentSave.respondToNext(with: .success(niActionPageData()))
        await settle()

        XCTAssertEqual(coordinator.state, .saved)
        XCTAssertTrue(coordinator.hasSaved)
        XCTAssertTrue(delegate.outcomes.isEmpty)

        coordinator.continueAfterSuccess()

        XCTAssertEqual(delegate.outcomes, [.saved])
    }

    func testSaveForUnverifiedExistingAccountConfirmsACodeFirst() async {
        makeCoordinator(config: makeConfig(route: .save))
        await startAndConfigure(mode: .save)
        await signInWithEmail()
        await completeCodeSent()

        await confirmCode()

        XCTAssertEqual(coordinator.state, .savePending)
        XCTAssertEqual(apiClient.saveAssociationToken.requestHistory.count, 1)
    }

    func testSaveFailureKeepsTheSheetOpenUntilClosed() async {
        // Given a signed-in user is saving
        makeCoordinator(config: makeConfig(route: .save))
        await startAndConfigure(mode: .save)
        await signInWithEmail()
        await completeCodeSent()
        await confirmCode()

        // When the save token can't be created
        apiClient.saveAssociationToken.respondToNext(with: .failure(TestError.failed))
        await settle()

        // Then the sheet says so instead of closing
        XCTAssertEqual(coordinator.state, .saveFailed(details: "failed"))
        XCTAssertTrue(delegate.outcomes.isEmpty)

        // ...until the user closes it
        coordinator.cancel()
        XCTAssertEqual(delegate.outcomes, [.cancelled])
    }

    func testCancelReportsCancellationAndANewAttemptCanStart() async {
        await startAndConfigure()

        coordinator.cancel()
        await settle()

        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(delegate.outcomes, [.cancelled])
        XCTAssertEqual(actions.skipCount, 0)

        // When the user starts again, Link stays configured and the session is never logged out
        coordinator.startReuse()
        await settle()

        XCTAssertEqual(coordinator.state, .collectEmail)
        XCTAssertEqual(linkSession.configure.requestHistory.count, 1)
        XCTAssertEqual(linkSession.logOutCount, 0)
    }

    func testResponsesFromACancelledAttemptAreIgnored() async {
        await startAndConfigure()
        coordinator.submitEmail("person@example.com")
        await settle()
        coordinator.cancel()

        linkSession.lookup.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()

        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(apiClient.documentList.requestHistory.isEmpty)
    }

    func testManualCaptureReportsAFallback() async {
        await startAndConfigure()

        coordinator.chooseManualCapture()
        await settle()

        XCTAssertEqual(delegate.outcomes, [.fallback(.userSelectedManualCapture)])
        XCTAssertEqual(actions.skipCount, 1)
    }

    func testFailedAttachFallsBackWithoutReplayingTheToken() async {
        await reachDocuments([makeDocument(id: "doc_1")])

        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(TestError.failed))
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback(.unavailable))
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1"])
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertEqual(actions.skipCount, 0)
    }

    func testAbandonStopsWithoutReportingAnOutcome() async {
        await startAndConfigure()

        coordinator.abandon()
        await settle()

        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(delegate.outcomes.isEmpty)
    }

    // MARK: - Entry

    func testEntryWithHandoffOffersReuseForItsAccount() {
        let entry = NetworkedIdentityEntry(config: makeConfig(), handoff: makeHandoff())

        XCTAssertEqual(entry, .init(linkAvailable: true, accountEmail: "person@example.com", needsEmail: false))
        XCTAssertTrue(entry.offersReuse)
    }

    func testEntryWithoutEmailOffersReuseAndAsksForTheEmail() {
        let entry = NetworkedIdentityEntry(config: makeConfig(), handoff: nil)

        XCTAssertEqual(entry, .init(linkAvailable: true, accountEmail: nil, needsEmail: true))
        XCTAssertTrue(entry.offersReuse)
    }

    func testEntryWithProvidedEmailWaitsForTheLookup() {
        let entry = NetworkedIdentityEntry(config: makeConfig(merchantEmail: "person@example.com"), handoff: nil)

        XCTAssertFalse(entry.offersReuse)
        XCTAssertTrue(entry.linkAvailable)
    }

    func testEntryWithoutPublishableKeyOffersNothing() {
        let entry = NetworkedIdentityEntry(config: makeConfig(merchantPublishableKey: nil), handoff: makeHandoff())

        XCTAssertFalse(entry.linkAvailable)
        XCTAssertFalse(entry.offersReuse)
    }

    func testProvidedEmailLookupReturnsTheAccountEmail() async {
        makeCoordinator(config: makeConfig(merchantEmail: "person@example.com"))

        let found = await lookUpProvidedAccountEmail(respondingWith: niAccount())

        XCTAssertEqual(found, "person@example.com")
        XCTAssertEqual(linkSession.lookup.requestHistory, ["person@example.com"])
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testProvidedEmailLookupWithoutAccountReturnsNil() async {
        makeCoordinator(config: makeConfig(merchantEmail: "person@example.com"))

        let found = await lookUpProvidedAccountEmail(respondingWith: nil)

        XCTAssertNil(found)
    }

    func testLinkIsConfiguredOnceForLookupAndStart() async {
        // Given the provided email was looked up
        makeCoordinator(config: makeConfig(merchantEmail: "person@example.com"))
        _ = await lookUpProvidedAccountEmail(respondingWith: niAccount())

        // When the user starts
        coordinator.startReuse()
        await settle()

        // Then Link isn't configured again
        XCTAssertEqual(linkSession.configure.requestHistory, ["pk_test_merchant"])
        XCTAssertEqual(coordinator.state, .lookupPending)
    }
}

// MARK: - Helpers

private extension NetworkedIdentityCoordinatorTest {
    func makeCoordinator(
        config: NetworkedIdentityConfig? = nil,
        handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff? = nil
    ) {
        coordinator = NetworkedIdentityCoordinator(
            linkSession: linkSession,
            apiClient: apiClient,
            actions: actions,
            documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: true),
            config: config ?? makeConfig(),
            handoff: handoff,
            currentTime: { 1_800_000_000 }
        )
        coordinator.delegate = delegate
    }

    func makeConfig(
        route: NetworkedIdentityRoute = .reuse,
        merchantPublishableKey: String? = "pk_test_merchant",
        merchantEmail: String? = nil
    ) -> NetworkedIdentityConfig {
        .init(
            route: route,
            merchantPublishableKey: merchantPublishableKey,
            merchantEmail: merchantEmail,
            seedSavedDocuments: false
        )
    }

    func makeHandoff() -> IdentityVerificationSheet.Configuration.LinkSessionHandoff {
        .init(
            email: "person@example.com",
            consumerSessionClientSecret: "handoff_secret",
            consumerPublishableKey: "pk_consumer_handoff"
        )
    }

    func makeDocument(id: String, liveCaptured: Bool = true) -> NetworkedIdentityDocument {
        .init(
            id: id,
            documentType: .passport,
            created: 1_700_000_000,
            country: "US",
            region: nil,
            redactedDocumentNumber: "•••• 1234",
            expirationDate: 1_900_000_000,
            liveCaptured: liveCaptured
        )
    }

    /// Lets suspended mock requests and their completions run on the main actor.
    func settle() async {
        for _ in 0..<20 {
            await Task.yield()
        }
        try? await Task.sleep(nanoseconds: 5_000_000)
        for _ in 0..<20 {
            await Task.yield()
        }
    }

    func startAndConfigure(mode: NetworkedIdentityMode = .reuse) async {
        switch mode {
        case .reuse:
            coordinator.startReuse()
        case .save:
            coordinator.startSave()
        }
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
    }

    func lookUpProvidedAccountEmail(respondingWith account: NetworkedIdentityLinkAccount?) async -> String? {
        let lookup = Task { await coordinator.lookUpProvidedAccountEmail() }
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        linkSession.lookup.respondToNext(with: .success(account))
        return await lookup.value
    }

    func signInWithEmail(account: NetworkedIdentityLinkAccount? = niAccount()) async {
        coordinator.submitEmail("person@example.com")
        await settle()
        linkSession.lookup.respondToNext(with: .success(account))
        await settle()
    }

    func completeCodeSent() async {
        linkSession.startVerification.respondToNext(with: .success(niAccount()))
        await settle()
    }

    func confirmCode() async {
        coordinator.submitOTP("123456")
        await settle()
        linkSession.confirmVerification.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()
    }

    func reachDocuments(_ documents: [NetworkedIdentityDocument]) async {
        await startAndConfigure()
        await signInWithEmail()
        await completeCodeSent()
        await confirmCode()
        apiClient.documentList.respondToNext(with: .success(.init(data: documents)))
        await settle()
    }

    func consumerError(_ code: String) -> Error {
        NSError(
            domain: "NetworkedIdentityCoordinatorTest",
            code: 0,
            userInfo: [STPError.stripeErrorCodeKey: code]
        )
    }
}

private enum TestError: Error {
    case failed
}

@MainActor
private final class NetworkedIdentityCoordinatorDelegateSpy: NetworkedIdentityCoordinatorDelegate {
    private(set) var states: [NetworkedIdentityState] = []
    private(set) var outcomes: [NetworkedIdentityOutcome] = []

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    ) {
        states.append(state)
    }

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didFinishWith outcome: NetworkedIdentityOutcome
    ) {
        outcomes.append(outcome)
    }
}

//
//  NetworkedIdentityCoordinatorTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
import UIKit
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
    private var linkUIHost: UIViewController!

    override func setUp() {
        super.setUp()
        linkSession = NetworkedIdentityLinkSessionTestMock()
        apiClient = NetworkedIdentityAPIClientTestMock()
        actions = NetworkedIdentityActionsTestMock()
        delegate = NetworkedIdentityCoordinatorDelegateSpy()
        linkUIHost = UIViewController()
        makeCoordinator()
    }

    func testNothingStartsWithoutAnExplicitStart() async {
        // When the user shares or continues before starting
        coordinator.shareSelectedDocument()
        coordinator.continueAfterSuccess()
        await settle()

        // Then nothing happens
        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertTrue(linkSession.configure.requestHistory.isEmpty)
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)
        XCTAssertTrue(delegate.outcomes.isEmpty)
    }

    func testStartWithoutMerchantPublishableKeyFallsBack() async {
        // Given no merchant publishable key
        makeCoordinator(config: makeConfig(merchantPublishableKey: nil))

        // When the user starts
        coordinator.startReuse()
        await settle()

        // Then the flow falls back to capture
        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(delegate.outcomes, [.fallback])
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
        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
    }

    func testWithoutHandoffOrKnownEmailLinksScreensAskForTheEmail() async {
        await startAndConfigure()

        // Link's own screens sign the user in; Identity's sheet stays hidden meanwhile
        XCTAssertEqual(coordinator.state, .linkAuthentication)
        XCTAssertFalse(coordinator.state.presentsIdentitySheet)
        XCTAssertEqual(linkSession.authenticateWithLinkUI.requestHistory, [.init(email: nil, phoneNumber: nil)])
    }

    func testKnownEmailAndPhoneHintPrefillLinksScreens() async {
        // Given the page provides an email and a phone hint
        makeCoordinator(config: makeConfig(merchantEmail: "merchant@example.com", phoneNumberAutofillHint: "+12025550100"))

        // When the user starts
        await startAndConfigure()

        // Then Link's screens are prefilled, without a lookup by Identity
        XCTAssertEqual(
            linkSession.authenticateWithLinkUI.requestHistory,
            [.init(email: "merchant@example.com", phoneNumber: "+12025550100")]
        )
        XCTAssertTrue(linkSession.lookup.requestHistory.isEmpty)
    }

    func testLinkAuthenticationLoadsDocumentsWithItsCredentials() async {
        await startAndConfigure()

        await authenticate()

        XCTAssertEqual(coordinator.state, .documentsPending)
        XCTAssertEqual(
            apiClient.documentList.requestHistory,
            [.init(consumerSessionClientSecret: "session_secret", consumerPublishableKey: "pk_consumer")]
        )
    }

    func testLinkAuthenticationFailureFallsBack() async {
        await startAndConfigure()

        linkSession.authenticateWithLinkUI.respondToNext(with: .failure(TestError.failed))
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(delegate.outcomes, [.fallback])
    }

    func testWithoutAHostForLinksScreensFallsBack() async {
        coordinator.linkUIHost = nil

        await startAndConfigure()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertTrue(linkSession.authenticateWithLinkUI.requestHistory.isEmpty)
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

        // Then documents load with the restored credentials, without Link's screens
        XCTAssertEqual(coordinator.state, .documentsPending)
        XCTAssertEqual(apiClient.documentList.requestHistory.first?.consumerSessionClientSecret, "session_secret")
        XCTAssertTrue(linkSession.authenticateWithLinkUI.requestHistory.isEmpty)
    }

    func testUnverifiedHandoffSignsInWithLinksScreensForItsAccount() async {
        makeCoordinator(handoff: makeHandoff(email: "handoff@example.com"))
        await startAndConfigure()

        linkSession.restore.respondToNext(with: .success(niAccount(isVerified: false)))
        await settle()

        XCTAssertEqual(coordinator.state, .linkAuthentication)
        XCTAssertEqual(linkSession.authenticateWithLinkUI.requestHistory, [.init(email: "person@example.com", phoneNumber: nil)])
    }

    func testExpiredHandoffSignsInWithLinksScreensForItsEmail() async {
        makeCoordinator(handoff: makeHandoff(email: "handoff@example.com"))
        await startAndConfigure()

        linkSession.restore.respondToNext(with: .failure(TestError.failed))
        await settle()

        XCTAssertEqual(coordinator.state, .linkAuthentication)
        XCTAssertEqual(linkSession.authenticateWithLinkUI.requestHistory, [.init(email: "handoff@example.com", phoneNumber: nil)])
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
        XCTAssertEqual(apiClient.associationToken.requestHistory.first?.verificationSessionID, "vs_target")
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1"])
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        // Then it waits for the user to continue
        XCTAssertEqual(coordinator.state, .documentShared(makeDocument(id: "doc_1")))
        XCTAssertTrue(delegate.outcomes.isEmpty)

        coordinator.continueAfterSuccess()

        XCTAssertEqual(delegate.outcomes, [.documentShared])
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testNoEligibleDocumentsFallsBack() async {
        await reachDocuments([makeDocument(id: "doc_1", liveCaptured: false)])

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
    }

    func testSaveSignsInWithLinksScreensThenPreparesTheSave() async {
        // Given the user starts saving
        makeCoordinator(config: makeConfig(route: .save, merchantEmail: "person@example.com"))
        await startAndConfigure(mode: .save)
        XCTAssertEqual(linkSession.authenticateWithLinkUI.requestHistory, [.init(email: "person@example.com", phoneNumber: nil)])

        // When Link's screens verify the session
        await authenticate()

        // Then the save is prepared with the authenticated account
        XCTAssertEqual(
            apiClient.saveAssociationToken.requestHistory,
            [.init(verificationSessionID: "vs_target", consumerSessionClientSecret: "session_secret", consumerPublishableKey: "pk_consumer")]
        )
        apiClient.saveAssociationToken.respondToNext(with: .success(.init(associationToken: "save_token")))
        await settle()
        XCTAssertEqual(actions.prepareDocumentSave.requestHistory, ["save_token"])
        actions.prepareDocumentSave.respondToNext(with: .success(niActionPageData()))
        await settle()

        XCTAssertEqual(coordinator.state, .savePrepared)
        XCTAssertFalse(coordinator.entry.offersSave)
        XCTAssertTrue(delegate.outcomes.isEmpty)

        coordinator.continueAfterSuccess()

        XCTAssertEqual(delegate.outcomes, [.savePrepared])
    }

    func testDismissingLinksScreensCancels() async {
        makeCoordinator(config: makeConfig(route: .save))
        await startAndConfigure(mode: .save)

        linkSession.authenticateWithLinkUI.respondToNext(with: .success(nil))
        await settle()

        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(delegate.outcomes, [.cancelled])
    }

    func testSaveFailureKeepsTheSheetOpenUntilClosed() async {
        // Given a signed-in user is saving
        makeCoordinator(config: makeConfig(route: .save))
        await startAndConfigure(mode: .save)
        await authenticate()

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

        // When the user starts again, Link stays configured
        coordinator.startReuse()
        await settle()

        XCTAssertEqual(coordinator.state, .linkAuthentication)
        XCTAssertEqual(linkSession.configure.requestHistory.count, 1)
    }

    func testResponsesFromACancelledAttemptAreIgnored() async {
        await startAndConfigure()
        coordinator.cancel()

        await authenticate()

        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(apiClient.documentList.requestHistory.isEmpty)
    }

    func testManualCaptureRecordsTheSkip() async {
        await startAndConfigure()

        coordinator.chooseManualCapture()
        await settle()

        XCTAssertEqual(delegate.outcomes, [.manualCapture])
        XCTAssertEqual(actions.skipCount, 1)
    }

    func testRejectedAttachIsRetriedOnceWithAFreshToken() async {
        await reachDocuments([makeDocument(id: "doc_1")])

        // When the first token is rejected and the session shows no attachment
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(apiError(status: 400)))
        await settle()

        // Then a fresh token is minted and redeemed; the first one is never replayed
        XCTAssertEqual(actions.committedChecks, [.resumeReuse])
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_2")))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1", "token_2"])
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        XCTAssertEqual(coordinator.state, .documentShared(makeDocument(id: "doc_1")))
        XCTAssertEqual(coordinator.route, .resumeReuse)
    }

    func testLostAttachResponseContinuesWhenTheSessionShowsTheAttachment() async {
        await reachDocuments([makeDocument(id: "doc_1")])
        var recorded: StripeAPI.VerificationPageData?
        coordinator.onVerificationUpdate = { recorded = $0; return true }
        actions.committedVerification = .success(niActionPageData())

        // When the attach response is lost but the session shows the document attached
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(URLError(.networkConnectionLost)))
        await settle()

        // Then the flow continues from the session state, without minting another token
        XCTAssertEqual(coordinator.state, .documentShared(makeDocument(id: "doc_1")))
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertEqual(recorded, niActionPageData())
        XCTAssertEqual(coordinator.route, .resumeReuse)
    }

    func testLostAttachResponseFallsBackWhenTheSessionCannotBeReadBack() async {
        await reachDocuments([makeDocument(id: "doc_1")])
        actions.committedVerification = .failure(URLError(.networkConnectionLost))

        // When the attach response is lost and the session can't be read back
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(URLError(.networkConnectionLost)))
        await settle()

        // Then the flow falls back without minting another token, since the first attach may have committed
        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertEqual(actions.committedChecks, [.resumeReuse])
    }

    func testAttachFailingTwiceFallsBack() async {
        await reachDocuments([makeDocument(id: "doc_1")])

        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(apiError(status: 429)))
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_2")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(URLError(.timedOut)))
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1", "token_2"])
        XCTAssertEqual(actions.committedChecks, [.resumeReuse, .resumeReuse])
        XCTAssertEqual(actions.skipCount, 0)
    }

    func testUnavailableNetworkedIdentityFallsBackWithoutRetrying() async {
        await reachDocuments([makeDocument(id: "doc_1")])

        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(
            with: .failure(apiError(status: 400, code: "networked_identity_unavailable"))
        )
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertTrue(actions.committedChecks.isEmpty)
    }

    func testDifferentSessionResponseFallsBackWithoutRetrying() async {
        await reachDocuments([makeDocument(id: "doc_1")])

        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(apiError(status: 404)))
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertTrue(actions.committedChecks.isEmpty)
    }

    func testAttachmentTheHostRejectsFallsBackWithoutRetrying() async {
        // Given the host rejects the session's updates
        await reachDocuments([makeDocument(id: "doc_1")])
        coordinator.onVerificationUpdate = { _ in false }

        // When the attachment comes back
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        // Then it isn't shown as shared, and reuse stays the route
        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertEqual(coordinator.route, .reuse)
    }

    func testLostSaveResponseContinuesWhenTheSessionShowsTheSave() async {
        makeCoordinator(config: makeConfig(route: .save))
        await startAndConfigure(mode: .save)
        await authenticate()
        actions.committedVerification = .success(niActionPageData())

        apiClient.saveAssociationToken.respondToNext(with: .success(.init(associationToken: "save_token")))
        await settle()
        actions.prepareDocumentSave.respondToNext(with: .failure(apiError(status: 502)))
        await settle()

        XCTAssertEqual(actions.committedChecks, [.resumeSave])
        XCTAssertEqual(apiClient.saveAssociationToken.requestHistory.count, 1)
        XCTAssertEqual(coordinator.state, .savePrepared)
        XCTAssertFalse(coordinator.entry.offersSave)
    }

    func testAbandonStopsWithoutReportingAnOutcome() async {
        await startAndConfigure()

        coordinator.abandon()
        await settle()

        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertTrue(delegate.outcomes.isEmpty)
    }

    func testManualCaptureWaitsForAnIssuedAttachmentBeforeSkipping() async {
        await reachDocuments([makeDocument(id: "doc_1")])
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1"])

        coordinator.chooseManualCapture()
        await settle()
        XCTAssertEqual(coordinator.state, .skipPending)
        XCTAssertEqual(actions.skipCount, 0)
        XCTAssertTrue(delegate.outcomes.isEmpty)

        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()
        XCTAssertEqual(actions.skipCount, 1)
        XCTAssertEqual(delegate.outcomes, [.manualCapture])
        XCTAssertEqual(coordinator.route, .none)
        XCTAssertFalse(coordinator.entry.offersSave)
    }

    func testClosingDuringAnIssuedAttachmentStillUpdatesTheHostRequirements() async {
        await reachDocuments([makeDocument(id: "doc_1")])
        var recorded: StripeAPI.VerificationPageData?
        coordinator.onVerificationUpdate = { recorded = $0; return true }
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()

        coordinator.cancel()
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        XCTAssertEqual(recorded, niActionPageData())
        XCTAssertEqual(delegate.routes, [.resumeReuse])
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(delegate.outcomes, [.cancelled])
    }

    func testReopeningLinkWaitsForThePreviousWriteBeforeAttachingAgain() async {
        await reachDocuments([makeDocument(id: "doc_1")])
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        coordinator.cancel()

        coordinator.startReuse()
        await settle()
        apiClient.documentList.respondToNext(with: .success(.init(data: [makeDocument(id: "doc_2")])))
        await settle()
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_2")))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1"])

        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1", "token_2"])
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()
        XCTAssertEqual(coordinator.state, .documentShared(makeDocument(id: "doc_2")))
    }

    func testFailedSkipStillContinuesWithOrdinaryVerification() async {
        actions.skipResult = .failure(TestError.failed)
        coordinator.chooseManualCapture()
        await settle()

        // The choice isn't recorded, but the user isn't blocked from verifying
        XCTAssertEqual(delegate.outcomes, [.fallback])
        XCTAssertEqual(coordinator.route, .reuse)
    }

    func testSaveAfterNoReusableDocumentsUsesTheSameAuthenticatedAccount() async {
        await reachDocuments([])

        coordinator.startSave()
        await settle()

        XCTAssertEqual(coordinator.state, .savePending)
        XCTAssertEqual(linkSession.configure.requestHistory.count, 1)
        XCTAssertEqual(linkSession.authenticateWithLinkUI.requestHistory.count, 1)
        apiClient.saveAssociationToken.respondToNext(with: .failure(TestError.failed))
        await settle()
    }

    func testStartingWhilePreviewLookupIsPendingSharesLinksConfiguration() async {
        // Given the provided email's lookup is still pending
        makeCoordinator(config: makeConfig(merchantEmail: "person@example.com"))
        let preview = Task { await coordinator.lookUpProvidedAccountEmail() }
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        XCTAssertEqual(linkSession.lookup.requestHistory, ["person@example.com"])

        // When the user starts
        coordinator.startReuse()
        await settle()

        // Then Link's screens sign in with the provided email, without configuring Link again
        XCTAssertEqual(linkSession.configure.requestHistory.count, 1)
        XCTAssertEqual(linkSession.authenticateWithLinkUI.requestHistory, [.init(email: "person@example.com", phoneNumber: nil)])

        linkSession.lookup.respondToNext(with: .success(niAccount()))
        _ = await preview.value
    }

    // MARK: - Entry

    func testEntryWithHandoffOffersReuseForItsAccount() {
        let entry = NetworkedIdentityEntry(config: makeConfig(), handoff: makeHandoff())

        XCTAssertEqual(entry.accountEmail, "person@example.com")
        XCTAssertFalse(entry.needsEmail)
        XCTAssertTrue(entry.offersReuse)
    }

    func testEntryWithoutEmailOffersReuseAndAsksForTheEmail() {
        let entry = NetworkedIdentityEntry(config: makeConfig(), handoff: nil)

        XCTAssertNil(entry.accountEmail)
        XCTAssertTrue(entry.needsEmail)
        XCTAssertTrue(entry.offersReuse)
    }

    func testEntryWithProvidedEmailWaitsForTheLookup() {
        let entry = NetworkedIdentityEntry(config: makeConfig(merchantEmail: "person@example.com"), handoff: nil)

        XCTAssertFalse(entry.offersReuse)
        XCTAssertTrue(entry.reuseAvailable)
    }

    func testEntryWithoutPublishableKeyOffersNothing() {
        let entry = NetworkedIdentityEntry(config: makeConfig(merchantPublishableKey: nil), handoff: makeHandoff())

        XCTAssertFalse(entry.reuseAvailable || entry.offersSave)
        XCTAssertFalse(entry.offersReuse)
    }

    func testSaveOnlySessionDoesNotLookUpTheProvidedEmail() async {
        // Given a session that only offers saving, with a provided email
        makeCoordinator(config: makeConfig(route: .save, merchantEmail: "person@example.com"))

        // When the entry is checked
        _ = Task { await coordinator.lookUpProvidedAccountEmail() }
        await settle()

        // Then Link isn't set up to look up the email
        XCTAssertTrue(linkSession.configure.requestHistory.isEmpty)
        XCTAssertTrue(linkSession.lookup.requestHistory.isEmpty)
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

    func testFailedProvidedEmailLookupIsRetried() async {
        // Given the provided email's lookup failed
        makeCoordinator(config: makeConfig(merchantEmail: "person@example.com"))
        let failed = Task { await coordinator.lookUpProvidedAccountEmail() }
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        linkSession.lookup.respondToNext(with: .failure(TestError.failed))
        let failedResult = await failed.value
        XCTAssertNil(failedResult)

        // When the entry is checked again
        let retried = Task { await coordinator.lookUpProvidedAccountEmail() }
        await settle()

        // Then the email is looked up again
        XCTAssertEqual(linkSession.lookup.requestHistory, ["person@example.com", "person@example.com"])
        linkSession.lookup.respondToNext(with: .success(niAccount()))
        let found = await retried.value
        XCTAssertEqual(found, "person@example.com")
    }

    func testLinkIsConfiguredOnceForLookupAndStart() async {
        // Given the provided email was looked up
        makeCoordinator(config: makeConfig(merchantEmail: "person@example.com"))
        _ = await lookUpProvidedAccountEmail(respondingWith: niAccount())

        // When the user starts
        coordinator.startReuse()
        await settle()

        // Then Link isn't configured again, and Link's screens verify the account that was found
        XCTAssertEqual(linkSession.configure.requestHistory, ["pk_test_merchant"])
        XCTAssertEqual(coordinator.state, .linkAuthentication)
        XCTAssertEqual(linkSession.authenticateWithLinkUI.requestHistory, [.init(email: "person@example.com", phoneNumber: nil)])
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
        coordinator.linkUIHost = linkUIHost
        coordinator.onVerificationUpdate = { _ in true }
    }

    func makeConfig(
        route: NetworkedIdentityRoute = .reuse,
        merchantPublishableKey: String? = "pk_test_merchant",
        merchantEmail: String? = nil,
        phoneNumberAutofillHint: String? = nil
    ) -> NetworkedIdentityConfig {
        .init(
            route: route,
            saveAvailable: true,
            merchantPublishableKey: merchantPublishableKey,
            merchantEmail: merchantEmail,
            phoneNumberAutofillHint: phoneNumberAutofillHint,
            seedSavedDocuments: false
        )
    }

    func makeHandoff(email: String = "person@example.com") -> IdentityVerificationSheet.Configuration.LinkSessionHandoff {
        .init(
            email: email,
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

    /// Completes Link's sign-in screens with a verified account.
    func authenticate() async {
        linkSession.authenticateWithLinkUI.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()
    }

    func reachDocuments(_ documents: [NetworkedIdentityDocument]) async {
        await startAndConfigure()
        await authenticate()
        apiClient.documentList.respondToNext(with: .success(.init(data: documents)))
        await settle()
    }

    func apiError(status: Int, code: String? = nil) -> Error {
        var error = try! StripeJSONDecoder().decode(
            StripeAPIError.self,
            from: Data(#"{"type":"invalid_request_error"}"#.utf8)
        )
        error.code = code
        error.httpStatusCode = status
        return StripeError.apiError(error)
    }
}

private enum TestError: Error {
    case failed
}

@MainActor
private final class NetworkedIdentityCoordinatorDelegateSpy: NetworkedIdentityCoordinatorDelegate {
    private(set) var states: [NetworkedIdentityState] = []
    private(set) var outcomes: [NetworkedIdentityOutcome] = []
    private(set) var routes: [NetworkedIdentityRoute] = []

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

    func networkedIdentityCoordinatorDidChangeRoute(_ coordinator: NetworkedIdentityCoordinator) {
        routes.append(coordinator.route)
    }
}

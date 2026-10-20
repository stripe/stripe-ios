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
        XCTAssertTrue(actions.skips.requestHistory.isEmpty)
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

        // Link's own screens sign the user in
        XCTAssertEqual(coordinator.state, .linkAuthentication)
        XCTAssertEqual(
            linkSession.authenticateWithLinkUI.requestHistory,
            [.init(email: nil, phoneNumber: nil, mode: .reuse)]
        )
    }

    func testKnownEmailAndPhoneHintPrefillLinksScreens() async {
        // Given the page provides an email and a phone hint
        makeCoordinator(config: makeConfig(merchantEmail: "merchant@example.com", phoneNumberAutofillHint: "+12025550100"))

        // When the user starts
        await startAndConfigure()

        // Then Link's screens are prefilled
        XCTAssertEqual(
            linkSession.authenticateWithLinkUI.requestHistory,
            [.init(email: "merchant@example.com", phoneNumber: "+12025550100", mode: .reuse)]
        )
    }

    func testLinkAuthenticationLoadsDocumentsWithItsCredentials() async {
        await startAndConfigure()

        await authenticate()

        XCTAssertEqual(coordinator.state, .documentsPending)
        XCTAssertEqual(
            apiClient.documentList.requestHistory,
            [.init(linkSessionKey: "lsk_session")]
        )
    }

    func testLinkAuthenticationFailureFallsBack() async {
        await startAndConfigure()

        linkSession.authenticateWithLinkUI.respondToNext(with: .failure(TestError.failed))
        await settle(until: { coordinator.state != .linkAuthentication })

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(delegate.outcomes, [.fallback])
    }

    func testWithoutAHostForLinksScreensFallsBack() async {
        coordinator.linkUIHost = nil

        await startAndConfigure()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertTrue(linkSession.authenticateWithLinkUI.requestHistory.isEmpty)
    }

    func testHandedInKeyLoadsDocumentsWithoutSigningIn() async {
        makeCoordinator(handoff: makeHandoff())
        await startAndConfigure()

        XCTAssertEqual(coordinator.state, .documentsPending)
        XCTAssertEqual(apiClient.documentList.requestHistory, [.init(linkSessionKey: "lsk_handoff")])
        XCTAssertTrue(linkSession.authenticateWithLinkUI.requestHistory.isEmpty)
    }

    func testHandedInKeyTheDocumentListRejectsSignsInWithLinksScreensForItsEmail() async {
        makeCoordinator(handoff: makeHandoff(email: "handoff@example.com"))
        await startAndConfigure()

        apiClient.documentList.respondToNext(with: .failure(apiError(status: 403)))
        await settle()

        XCTAssertEqual(coordinator.state, .linkAuthentication)
        XCTAssertEqual(
            linkSession.authenticateWithLinkUI.requestHistory,
            [.init(email: "handoff@example.com", phoneNumber: nil, mode: .reuse)]
        )
    }

    func testHandedInKeyTheSaveTokenRejectsSignsInWithLinksScreensForItsEmail() async {
        makeCoordinator(handoff: makeHandoff(email: "handoff@example.com"))
        await startAndConfigure(mode: .save)

        apiClient.saveAssociationToken.respondToNext(with: .failure(apiError(status: 401)))
        await settle()

        XCTAssertEqual(coordinator.state, .linkAuthentication)
        XCTAssertEqual(
            linkSession.authenticateWithLinkUI.requestHistory,
            [.init(email: "handoff@example.com", phoneNumber: nil, mode: .save)]
        )
    }

    func testKeyRejectedAfterSigningInWithLinkFallsBack() async {
        makeCoordinator(handoff: makeHandoff())
        await startAndConfigure()
        apiClient.documentList.respondToNext(with: .failure(apiError(status: 403)))
        await settle()

        linkSession.authenticateWithLinkUI.respondToNext(with: .success(niAccount()))
        await settle()
        XCTAssertEqual(apiClient.documentList.requestHistory.last, .init(linkSessionKey: "lsk_session"))
        apiClient.documentList.respondToNext(with: .failure(apiError(status: 403)))
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(linkSession.authenticateWithLinkUI.requestHistory.count, 1)
    }

    func testOtherErrorsForTheHandedInKeyFallBack() async {
        makeCoordinator(handoff: makeHandoff())
        await startAndConfigure()

        apiClient.documentList.respondToNext(with: .failure(apiError(status: 500)))
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertTrue(linkSession.authenticateWithLinkUI.requestHistory.isEmpty)
    }

    func testSingleEligibleDocumentIsPreselectedButNotShared() async {
        await reachDocuments([niDocument(id: "doc_1")])

        XCTAssertEqual(coordinator.state, .selectDocument(documents: [niDocument(id: "doc_1")], selectedDocumentID: "doc_1"))
        XCTAssertTrue(apiClient.associationToken.requestHistory.isEmpty)
    }

    func testSeveralDocumentsNeedASelectionBeforeSharing() async {
        let documents = [niDocument(id: "doc_1"), niDocument(id: "doc_2")]
        await reachDocuments(documents)

        // Sharing does nothing until a document is selected
        coordinator.shareSelectedDocument()
        XCTAssertEqual(coordinator.state, .selectDocument(documents: documents, selectedDocumentID: nil))

        coordinator.selectDocument(niDocument(id: "doc_2"))

        XCTAssertEqual(coordinator.state, .selectDocument(documents: documents, selectedDocumentID: "doc_2"))
    }

    func testSharingAttachesTheSelectedDocumentAndWaitsForContinue() async {
        await reachDocuments([niDocument(id: "doc_1")])

        // When the user shares the preselected document
        coordinator.shareSelectedDocument()
        XCTAssertEqual(coordinator.state, .sharingDocument(niDocument(id: "doc_1")))
        await settle()
        XCTAssertEqual(apiClient.associationToken.requestHistory.first?.identityDocumentID, "doc_1")
        XCTAssertEqual(apiClient.associationToken.requestHistory.first?.verificationSessionID, "vs_target")
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1"])
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        // Then it waits for the user to continue
        XCTAssertEqual(coordinator.state, .documentShared(niDocument(id: "doc_1")))
        XCTAssertTrue(delegate.outcomes.isEmpty)

        coordinator.continueAfterSuccess()

        XCTAssertEqual(delegate.outcomes, [.documentShared])
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testNoEligibleDocumentsFallsBack() async {
        await reachDocuments([niDocument(id: "doc_1", liveCaptured: false)])

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
    }

    func testSaveSignsInWithLinksScreensThenPreparesTheSave() async {
        // Given the user starts saving
        makeCoordinator(config: makeConfig(route: .save, merchantEmail: "person@example.com"))
        await startAndConfigure(mode: .save)
        XCTAssertEqual(
            linkSession.authenticateWithLinkUI.requestHistory,
            [.init(email: "person@example.com", phoneNumber: nil, mode: .save)]
        )

        // When Link's screens verify the session
        await authenticate()

        // Then the save is prepared with the authenticated account
        XCTAssertEqual(
            apiClient.saveAssociationToken.requestHistory,
            [.init(verificationSessionID: "vs_target", linkSessionKey: "lsk_session")]
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

    func testClosingTheSheetWhileTheSaveIsWrittenLetsItFinish() async {
        // Given the save is being written
        makeCoordinator(config: makeConfig(route: .save))
        await startAndConfigure(mode: .save)
        await authenticate()
        apiClient.saveAssociationToken.respondToNext(with: .success(.init(associationToken: "save_token")))
        await settle()
        XCTAssertEqual(coordinator.state, .savePending)

        // When the user closes the sheet, the write can still commit, so it isn't abandoned
        coordinator.cancel()
        XCTAssertEqual(coordinator.state, .savePending)
        XCTAssertTrue(delegate.outcomes.isEmpty)

        actions.prepareDocumentSave.respondToNext(with: .success(niActionPageData()))
        await settle()
        XCTAssertEqual(coordinator.state, .savePrepared)
    }

    func testSavingARecordedSaveConfirmsItWithoutSavingAgain() async {
        // Given a save recorded before a submit that failed
        makeCoordinator(config: makeConfig(route: .resumeSave))

        coordinator.startSave()
        await settle()

        // Then it's confirmed without signing in or saving again
        XCTAssertEqual(coordinator.state, .savePrepared)
        XCTAssertTrue(linkSession.configure.requestHistory.isEmpty)
        XCTAssertTrue(apiClient.saveAssociationToken.requestHistory.isEmpty)
        coordinator.continueAfterSuccess()
        XCTAssertEqual(delegate.outcomes, [.savePrepared])
    }

    func testCancelReportsCancellation() async {
        await startAndConfigure()

        coordinator.cancel()
        await settle()

        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(delegate.outcomes, [.cancelled])
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
        await settle(until: { actions.skips.pendingRequestCount == 1 })
        actions.skips.respondToNext(with: .success(niActionPageData()))
        await settle()

        XCTAssertEqual(delegate.outcomes, [.manualCapture])
        XCTAssertEqual(actions.skips.requestHistory.count, 1)
    }

    func testRejectedAttachIsRetriedOnceWithAFreshToken() async {
        await reachDocuments([niDocument(id: "doc_1")])

        // When the first token is rejected and the session shows no attachment
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(apiError(status: 400)))
        await settle()
        XCTAssertEqual(actions.committedChecks.requestHistory, [.resumeReuse])
        actions.committedChecks.respondToNext(with: .success(nil))
        await settle()

        // Then a fresh token is minted and redeemed; the first one is never replayed
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_2")))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1", "token_2"])
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        XCTAssertEqual(coordinator.state, .documentShared(niDocument(id: "doc_1")))
        XCTAssertEqual(coordinator.route, .resumeReuse)
    }

    func testLostAttachResponseContinuesWhenTheSessionShowsTheAttachment() async {
        await reachDocuments([niDocument(id: "doc_1")])
        var recorded: StripeAPI.VerificationPageData?
        coordinator.onVerificationUpdate = { recorded = $0; return true }

        // When the attach response is lost but the session shows the document attached
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(URLError(.networkConnectionLost)))
        await settle()
        XCTAssertEqual(actions.committedChecks.requestHistory, [.resumeReuse])
        actions.committedChecks.respondToNext(with: .success(niActionPageData()))
        await settle()

        // Then the flow continues from the session state, without minting another token
        XCTAssertEqual(coordinator.state, .documentShared(niDocument(id: "doc_1")))
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertEqual(recorded, niActionPageData())
        XCTAssertEqual(coordinator.route, .resumeReuse)
    }

    func testLostAttachResponseFallsBackWhenTheSessionCannotBeReadBack() async {
        await reachDocuments([niDocument(id: "doc_1")])

        // When the attach response is lost and the session can't be read back
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(URLError(.networkConnectionLost)))
        await settle()
        XCTAssertEqual(actions.committedChecks.requestHistory, [.resumeReuse])
        actions.committedChecks.respondToNext(with: .failure(URLError(.networkConnectionLost)))
        await settle()

        // Then the flow falls back without minting another token, since the first attach may have committed
        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
    }

    func testAttachFailingTwiceFallsBack() async {
        await reachDocuments([niDocument(id: "doc_1")])

        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(apiError(status: 429)))
        await settle()
        actions.committedChecks.respondToNext(with: .success(nil))
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_2")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(URLError(.timedOut)))
        await settle()
        actions.committedChecks.respondToNext(with: .success(nil))
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1", "token_2"])
        XCTAssertEqual(actions.committedChecks.requestHistory, [.resumeReuse, .resumeReuse])
        XCTAssertTrue(actions.skips.requestHistory.isEmpty)
    }

    func testUnavailableNetworkedIdentityFallsBackWithoutRetrying() async {
        await reachDocuments([niDocument(id: "doc_1")])

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
        XCTAssertTrue(actions.committedChecks.requestHistory.isEmpty)
    }

    func testNonRetryableAttachErrorFallsBackWithoutRetrying() async {
        await reachDocuments([niDocument(id: "doc_1")])

        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        actions.attachDocument.respondToNext(with: .failure(apiError(status: 404)))
        await settle()

        XCTAssertEqual(coordinator.state, .fullCaptureFallback)
        XCTAssertEqual(apiClient.associationToken.requestHistory.count, 1)
        XCTAssertTrue(actions.committedChecks.requestHistory.isEmpty)
    }

    func testAttachmentTheHostRejectsFallsBackWithoutRetrying() async {
        // Given the host rejects the session's updates
        await reachDocuments([niDocument(id: "doc_1")])
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

        apiClient.saveAssociationToken.respondToNext(with: .success(.init(associationToken: "save_token")))
        await settle()
        actions.prepareDocumentSave.respondToNext(with: .failure(apiError(status: 502)))
        await settle()
        XCTAssertEqual(actions.committedChecks.requestHistory, [.resumeSave])
        actions.committedChecks.respondToNext(with: .success(niActionPageData()))
        await settle()

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
        await reachDocuments([niDocument(id: "doc_1")])
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        XCTAssertEqual(actions.attachDocument.requestHistory, ["token_1"])

        coordinator.chooseManualCapture()
        await settle()
        XCTAssertEqual(coordinator.state, .skipPending)
        XCTAssertTrue(actions.skips.requestHistory.isEmpty)
        XCTAssertTrue(delegate.outcomes.isEmpty)

        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle(until: { actions.skips.pendingRequestCount == 1 })
        actions.skips.respondToNext(with: .success(niActionPageData()))
        await settle()
        XCTAssertEqual(actions.skips.requestHistory.count, 1)
        XCTAssertEqual(delegate.outcomes, [.manualCapture])
        XCTAssertEqual(coordinator.route, .none)
        XCTAssertFalse(coordinator.entry.offersSave)
    }

    func testClosingDuringAnIssuedAttachmentStillUpdatesTheHostRequirements() async {
        await reachDocuments([niDocument(id: "doc_1")])
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
        XCTAssertEqual(delegate.routeChangeCount, 1)
        XCTAssertEqual(coordinator.route, .resumeReuse)
        XCTAssertEqual(coordinator.state, .cancelled)
        XCTAssertEqual(delegate.outcomes, [.cancelled])
    }

    func testReopeningLinkWaitsForThePreviousWriteBeforeAttachingAgain() async {
        await reachDocuments([niDocument(id: "doc_1")])
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        coordinator.cancel()

        coordinator.startReuse()
        await settle()
        apiClient.documentList.respondToNext(with: .success(.init(data: [niDocument(id: "doc_2")])))
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
        XCTAssertEqual(coordinator.state, .documentShared(niDocument(id: "doc_2")))
    }

    func testFailedSkipStillContinuesWithOrdinaryVerification() async {
        coordinator.chooseManualCapture()
        await settle(until: { actions.skips.pendingRequestCount == 1 })
        actions.skips.respondToNext(with: .failure(TestError.failed))
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

    func testDecliningSaveRecordsASkipAndStopsOfferingSave() async {
        makeCoordinator(config: makeConfig(route: .save))

        let decline = Task { await coordinator.declineSave() }
        await settle(until: { actions.skips.pendingRequestCount == 1 })
        actions.skips.respondToNext(with: .success(niActionPageData()))
        await decline.value

        XCTAssertFalse(coordinator.entry.offersSave)
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testAFailedSkipWhenDecliningSaveStillReturns() async {
        makeCoordinator(config: makeConfig(route: .save))

        let decline = Task { await coordinator.declineSave() }
        await settle(until: { actions.skips.pendingRequestCount == 1 })
        actions.skips.respondToNext(with: .failure(TestError.failed))
        await decline.value

        XCTAssertTrue(coordinator.entry.offersSave)
    }

    // MARK: - Entry

    func testAFoundSavedDocumentShowsTheChipWithTheProvidedEmail() {
        let entry = NetworkedIdentityEntry(
            config: makeConfig(merchantEmail: "person@example.com", savedDocumentAvailable: true),
            handoff: nil
        )

        XCTAssertTrue(entry.offersReuse)
        XCTAssertEqual(entry.savedIDEmail, "person@example.com")
    }

    func testAHandedInSessionsEmailIsUsedForTheChip() {
        let entry = NetworkedIdentityEntry(
            config: makeConfig(merchantEmail: "merchant@example.com", savedDocumentAvailable: true),
            handoff: makeHandoff()
        )

        XCTAssertEqual(entry.savedIDEmail, "person@example.com")
    }

    func testReuseCanBeTriedWithoutAFoundDocumentWithoutTheChip() {
        let entry = NetworkedIdentityEntry(config: makeConfig(merchantEmail: "person@example.com"), handoff: nil)

        XCTAssertTrue(entry.offersReuse)
        XCTAssertNil(entry.savedIDEmail)
    }

    func testWithoutAnEmailLinkIsOfferedWithoutTheChip() {
        let entry = NetworkedIdentityEntry(config: makeConfig(savedDocumentAvailable: true), handoff: nil)

        XCTAssertTrue(entry.offersReuse)
        XCTAssertNil(entry.savedIDEmail)
    }

    func testEntryWithoutPublishableKeyOffersNothing() {
        let entry = NetworkedIdentityEntry(
            config: makeConfig(merchantPublishableKey: nil, savedDocumentAvailable: true),
            handoff: makeHandoff()
        )

        XCTAssertFalse(entry.offersReuse || entry.offersSave)
        XCTAssertNil(entry.savedIDEmail)
    }

    func testSaveRouteOffersSaveWithoutTheChip() {
        let entry = NetworkedIdentityEntry(
            config: makeConfig(route: .save, merchantEmail: "person@example.com", savedDocumentAvailable: true),
            handoff: nil
        )

        XCTAssertFalse(entry.offersReuse)
        XCTAssertTrue(entry.offersSave)
        XCTAssertNil(entry.savedIDEmail)
    }

    func testSkippedAndResumedRoutesOfferNeitherReuseNorSave() {
        for route: NetworkedIdentityRoute in [.none, .resumeReuse, .resumeSave] {
            let entry = NetworkedIdentityEntry(config: makeConfig(route: route), handoff: makeHandoff())

            XCTAssertFalse(entry.offersReuse, "\(route)")
            XCTAssertFalse(entry.offersSave, "\(route)")
        }
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
        phoneNumberAutofillHint: String? = nil,
        savedDocumentAvailable: Bool = false
    ) -> NetworkedIdentityConfig {
        .init(
            route: route,
            saveEnabled: true,
            savedDocumentAvailable: savedDocumentAvailable,
            merchantPublishableKey: merchantPublishableKey,
            merchantEmail: merchantEmail,
            phoneNumberAutofillHint: phoneNumberAutofillHint
        )
    }

    func makeHandoff(email: String = "person@example.com") -> IdentityVerificationSheet.Configuration.LinkSessionHandoff {
        .init(
            email: email,
            linkSessionKey: "lsk_handoff"
        )
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

    /// Completes Link's sign-in screens with a verified account.
    func authenticate() async {
        linkSession.authenticateWithLinkUI.respondToNext(with: .success(niAccount()))
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
    private(set) var outcomes: [NetworkedIdentityOutcome] = []
    private(set) var routeChangeCount = 0

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    ) {}

    func networkedIdentityCoordinatorDidFinish(with outcome: NetworkedIdentityOutcome) {
        outcomes.append(outcome)
    }

    func networkedIdentityCoordinatorDidChangeRoute() {
        routeChangeCount += 1
    }
}

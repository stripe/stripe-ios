@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripeIdentity
import XCTest

@MainActor
final class NetworkedIdentityIntegrationTest: XCTestCase {
    func testUnavailableNetworkingWithMerchantKeyDoesNotOfferReuse() throws {
        let page = try makePage(networking: nil)
        let config = NetworkedIdentityConfig.from(page: page, overrides: nil)
        XCTAssertEqual(config.route, .none)
        let entry = NetworkedIdentityEntry(config: config, handoff: handoff)
        XCTAssertFalse(entry.offersReuse, "A bootstrap merchant key is not Networked Identity eligibility")
    }

    func testResumedSessionWithoutMissingFieldsSubmitsBeforeSuccess() async throws {
        for direction in ["consumer_to_merchant", "merchant_to_consumer"] {
            let page = try makeResumedPage(direction: direction)
            let flow = VerificationSheetFlowController(configuration: networkedIdentityConfiguration)
            let sheet = VerificationSheetControllerMock(flowController: flow)
            flow.nextViewController(
                skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
                sheetController: sheet
            ) { XCTAssertTrue($0 is LoadingViewController) }
            await settle()
            XCTAssertTrue(sheet.didSubmitResumedNetworkedIdentity)
        }
    }

    func testResumedSessionIsNotSubmittedWithoutNetworkedIdentity() async throws {
        // Given a session resumed from an earlier Networked Identity presentation
        let page = try makeResumedPage(direction: "consumer_to_merchant")

        // When Identity runs without Networked Identity
        let flow = VerificationSheetFlowController(configuration: .init(brandLogo: UIImage()))
        let sheet = VerificationSheetControllerMock(flowController: flow)
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) { XCTAssertTrue($0 is SuccessViewController) }
        await settle()

        // Then the ordinary flow continues without submitting on its behalf
        XCTAssertFalse(sheet.didSubmitResumedNetworkedIdentity)
    }

    func testSaveOnlyConsentScreenDoesNotLookUpTheProvidedEmail() async throws {
        // Given a session that only offers saving, with a provided email
        let link = NetworkedIdentityLinkSessionTestMock()
        let presenter = NetworkedIdentityPresenter(
            coordinator: makeCoordinator(
                route: .save, merchantEmail: "person@example.com", handoff: nil, link: link,
                api: NetworkedIdentityAPIClientTestMock(), actions: NetworkedIdentityActionsTestMock()
            ),
            includesSelfie: false
        )
        let page = try VerificationPageMock.response200.make()

        // When the consent screen opens
        let screen = try BiometricConsentViewController(
            brandLogo: UIImage(), showsStripeLogo: false, consentContent: page.biometricConsent,
            networkedIdentity: presenter, sheetController: VerificationSheetControllerMock()
        )
        await settle()

        // Then Link isn't set up to look up the email
        withExtendedLifetime(screen) {
            XCTAssertTrue(link.configure.requestHistory.isEmpty)
            XCTAssertTrue(link.lookup.requestHistory.isEmpty)
        }
    }

    func testSuccessScreenDoesNotLookUpTheProvidedEmail() async throws {
        // Given a session that offers saving, with a provided email
        let link = NetworkedIdentityLinkSessionTestMock()
        let presenter = NetworkedIdentityPresenter(
            coordinator: makeCoordinator(
                route: .reuse, merchantEmail: "person@example.com", handoff: nil, link: link,
                api: NetworkedIdentityAPIClientTestMock(), actions: NetworkedIdentityActionsTestMock()
            ),
            includesSelfie: false
        )

        // When the success screen offers saving
        let screen = SuccessViewController(
            successContent: try VerificationPageMock.response200.make().success,
            networkedIdentity: presenter,
            sheetController: VerificationSheetControllerMock()
        )
        await settle()

        // Then Link isn't set up to look up the email, which that screen doesn't show
        withExtendedLifetime(screen) {
            XCTAssertTrue(link.configure.requestHistory.isEmpty)
        }
    }

    func testIntroOffersOrdinaryConsentOnceAnAttachmentCommitsAfterLinkWasClosed() async throws {
        // Given the intro offers reuse for the handed-in account
        let link = NetworkedIdentityLinkSessionTestMock()
        let api = NetworkedIdentityAPIClientTestMock()
        let actions = NetworkedIdentityActionsTestMock()
        let presenter = NetworkedIdentityPresenter(
            coordinator: makeCoordinator(
                route: .reuse, merchantEmail: nil, handoff: handoff, link: link, api: api, actions: actions
            ),
            includesSelfie: false
        )
        let consent = try VerificationPageMock.response200.make().biometricConsent
        let screen = try BiometricConsentViewController(
            brandLogo: UIImage(), showsStripeLogo: false, consentContent: consent,
            networkedIdentity: presenter, sheetController: VerificationSheetControllerMock()
        )
        screen.scrolledToBottom = true
        let introTexts = visibleTexts(in: screen.view)
        XCTAssertTrue(introTexts.contains("Continue with Link"))
        XCTAssertTrue(introTexts.contains("Saved ID · person@example.com"))

        // ...and the user closed Link's sheet while a saved ID was being attached
        await reachDocuments(presenter.coordinator, link: link, api: api)
        presenter.coordinator.shareSelectedDocument()
        await settle()
        api.associationToken.respondToNext(with: .success(.init(associationToken: "token_1")))
        await settle()
        presenter.coordinator.cancel()

        // When the attachment commits
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        // Then the intro shows ordinary consent, without Link's buttons or the saved ID chip
        let texts = visibleTexts(in: screen.view)
        XCTAssertTrue(texts.contains(consent.acceptButtonText))
        XCTAssertFalse(texts.contains("Continue with Link"))
        XCTAssertFalse(texts.contains { $0.hasPrefix("Saved ID") })
    }

    func testIntroManualVerificationPersistsSkip() async throws {
        let page = try makePage(networking: [
            "save_available": true, "reuse_available": true,
            "state": ["consented": false, "skipped": false, "direction": NSNull()],
        ])
        let api = IdentityAPIClientTestMock()
        let flow = VerificationSheetFlowController(configuration: networkedIdentityConfiguration)
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let presenter = try XCTUnwrap(flow.networkedIdentityPresenter(staticContent: page, sheetController: sheet))
        let screen = try BiometricConsentViewController(
            brandLogo: UIImage(), showsStripeLogo: false, consentContent: page.biometricConsent,
            networkedIdentity: presenter, sheetController: sheet
        )
        screen.scrolledToBottom = true
        let button = try XCTUnwrap(screen.flowViewModel.buttons.first { $0.text == "Manually verify instead" })
        button.didTap()
        await settle()
        XCTAssertEqual(api.networkedIdentitySkip.requestHistory.count, 1)
        XCTAssertNil(sheet.savedData)
        api.networkedIdentitySkip.respondToNext(with: .success(niActionPageData(id: api.verificationSessionId)))
        await settle()
        XCTAssertEqual(sheet.savedData, .init(biometricConsent: true))
    }

    func testManualCapturePreventsPendingTokenFromAttachingLater() async {
        let link = NetworkedIdentityLinkSessionTestMock()
        let api = NetworkedIdentityAPIClientTestMock()
        let actions = NetworkedIdentityActionsTestMock()
        let coordinator = makeCoordinator(
            route: .reuse, merchantEmail: nil, handoff: handoff, link: link, api: api, actions: actions
        )
        await reachDocuments(coordinator, link: link, api: api)
        coordinator.shareSelectedDocument()
        await settle()
        coordinator.chooseManualCapture()
        await settle()
        XCTAssertEqual(actions.skipCount, 1)
        api.associationToken.respondToNext(with: .success(.init(associationToken: "late_token")))
        await settle()
        XCTAssertTrue(actions.attachDocument.requestHistory.isEmpty, "A late token must not start an attachment after skip")
        if actions.attachDocument.pendingRequestCount > 0 {
            actions.attachDocument.respondToNext(with: .success(niActionPageData()))
            await settle()
        }
        coordinator.abandon()
    }

    func testScreensShareOnePresenterUntilTheSheetIsPresentedAgain() throws {
        let flow = VerificationSheetFlowController(configuration: networkedIdentityConfiguration)
        let sheet = VerificationSheetControllerMock(flowController: flow)
        let page = try makePage(networking: [
            "save_available": true, "reuse_available": true,
            "state": ["consented": false, "skipped": false, "direction": NSNull()],
        ])
        let first = try XCTUnwrap(flow.networkedIdentityPresenter(staticContent: page, sheetController: sheet))
        let next = try XCTUnwrap(flow.networkedIdentityPresenter(
            staticContent: page.copyWithNewMissings(newMissings: []), sheetController: sheet
        ))
        XCTAssertTrue(first === next)
        XCTAssertTrue(first.coordinator === next.coordinator)

        flow.resetNetworkedIdentityForNewPresentation()

        XCTAssertEqual(first.coordinator.state, .cancelled)
        let reopened = try XCTUnwrap(flow.networkedIdentityPresenter(staticContent: page, sheetController: sheet))
        XCTAssertFalse(first === reopened)
    }

    func testSkippedAndResumedSessionsOfferNeitherReuseNorSave() throws {
        for state: [String: Any] in [
            ["consented": false, "skipped": true, "direction": NSNull()],
            ["consented": true, "skipped": false, "direction": "consumer_to_merchant"],
            ["consented": true, "skipped": false, "direction": "merchant_to_consumer"],
        ] {
            let page = try makePage(networking: ["save_available": true, "reuse_available": true, "state": state])
            let config = NetworkedIdentityConfig.from(page: page, overrides: nil)
            let entry = NetworkedIdentityEntry(config: config, handoff: handoff)
            XCTAssertFalse(entry.offersReuse)
            XCTAssertFalse(entry.offersSave)
        }
    }

    private var handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff {
        .init(email: "person@example.com", consumerSessionClientSecret: "session_secret", consumerPublishableKey: "pk_consumer")
    }

    private var networkedIdentityConfiguration: IdentityVerificationSheet.Configuration {
        var configuration = IdentityVerificationSheet.Configuration(brandLogo: UIImage())
        configuration.networkedIdentity = .init(
            linkSessionHandoff: handoff, debugMerchantPublishableKey: nil,
            debugProvidedEmail: nil, debugRoute: nil, debugSeedSavedDocuments: false
        )
        return configuration
    }

    private func makeResumedPage(direction: String) throws -> StripeAPI.VerificationPage {
        try makePage(networking: [
            "save_available": true, "reuse_available": true,
            "state": ["consented": true, "skipped": false, "direction": direction],
        ]).copyWithNewMissings(newMissings: [])
    }

    private func makePage(networking: [String: Any]?) throws -> StripeAPI.VerificationPage {
        var fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: VerificationPageMock.response200.data()) as? [String: Any])
        fixture["merchant_publishable_key"] = "pk_test_merchant"
        fixture["networked_identity"] = networking
        fixture["status"] = "requires_input"
        fixture["submitted"] = false
        return try StripeJSONDecoder().decode(StripeAPI.VerificationPage.self, from: JSONSerialization.data(withJSONObject: fixture))
    }

    private func makeCoordinator(
        route: NetworkedIdentityRoute,
        merchantEmail: String?,
        handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff?,
        link: NetworkedIdentityLinkSessionTestMock,
        api: NetworkedIdentityAPIClientTestMock,
        actions: NetworkedIdentityActionsTestMock
    ) -> NetworkedIdentityCoordinator {
        let coordinator = NetworkedIdentityCoordinator(
            linkSession: link, apiClient: api, actions: actions,
            documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false),
            config: .init(
                route: route, saveAvailable: true, merchantPublishableKey: "pk_test_merchant",
                merchantEmail: merchantEmail, phoneNumberAutofillHint: nil, seedSavedDocuments: false
            ),
            handoff: handoff, currentTime: { 1_800_000_000 }
        )
        coordinator.onVerificationUpdate = { _ in true }
        return coordinator
    }

    /// Starts reuse with the handed-in session and lists one saved document.
    private func reachDocuments(
        _ coordinator: NetworkedIdentityCoordinator,
        link: NetworkedIdentityLinkSessionTestMock,
        api: NetworkedIdentityAPIClientTestMock
    ) async {
        coordinator.startReuse()
        await settle()
        link.configure.respondToNext(with: .success(()))
        await settle()
        link.restore.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()
        api.documentList.respondToNext(with: .success(.init(data: [
            .init(id: "doc_1", documentType: .passport, created: 1_700_000_000,
                  country: "US", region: nil, redactedDocumentNumber: nil,
                  expirationDate: 1_900_000_000, liveCaptured: true),
        ])))
        await settle()
    }

    /// Texts of the labels the user can see.
    private func visibleTexts(in view: UIView) -> [String] {
        guard !view.isHidden else { return [] }
        return [(view as? UILabel)?.text].compactMap { $0 } + view.subviews.flatMap(visibleTexts(in:))
    }

    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
        try? await Task.sleep(nanoseconds: 5_000_000)
        for _ in 0..<20 { await Task.yield() }
    }
}

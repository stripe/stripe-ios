@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) @testable import StripeIdentity
import XCTest

@MainActor
final class NetworkedIdentityIntegrationTest: XCTestCase {
    func testUnavailableNetworkingWithMerchantKeyDoesNotOfferReuse() throws {
        let page = try makePage(networking: nil)
        let config = NetworkedIdentityConfig.from(page: page, options: nil)
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
            XCTAssertTrue(sheet.didSubmitAndTransition)
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
        XCTAssertFalse(sheet.didSubmitAndTransition)
    }

    func testFinishingCollectionOffersSavingInsteadOfSubmitting() async throws {
        // Given a session that offers saving the ID
        let (controller, flow, api) = makeVerification(page: try makePage(networking: [
            "save_enabled": true, "reuse_enabled": true,
            "state": ["consented": false, "skipped": false, "direction": NSNull()],
        ]))

        // When the last capture leaves nothing missing
        controller.saveAndTransition(from: .selfieCapture, collectedData: .init(), completion: {})
        api.verificationPageData.respondToRequests(with: .success(try VerificationPageDataMock.noErrors.make()))
        await settle()

        // Then saving is offered, and nothing is submitted yet
        XCTAssertTrue(flow.navigationController.viewControllers.last is NetworkedIdentitySaveViewController)
        XCTAssertTrue(api.verificationSessionSubmit.requestHistory.isEmpty)
    }

    func testFinishingCollectionSubmitsWhenSavingIsNotOffered() async throws {
        for (saveAvailable, state): (Bool, [String: Any]) in [
            // A saved ID was attached
            (true, ["consented": true, "skipped": false, "direction": "consumer_to_merchant"]),
            // The user chose to verify without Link
            (true, ["consented": false, "skipped": true, "direction": NSNull()]),
            // Saving isn't available
            (false, ["consented": false, "skipped": false, "direction": NSNull()]),
        ] {
            // Given a session that doesn't offer saving the ID
            let (controller, flow, api) = makeVerification(page: try makePage(networking: [
                "save_enabled": saveAvailable, "reuse_enabled": true, "state": state,
            ]))

            // When the last capture leaves nothing missing
            controller.saveAndTransition(from: .selfieCapture, collectedData: .init(), completion: {})
            api.verificationPageData.respondToRequests(with: .success(try VerificationPageDataMock.noErrors.make()))
            await settle()

            // Then the verification is submitted without offering to save
            XCTAssertEqual(api.verificationSessionSubmit.requestHistory.count, 1)
            XCTAssertFalse(flow.navigationController.viewControllers.last is NetworkedIdentitySaveViewController)
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
            "save_enabled": true, "reuse_enabled": true,
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
            "save_enabled": true, "reuse_enabled": true,
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
            let page = try makePage(networking: ["save_enabled": true, "reuse_enabled": true, "state": state])
            let config = NetworkedIdentityConfig.from(page: page, options: nil)
            let entry = NetworkedIdentityEntry(config: config, handoff: handoff)
            XCTAssertFalse(entry.offersReuse)
            XCTAssertFalse(entry.offersSave)
        }
    }

    private var handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff {
        .init(email: "person@example.com", linkSessionKey: "lsk_session")
    }

    private var networkedIdentityConfiguration: IdentityVerificationSheet.Configuration {
        var configuration = IdentityVerificationSheet.Configuration(brandLogo: UIImage())
        configuration.networkedIdentity = .init(
            linkSessionHandoff: handoff, debugMerchantPublishableKey: nil,
            debugProvidedEmail: nil, debugRoute: nil, debugSeedSavedDocuments: false
        )
        return configuration
    }

    private func makeVerification(
        page: StripeAPI.VerificationPage
    ) -> (VerificationSheetController, VerificationSheetFlowController, IdentityAPIClientTestMock) {
        let api = IdentityAPIClientTestMock()
        let flow = VerificationSheetFlowController(configuration: networkedIdentityConfiguration)
        let controller = VerificationSheetController(
            apiClient: api, flowController: flow, mlModelLoader: IdentityMLModelLoaderMock(),
            analyticsClient: .init(verificationSessionId: "", analyticsClient: MockAnalyticsClientV2())
        )
        controller.verificationPageResponse = .success(page)
        // The navigation stack only follows animated transitions in a window.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = flow.navigationController
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        return (controller, flow, api)
    }

    private func makeResumedPage(direction: String) throws -> StripeAPI.VerificationPage {
        try makePage(networking: [
            "save_enabled": true, "reuse_enabled": true,
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
                // The intro shows the "Saved ID" chip for the handed-in account.
                route: route, saveEnabled: true, savedDocumentAvailable: true, merchantPublishableKey: "pk_test_merchant",
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
        api.documentList.respondToNext(with: .success(.init(data: [niDocument(redactedDocumentNumber: nil)])))
        await settle()
    }

    /// Texts of the labels the user can see.
    private func visibleTexts(in view: UIView) -> [String] {
        guard !view.isHidden else { return [] }
        return [(view as? UILabel)?.text].compactMap { $0 } + view.subviews.flatMap(visibleTexts(in:))
    }
}

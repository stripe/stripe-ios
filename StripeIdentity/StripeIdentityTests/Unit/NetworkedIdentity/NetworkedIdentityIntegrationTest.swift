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
            let page = try makePage(networking: [
                "save_available": true, "reuse_available": true,
                "state": ["consented": true, "skipped": false, "direction": direction],
            ]).copyWithNewMissings(newMissings: [])
            let api = IdentityAPIClientTestMock()
            api.supportsNetworkedIdentity = true
            let flow = VerificationSheetFlowController(configuration: .init(brandLogo: UIImage()))
            let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
            flow.nextViewController(
                skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
                sheetController: sheet
            ) { XCTAssertTrue($0 is LoadingViewController) }
            await settle()
            let continued = try XCTUnwrap(sheet.networkedIdentityResult).get()
            XCTAssertTrue(continued.requirements.missing.isEmpty)
            XCTAssertFalse(continued.submitted)
        }
    }

    func testIntroManualVerificationPersistsSkip() async throws {
        let page = try makePage(networking: [
            "save_available": true, "reuse_available": true,
            "state": ["consented": false, "skipped": false, "direction": NSNull()],
        ])
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        let sheet = VerificationSheetControllerMock(apiClient: api)
        let presenter = NetworkedIdentityPresenter(
            options: .init(linkSessionHandoff: handoff, debugMerchantPublishableKey: nil,
                           debugProvidedEmail: nil, debugRoute: nil, debugSeedSavedDocuments: false),
            verificationPage: page, identityAPIClient: api
        )
        let screen = try BiometricConsentViewController(
            brandLogo: UIImage(), showsStripeLogo: false, consentContent: page.biometricConsent,
            networkedIdentity: presenter, sheetController: sheet
        )
        screen.scrolledToBottom = true
        let button = try XCTUnwrap(screen.flowViewModel.buttons.first { $0.text == "Manually verify instead" })
        button.didTap()
        await settle()
        XCTAssertEqual(api.networkedIdentitySkip.requestHistory.count, 1)
        XCTAssertNil(sheet.networkedIdentityConsentUpdate)
        api.networkedIdentitySkip.respondToNext(with: .success(niActionPageData(id: api.verificationSessionId)))
        await settle()
        XCTAssertEqual(sheet.networkedIdentityConsentUpdate, niActionPageData(id: api.verificationSessionId))
    }

    func testManualCapturePreventsPendingTokenFromAttachingLater() async {
        let link = NetworkedIdentityLinkSessionTestMock()
        let api = NetworkedIdentityAPIClientTestMock()
        let actions = NetworkedIdentityActionsTestMock()
        let coordinator = NetworkedIdentityCoordinator(
            linkSession: link, apiClient: api, actions: actions,
            documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false),
            config: .init(route: .reuse, saveAvailable: true, merchantPublishableKey: "pk_test_merchant", merchantEmail: nil, seedSavedDocuments: false),
            handoff: handoff, currentTime: { 1_800_000_000 }
        )
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
        var configuration = IdentityVerificationSheet.Configuration(brandLogo: UIImage())
        configuration.networkedIdentity = .init(
            linkSessionHandoff: handoff, debugMerchantPublishableKey: nil,
            debugProvidedEmail: nil, debugRoute: nil, debugSeedSavedDocuments: false
        )
        let flow = VerificationSheetFlowController(configuration: configuration)
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

    func testSkippedAndResumedSessionsDoNotOfferNewReuse() throws {
        for state: [String: Any] in [
            ["consented": false, "skipped": true, "direction": NSNull()],
            ["consented": true, "skipped": false, "direction": "consumer_to_merchant"],
            ["consented": true, "skipped": false, "direction": "merchant_to_consumer"],
        ] {
            let page = try makePage(networking: ["save_available": true, "reuse_available": true, "state": state])
            let config = NetworkedIdentityConfig.from(page: page, overrides: nil)
            let entry = NetworkedIdentityEntry(config: config, handoff: handoff)
            XCTAssertFalse(entry.offersReuse)
            XCTAssertEqual(entry.offersSave, config.route == .resumeSave)
        }
    }

    private var handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff {
        .init(email: "person@example.com", consumerSessionClientSecret: "session_secret", consumerPublishableKey: "pk_consumer")
    }

    private func makePage(networking: [String: Any]?) throws -> StripeAPI.VerificationPage {
        var fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: VerificationPageMock.response200.data()) as? [String: Any])
        fixture["merchant_publishable_key"] = "pk_test_merchant"
        fixture["networked_identity"] = networking
        fixture["status"] = "requires_input"
        fixture["submitted"] = false
        return try StripeJSONDecoder().decode(StripeAPI.VerificationPage.self, from: JSONSerialization.data(withJSONObject: fixture))
    }

    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
        try? await Task.sleep(nanoseconds: 5_000_000)
        for _ in 0..<20 { await Task.yield() }
    }
}

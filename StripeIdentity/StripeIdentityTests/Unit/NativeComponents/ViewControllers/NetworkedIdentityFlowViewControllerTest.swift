//
//  NetworkedIdentityFlowViewControllerTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeUICore
import UIKit
import XCTest

@testable import StripeIdentity

@MainActor
final class NetworkedIdentityFlowViewControllerTest: XCTestCase {
    private typealias Copy = NetworkedIdentityFlowViewController.Copy

    private var linkSession: NetworkedIdentityLinkSessionTestMock!
    private var apiClient: NetworkedIdentityAPIClientTestMock!
    private var actions: NetworkedIdentityActionsTestMock!
    private var coordinator: NetworkedIdentityCoordinator!
    private var viewController: NetworkedIdentityFlowViewController!
    private var linkUIHost: UIViewController!

    override func setUp() {
        super.setUp()
        linkSession = NetworkedIdentityLinkSessionTestMock()
        apiClient = NetworkedIdentityAPIClientTestMock()
        actions = NetworkedIdentityActionsTestMock()
        coordinator = NetworkedIdentityCoordinator(
            linkSession: linkSession,
            apiClient: apiClient,
            actions: actions,
            documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false),
            config: .init(
                route: .reuse,
                saveEnabled: true,
                savedDocumentAvailable: false,
                merchantPublishableKey: "pk_test_merchant",
                merchantEmail: nil,
                phoneNumberAutofillHint: nil
            ),
            handoff: nil,
            currentTime: { 1_800_000_000 }
        )
        viewController = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: false)
        linkUIHost = UIViewController()
        coordinator.delegate = self
        coordinator.linkUIHost = linkUIHost
        coordinator.onVerificationUpdate = { _ in true }
        viewController.loadViewIfNeeded()
    }

    func testDocumentStepThenSharedStep() async {
        // Given the user signed in with Link's screens and has a saved document
        await signIn()
        XCTAssertEqual(viewController.visibleStep, .progress)
        apiClient.documentList.respondToNext(with: .success(.init(data: [niDocument()])))
        await settle()
        XCTAssertEqual(viewController.visibleStep, .documents)

        // When the document is shared
        coordinator.shareSelectedDocument()
        await settle()
        apiClient.associationToken.respondToNext(with: .success(.init(associationToken: "token")))
        await settle()
        actions.attachDocument.respondToNext(with: .success(niActionPageData()))
        await settle()

        // Then the shared confirmation is shown
        XCTAssertEqual(viewController.visibleStep, .documentShared)
    }

    func testManualCaptureIsNotOfferedWhileSharing() async {
        // Given the user can share a saved ID or verify manually
        await signInAndListDocuments()
        XCTAssertEqual(visibleButtonTitles, [Copy.share, Copy.manualCapture])

        // When they share it
        coordinator.shareSelectedDocument()

        // Then only the pending share remains
        XCTAssertEqual(coordinator.state, .sharingDocument(niDocument()))
        XCTAssertEqual(visibleButtonTitles, [Copy.share])

        // Finish the pending request so the attempt doesn't outlive the test
        await settle()
        apiClient.associationToken.respondToNext(with: .failure(URLError(.notConnectedToInternet)))
        await settle()
    }

    func testManualCaptureIsNotOfferedAgainWhileSkipping() async {
        // Given the user can share a saved ID or verify manually
        await signInAndListDocuments()

        // When they choose to verify manually
        coordinator.chooseManualCapture()

        // Then nothing more is offered while the choice is recorded
        XCTAssertEqual(coordinator.state, .skipPending)
        XCTAssertEqual(visibleButtonTitles, [])
    }

    func testSavingIsTitledContinueWithLink() {
        // When the save is being recorded
        viewController.render(.savePending)

        // Then the progress is titled "Continue with Link"
        XCTAssertTrue(visibleTexts.contains("Continue with Link"))
        XCTAssertTrue(visibleTexts.contains("Saving your ID…"))
    }

    func testSavedStepNamesTheSelfieOnlyWhenTheVerificationHasOne() {
        for (includesSelfie, title, body) in [
            (false, "ID saved", "It's encrypted and ready to reuse with your Link wallet."),
            (true, "ID and selfie saved", "They are encrypted and ready to reuse with your Link wallet."),
        ] {
            // Given the sheet of a verification with or without a selfie
            viewController = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: includesSelfie)
            viewController.loadViewIfNeeded()

            // When the save is prepared
            viewController.render(.savePrepared)

            // Then it names what was saved
            XCTAssertTrue(visibleTexts.contains(title))
            XCTAssertTrue(visibleTexts.contains(body))
            XCTAssertEqual(visibleButtonTitles, [Copy.done])
        }
    }
}

private extension NetworkedIdentityFlowViewControllerTest {
    /// Titles of the buttons the user can see.
    var visibleButtonTitles: [String?] {
        func buttons(in view: UIView) -> [Button] {
            guard !view.isHidden else {
                return []
            }
            if let button = view as? Button {
                return [button]
            }
            return view.subviews.flatMap(buttons(in:))
        }
        return buttons(in: viewController.view).map(\.title)
    }

    /// Texts of the labels the user can see.
    var visibleTexts: [String] {
        func texts(in view: UIView) -> [String] {
            guard !view.isHidden else {
                return []
            }
            return [(view as? UILabel)?.text].compactMap { $0 } + view.subviews.flatMap(texts(in:))
        }
        return texts(in: viewController.view)
    }

    func signIn() async {
        coordinator.startReuse()
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        linkSession.authenticateWithLinkUI.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()
    }

    func signInAndListDocuments() async {
        await signIn()
        apiClient.documentList.respondToNext(with: .success(.init(data: [niDocument()])))
        await settle()
    }
}

extension NetworkedIdentityFlowViewControllerTest: NetworkedIdentityCoordinatorDelegate {
    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    ) {
        viewController.render(state)
    }

    func networkedIdentityCoordinatorDidFinish(with outcome: NetworkedIdentityOutcome) {}

    func networkedIdentityCoordinatorDidChangeRoute() {}
}

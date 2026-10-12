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
                saveAvailable: true,
                merchantPublishableKey: "pk_test_merchant",
                merchantEmail: nil,
                phoneNumberAutofillHint: nil,
                seedSavedDocuments: false
            ),
            handoff: nil,
            currentTime: { 1_800_000_000 }
        )
        viewController = NetworkedIdentityFlowViewController(coordinator: coordinator)
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
        apiClient.documentList.respondToNext(with: .success(.init(data: [makeDocument()])))
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
        XCTAssertEqual(coordinator.state, .sharingDocument(makeDocument()))
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
        apiClient.documentList.respondToNext(with: .success(.init(data: [makeDocument()])))
        await settle()
    }

    func makeDocument() -> NetworkedIdentityDocument {
        .init(
            id: "doc_1",
            documentType: .passport,
            created: 1_700_000_000,
            country: "US",
            region: nil,
            redactedDocumentNumber: "•••• 1234",
            expirationDate: 1_900_000_000,
            liveCaptured: true
        )
    }

    func settle() async {
        for _ in 0..<20 {
            await Task.yield()
        }
        try? await Task.sleep(nanoseconds: 5_000_000)
        for _ in 0..<20 {
            await Task.yield()
        }
    }
}

extension NetworkedIdentityFlowViewControllerTest: NetworkedIdentityCoordinatorDelegate {
    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    ) {
        viewController.render(state)
    }

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didFinishWith outcome: NetworkedIdentityOutcome
    ) {}

    func networkedIdentityCoordinatorDidChangeRoute(_ coordinator: NetworkedIdentityCoordinator) {}
}

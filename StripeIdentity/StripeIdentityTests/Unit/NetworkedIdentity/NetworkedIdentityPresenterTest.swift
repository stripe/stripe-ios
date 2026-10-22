//
//  NetworkedIdentityPresenterTest.swift
//  StripeIdentityTests
//

import UIKit
import XCTest

@testable import StripeIdentity

@MainActor
final class NetworkedIdentityPresenterTest: XCTestCase {
    private var linkSession: NetworkedIdentityLinkSessionTestMock!
    private var apiClient: NetworkedIdentityAPIClientTestMock!
    private var presenter: NetworkedIdentityPresenter!
    private var host: PresentationRecordingViewController!
    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        linkSession = NetworkedIdentityLinkSessionTestMock()
        apiClient = NetworkedIdentityAPIClientTestMock()
        presenter = NetworkedIdentityPresenter(
            coordinator: NetworkedIdentityCoordinator(
                linkSession: linkSession,
                apiClient: apiClient,
                actions: NetworkedIdentityActionsTestMock(),
                documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false),
                config: .init(
                    route: .reuse,
                    saveEnabled: true,
                    savedDocumentAvailable: false,
                    merchantPublishableKey: "pk_test_merchant",
                    merchantEmail: nil,
                    phoneNumberAutofillHint: nil,
                    seedSavedDocuments: false
                ),
                handoff: nil,
                currentTime: { 1_800_000_000 }
            ),
            includesSelfie: false
        )
        host = PresentationRecordingViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        presenter.end()
        window.isHidden = true
        super.tearDown()
    }

    func testSheetStaysHiddenWhileLinksScreensSignTheUserIn() async {
        // When the user starts
        presenter.startReuse(from: host) { _ in }

        // Then nothing is shown while Link is prepared
        XCTAssertEqual(presenter.coordinator.state, .preparing)
        XCTAssertTrue(host.presented.isEmpty)

        // ...or while Link's own screens sign the user in
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        XCTAssertEqual(presenter.coordinator.state, .linkAuthentication)
        XCTAssertTrue(host.presented.isEmpty)
    }

    func testSheetIsShownOnceSignedInAndUpdatedInPlace() async throws {
        // When Link's own screens sign the user in
        await signIn()

        // Then Identity's sheet shows the saved IDs loading
        XCTAssertEqual(presenter.coordinator.state, .documentsPending)
        XCTAssertEqual(host.presented.count, 1)
        let flow = try XCTUnwrap(flowViewController(in: host.presented[0]))
        XCTAssertEqual(flow.visibleStep, .progress)

        // ...and the same sheet shows them once they load
        apiClient.documentList.respondToNext(with: .success(.init(data: [niDocument()])))
        await settle()
        XCTAssertEqual(host.presented.count, 1)
        XCTAssertEqual(flow.visibleStep, .documents)
    }

    func testClosingDismissesTheSheet() async throws {
        // Given Identity's sheet is shown
        await signIn()
        let closedFlow = try XCTUnwrap(host.presented.first.flatMap(flowViewController(in:)))

        // When the user closes it and starts again
        presenter.coordinator.cancel()
        presenter.startReuse(from: host) { _ in }
        await settle()

        // Then a new sheet is presented, and the closed one no longer follows the attempt
        XCTAssertEqual(presenter.coordinator.state, .documentsPending)
        XCTAssertEqual(host.presented.count, 2)
        XCTAssertFalse(host.presented[0] === host.presented[1])
        XCTAssertEqual(closedFlow.visibleStep, .progress)
    }
}

/// Records presentations. Unhosted unit tests never finish a UIKit presentation, so `presentedViewController`
/// can't show a dismissal.
private final class PresentationRecordingViewController: UIViewController {
    private(set) var presented: [UIViewController] = []

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presented.append(viewControllerToPresent)
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

private extension NetworkedIdentityPresenterTest {
    func signIn() async {
        presenter.startReuse(from: host) { _ in }
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        linkSession.authenticateWithLinkUI.respondToNext(with: .success(niAccount(isVerified: true)))
        await settle()
    }

    func flowViewController(in viewController: UIViewController) -> NetworkedIdentityFlowViewController? {
        (viewController as? NetworkedIdentityFlowViewController)
            ?? viewController.children.lazy.compactMap { self.flowViewController(in: $0) }.first
    }
}

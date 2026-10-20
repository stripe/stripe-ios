//
//  NetworkedIdentityFlowViewControllerSnapshotTest.swift
//  StripeIdentityTests
//

import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable import StripeIdentity

@MainActor
final class NetworkedIdentityFlowViewControllerSnapshotTest: STPSnapshotTestCase {
    private static let snapshotFrame = CGRect(x: 0, y: 0, width: 375, height: 812)

    private let drivingLicense = niDocument(
        id: "id_doc_license",
        documentType: .drivingLicense,
        redactedDocumentNumber: "•••• 4242"
    )
    private let passport = niDocument(id: "id_doc_passport", redactedDocumentNumber: "•••• 6789")
    private lazy var viewController: NetworkedIdentityFlowViewController = {
        let coordinator = NetworkedIdentityCoordinator(
            linkSession: NetworkedIdentityLinkSessionTestMock(),
            apiClient: NetworkedIdentityAPIClientTestMock(),
            actions: NetworkedIdentityActionsTestMock(),
            documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false),
            config: .init(
                route: .reuse,
                saveEnabled: true,
                savedDocumentAvailable: false,
                merchantPublishableKey: "pk_test_merchant",
                merchantEmail: nil,
                phoneNumberAutofillHint: nil
            ),
            handoff: nil
        )
        let viewController = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: false)
        viewController.loadViewIfNeeded()
        return viewController
    }()
    private lazy var navigationController = UINavigationController(rootViewController: viewController)
    private lazy var window: UIWindow = {
        let window = UIWindow(frame: Self.snapshotFrame)
        window.rootViewController = navigationController
        window.isHidden = false
        return window
    }()

    func testSelectedSavedDocument() {
        // When a verified consumer with two reusable documents selects their passport
        viewController.render(.selectDocument(documents: [drivingLicense, passport], selectedDocumentID: passport.id))

        // Then the selected state is visible in the saved-document list
        verifyView()
    }

    func testAttachingSavedDocument() {
        // When the selected document is being shared
        viewController.render(.sharingDocument(passport))

        // Then the screen cannot submit another action while attachment is pending
        verifyView()
    }

    func testSaveFailed() {
        // When the save token can't be created
        viewController.render(.saveFailed(details: "The request could not be completed. (resource_missing)"))

        // Then the failure stays on screen with its details
        verifyView()
    }

    func testSavePrepared() {
        // When the save is prepared
        viewController.render(.savePrepared)

        // Then the confirmation is shown in Link's style
        verifyView()
    }
}

private extension NetworkedIdentityFlowViewControllerSnapshotTest {
    func verifyView(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        _ = window
        window.layoutIfNeeded()
        navigationController.view.layoutIfNeeded()
        XCTAssertEqual(navigationController.view.bounds, Self.snapshotFrame)
        STPSnapshotVerifyView(navigationController.view, file: file, line: line)
    }
}

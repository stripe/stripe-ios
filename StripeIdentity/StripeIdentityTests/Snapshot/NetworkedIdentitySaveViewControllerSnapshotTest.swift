//
//  NetworkedIdentitySaveViewControllerSnapshotTest.swift
//  StripeIdentityTests
//

import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable import StripeIdentity

@MainActor
final class NetworkedIdentitySaveViewControllerSnapshotTest: STPSnapshotTestCase {
    func testSaveOffer() {
        let presenter = NetworkedIdentityPresenter(
            coordinator: NetworkedIdentityCoordinator(
                linkSession: NetworkedIdentityLinkSessionTestMock(),
                apiClient: NetworkedIdentityAPIClientTestMock(),
                actions: NetworkedIdentityActionsTestMock(),
                documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false),
                config: .init(
                    route: .save,
                    saveEnabled: true,
                    savedDocumentAvailable: false,
                    merchantPublishableKey: "pk_test_merchant",
                    merchantEmail: nil,
                    phoneNumberAutofillHint: nil
                ),
                handoff: nil
            ),
            includesSelfie: true
        )
        let viewController = NetworkedIdentitySaveViewController(
            networkedIdentity: presenter,
            sheetController: VerificationSheetControllerMock()
        )

        STPSnapshotVerifyView(viewController.view)
    }
}

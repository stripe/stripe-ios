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
    private typealias Strings = NetworkedIdentityFlowViewController.Strings

    private var coordinator: NetworkedIdentityCoordinator!
    private var viewController: NetworkedIdentityFlowViewController!

    override func setUp() {
        super.setUp()
        coordinator = NetworkedIdentityCoordinator(
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
            handoff: nil,
            currentTime: { 1_800_000_000 }
        )
        viewController = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: false)
        viewController.loadViewIfNeeded()
    }

    func testSharedStepConfirmsTheShareAndOffersContinue() {
        // When the saved ID was shared
        viewController.render(.documentShared(niDocument()))

        // Then the confirmation is shown with a way to continue
        XCTAssertTrue(visibleTexts.contains(Strings.sharedTitle))
        XCTAssertEqual(visibleButtonTitles, [Strings.continueButton])
    }

    func testManualCaptureIsNotOfferedWhileSharing() {
        // Given the user can share a saved ID or verify manually
        viewController.render(.selectDocument(documents: [niDocument()], selectedDocumentID: niDocument().id))
        XCTAssertEqual(visibleButtonTitles, [Strings.share, Strings.manualCapture])

        // When they share it
        viewController.render(.sharingDocument(niDocument()))

        // Then only the pending share remains
        XCTAssertEqual(visibleButtonTitles, [Strings.share])
    }

    func testManualCaptureIsNotOfferedAgainWhileSkipping() {
        // Given the user can share a saved ID or verify manually
        viewController.render(.selectDocument(documents: [niDocument()], selectedDocumentID: niDocument().id))
        XCTAssertEqual(visibleButtonTitles, [Strings.share, Strings.manualCapture])

        // When they choose to verify manually
        viewController.render(.skipPending)

        // Then nothing more is offered while the choice is recorded
        XCTAssertEqual(visibleButtonTitles, [])
    }

    func testSavingIsTitledContinueWithLink() {
        // When the save is being recorded
        viewController.render(.savePending)

        // Then the progress is titled "Continue with Link"
        XCTAssertTrue(visibleTexts.contains("Continue with Link"))
        XCTAssertTrue(visibleTexts.contains("Saving your ID…"))
    }

    func testSavedStepNamesTheID() {
        // When the save of a verification without a selfie is prepared
        viewController.render(.savePrepared)

        // Then it names the ID
        XCTAssertTrue(visibleTexts.contains("ID saved"))
        XCTAssertTrue(visibleTexts.contains("It's encrypted and ready to reuse with your Link wallet."))
        XCTAssertEqual(visibleButtonTitles, [Strings.done])
    }

    func testSavedStepNamesTheSelfieWhenTheVerificationHasOne() {
        // Given the sheet of a verification with a selfie
        viewController = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: true)
        viewController.loadViewIfNeeded()

        // When the save is prepared
        viewController.render(.savePrepared)

        // Then it names the ID and the selfie
        XCTAssertTrue(visibleTexts.contains("ID and selfie saved"))
        XCTAssertTrue(visibleTexts.contains("They are encrypted and ready to reuse with your Link wallet."))
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
}

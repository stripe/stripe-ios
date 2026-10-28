//
//  NetworkedIdentitySaveViewControllerTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeUICore
import UIKit
import XCTest

@testable import StripeIdentity

@MainActor
final class NetworkedIdentitySaveViewControllerTest: XCTestCase {
    private var linkSession: NetworkedIdentityLinkSessionTestMock!
    private var apiClient: NetworkedIdentityAPIClientTestMock!
    private var actions: NetworkedIdentityActionsTestMock!
    private var sheetController: VerificationSheetControllerMock!
    private var presenter: NetworkedIdentityPresenter!
    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        linkSession = NetworkedIdentityLinkSessionTestMock()
        apiClient = NetworkedIdentityAPIClientTestMock()
        actions = NetworkedIdentityActionsTestMock()
        sheetController = VerificationSheetControllerMock()
        window = UIWindow(frame: UIScreen.main.bounds)
    }

    override func tearDown() {
        presenter?.end()
        window.isHidden = true
        super.tearDown()
    }

    func testCopyNamesTheID() {
        // When the save offer of a verification without a selfie is shown
        let screen = makeScreen(includesSelfie: false)

        // Then it names the ID
        let texts = visibleTexts(in: screen.view)
        XCTAssertTrue(texts.contains("Save your ID with Link."))
        XCTAssertTrue(texts.contains("Save your ID for the next time you need to verify."))
    }

    func testCopyNamesTheSelfieWhenTheVerificationHasOne() {
        // When the save offer of a verification with a selfie is shown
        let screen = makeScreen(includesSelfie: true)

        // Then it names the ID and the selfie
        let texts = visibleTexts(in: screen.view)
        XCTAssertTrue(texts.contains("Save your ID and selfie with Link."))
        XCTAssertTrue(texts.contains("Save your ID and selfie for the next time you need to verify."))
    }

    func testFinishingWithoutSavingRecordsTheDeclineThenSubmits() async {
        // Given the save offer
        let screen = makeScreen(includesSelfie: false)

        // When the user finishes without saving
        screen.flowViewModel.buttons.first { $0.text == "Finish without saving" }?.didTap()
        await settle(until: { actions.skips.pendingRequestCount == 1 })

        // Then nothing is submitted while the decline is recorded, since a submitted verification takes no more writes
        XCTAssertTrue(sheetController.submitAndTransitionCompletions.isEmpty)
        actions.skips.respondToNext(with: .success(niActionPageData()))
        await settle(until: { !sheetController.submitAndTransitionCompletions.isEmpty })

        // ...and the verification is submitted once it is, without starting Link
        XCTAssertEqual(sheetController.submitAndTransitionCompletions.count, 1)
        XCTAssertEqual(sheetController.analyticsClient.timeToScreenFromScreen, .networkedIdentitySave)
        XCTAssertTrue(linkSession.configure.requestHistory.isEmpty)
    }

    func testChoicesAreDisabledWhileASaveIsInProgress() async {
        // Given the user started saving
        let screen = makeScreen(includesSelfie: false)
        tapSave(on: screen)

        // Then neither choice can be made while Link is prepared, or while its own screens are shown
        XCTAssertEqual(presenter.coordinator.state, .preparing)
        XCTAssertEqual(buttons(in: screen.view).map(\.isEnabled), [false, false])
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        XCTAssertEqual(presenter.coordinator.state, .linkAuthentication)
        XCTAssertEqual(buttons(in: screen.view).map(\.isEnabled), [false, false])

        // ...until the attempt ends, which submits nothing
        linkSession.authenticateWithLinkUI.respondToNext(with: .success(nil))
        await settle()
        XCTAssertEqual(buttons(in: screen.view).map(\.isEnabled), [true, true])
        XCTAssertTrue(sheetController.submitAndTransitionCompletions.isEmpty)
    }

    func testARecordedSaveCantBeFinishedWithoutSaving() {
        // Given a save recorded before a submit that failed
        let screen = makeScreen(includesSelfie: false, route: .resumeSave)

        // Then only saving is offered, since finishing would still save the ID
        let buttons = buttons(in: screen.view)
        XCTAssertEqual(buttons.map(\.accessibilityLabel), ["Save with Link"])
        XCTAssertTrue(buttons.allSatisfy { sequence(first: $0 as UIView, next: \.superview).allSatisfy { !$0.isHidden } })
    }

    func testDoneAfterSavingSubmits() async {
        // Given the user saved their ID with Link
        await saveID(on: makeScreen(includesSelfie: false))
        XCTAssertTrue(sheetController.submitAndTransitionCompletions.isEmpty)

        // When they tap Done
        presenter.coordinator.continueAfterSuccess()

        // Then the verification is submitted
        XCTAssertEqual(sheetController.submitAndTransitionCompletions.count, 1)
    }

    func testClosingLinksSheetAfterSavingSubmits() async {
        // Given the user saved their ID with Link
        await saveID(on: makeScreen(includesSelfie: false))

        // When they close Link's sheet instead of tapping Done
        presenter.coordinator.cancel()

        // Then the verification is submitted, since saving can't be offered again
        XCTAssertEqual(sheetController.submitAndTransitionCompletions.count, 1)
    }
}

private extension NetworkedIdentitySaveViewControllerTest {
    func makeScreen(includesSelfie: Bool, route: NetworkedIdentityRoute = .save) -> NetworkedIdentitySaveViewController {
        presenter = NetworkedIdentityPresenter(
            coordinator: NetworkedIdentityCoordinator(
                linkSession: linkSession,
                apiClient: apiClient,
                actions: actions,
                documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false),
                config: .init(
                    route: route,
                    saveEnabled: true,
                    savedDocumentAvailable: false,
                    merchantPublishableKey: "pk_test_merchant",
                    merchantEmail: nil,
                    phoneNumberAutofillHint: nil
                ),
                handoff: nil,
                currentTime: { 1_800_000_000 }
            ),
            includesSelfie: includesSelfie
        )
        presenter.coordinator.onVerificationUpdate = { _ in true }
        let screen = NetworkedIdentitySaveViewController(networkedIdentity: presenter, sheetController: sheetController)
        window.rootViewController = UINavigationController(rootViewController: screen)
        window.makeKeyAndVisible()
        return screen
    }

    /// Signs in with Link's screens; the save token is then requested.
    func signIn() async {
        await settle()
        linkSession.configure.respondToNext(with: .success(()))
        await settle()
        linkSession.authenticateWithLinkUI.respondToNext(with: .success(niAccount()))
        await settle()
    }

    func saveID(on screen: UIViewController) async {
        tapSave(on: screen)
        await signIn()
        apiClient.saveAssociationToken.respondToNext(with: .success(.init(associationToken: "save_token")))
        await settle()
        actions.prepareDocumentSave.respondToNext(with: .success(niActionPageData()))
        await settle()
        XCTAssertEqual(presenter.coordinator.state, .savePrepared)
    }

    /// The save button, then "Finish without saving".
    func buttons(in view: UIView) -> [Button] {
        [view as? Button].compactMap { $0 } + view.subviews.flatMap(buttons(in:))
    }

    func tapSave(on screen: UIViewController) {
        guard let button = buttons(in: screen.view).first(where: { $0.accessibilityLabel == "Save with Link" }) else {
            return XCTFail("No save button")
        }
        button.sendActions(for: .touchUpInside)
    }

    /// Texts the user can see, in labels and HTML text views.
    func visibleTexts(in view: UIView) -> [String] {
        guard !view.isHidden else { return [] }
        let text = ((view as? UILabel)?.text ?? (view as? UITextView)?.text)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return [text].compactMap { $0 } + view.subviews.flatMap(visibleTexts(in:))
    }
}

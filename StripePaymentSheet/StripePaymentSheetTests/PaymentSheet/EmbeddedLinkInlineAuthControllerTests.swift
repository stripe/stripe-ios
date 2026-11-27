//
//  EmbeddedLinkInlineAuthControllerTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@_spi(InternalOnlyAPI) import StripeUICore
import XCTest

@MainActor
final class EmbeddedLinkInlineAuthControllerTests: XCTestCase {
    private let host = HostSpy()
    private let experimentAnalyticsClient = MockAnalyticsClientV2()
    private let analyticsClient = STPTestingAnalyticsClient()
    private var window: UIWindow?

    override func setUp() {
        super.setUp()
        EmbeddedLinkInlineAuthRegistry.reset()
    }

    override func tearDown() {
        EmbeddedLinkInlineAuthRegistry.reset()
        LinkAccountContext.shared.account = nil
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    func testTreatmentSendsOneCodeTheFirstTimeTheElementIsVisible() async throws {
        // Given a returning customer in the treatment group
        let (controller, account) = makeController(group: .treatment)
        XCTAssertTrue(controller.isShowingCard)
        XCTAssertNotNil(controller.makeCardView(appearance: .default))
        XCTAssertTrue(account.starts.isEmpty)

        // When the element becomes visible, twice
        controller.elementBecameVisible()
        controller.elementBecameVisible()
        await settle()

        // Then one exposure is logged and one SMS is sent
        XCTAssertEqual(account.starts.map(\.type), [.sms])
        XCTAssertEqual(controller.coordinator.analyticsSurface, .embeddedInline)
        let exposures = experimentAnalyticsClient.loggedAnalyticPayloads(withEventName: ExperimentAnalyticsHelper.eventName)
        XCTAssertEqual(exposures.count, 1)
        XCTAssertEqual(exposures.first?["assignment_group"] as? String, "treatment")
        XCTAssertTrue(controller.coordinator.canSubmitCode)
        XCTAssertEqual(loggedEvents(.linkEmbeddedInlineAuthShown).count, 1)
    }

    func testControlGroupKeepsTheLinkRowButLogsTheSameExposure() async {
        // Given a returning customer in the control group
        let (controller, account) = makeController(group: .control)

        // Then there's no card, and becoming visible logs exposure without sending a code
        XCTAssertFalse(controller.isShowingCard)
        XCTAssertNil(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()
        XCTAssertTrue(account.starts.isEmpty)
        let exposures = experimentAnalyticsClient.loggedAnalyticPayloads(withEventName: ExperimentAnalyticsHelper.eventName)
        XCTAssertEqual(exposures.first?["assignment_group"] as? String, "control")
        XCTAssertTrue(loggedEvents(.linkEmbeddedInlineAuthShown).isEmpty)
    }

    func testSessionsWithoutAnAssignmentShowTheCardWithoutLoggingExposure() async {
        let (controller, account) = makeController(group: nil)
        XCTAssertTrue(controller.isShowingCard)
        controller.elementBecameVisible()
        await settle()
        XCTAssertEqual(account.starts.count, 1)
        XCTAssertTrue(experimentAnalyticsClient.loggedAnalyticPayloads(withEventName: ExperimentAnalyticsHelper.eventName).isEmpty)
    }

    func testNothingIsSentBeforeTheElementIsVisible() async {
        let (controller, account) = makeController()
        _ = controller.makeCardView(appearance: .default)
        await settle()
        XCTAssertTrue(account.starts.isEmpty)
        XCTAssertFalse(controller.coordinator.hasStarted)
    }

    func testClosingCollapsesTheCardButKeepsTheAttempt() async throws {
        // Given a card whose code was sent
        let (controller, _) = makeController()
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()

        // When the customer closes it
        card.onClose?()

        // Then it collapses, is remembered for this session, and the code stays usable
        XCTAssertEqual(controller.phase, .collapsed)
        XCTAssertEqual(host.collapses, 1)
        XCTAssertFalse(controller.coordinator.isFinished)
        XCTAssertTrue(controller.coordinator.canSubmitCode)
        XCTAssertNotNil(controller.accountToPreserveOnUpdate)
        XCTAssertEqual(EmbeddedLinkInlineAuthRegistry.ineligibleReason(email: controller.linkAccount.email), .dismissedThisSession)
        XCTAssertNil(controller.makeCardView(appearance: .default))
        XCTAssertEqual(loggedEvents(.linkEmbeddedInlineAuthDismissed).count, 1)
    }

    func testSwitchingAccountsLogsOut() async throws {
        // Given the account the card shows is the current Link account
        let (controller, _) = makeController()
        LinkAccountContext.shared.account = controller.linkAccount
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))

        // When the customer switches accounts
        card.onSwitchAccount?()

        // Then the card collapses and the account is logged out
        XCTAssertEqual(controller.phase, .finished)
        XCTAssertEqual(host.collapses, 1)
        XCTAssertNil(LinkAccountContext.shared.account)
        XCTAssertNil(controller.accountToPreserveOnUpdate)
    }

    func testFailedFirstCodeFallsBackToTheLinkRow() async {
        // Given sending the first code fails, e.g. because of rate limits
        let account = LinkAuthAccountStub()
        account.nextStartResult = .failure(LinkAuthStubs.error("consumer_verification_max_attempts_exceeded"))
        let (controller, _) = makeController(account: account)
        _ = controller.makeCardView(appearance: .default)

        // When the element becomes visible
        controller.elementBecameVisible()
        await settle()

        // Then the card collapses back into the Link row
        XCTAssertEqual(controller.phase, .finished)
        XCTAssertEqual(host.collapses, 1)
        XCTAssertFalse(controller.isShowingCard)
        XCTAssertEqual(loggedEvents(.linkEmbeddedInlineAuthFellBack).map { $0.params["reason"] as? String }, ["send_failed"])
    }

    func testAnotherSurfaceReplacingTheAccountEndsTheAttempt() async {
        let (controller, _) = makeController()
        _ = controller.makeCardView(appearance: .default)
        controller.elementBecameVisible()
        await settle()

        controller.linkAccountDidChange(controller.linkAccount)
        XCTAssertEqual(controller.phase, .expanded)

        controller.linkAccountDidChange(PaymentSheetLinkAccount._testValue(email: "someone.else@example.com"))
        XCTAssertEqual(controller.phase, .finished)
        XCTAssertTrue(controller.coordinator.isFinished)
        XCTAssertEqual(host.collapses, 1)
    }

    func testEnteringTheRightCodeReportsVerificationWithoutCollapsing() async throws {
        // Given a card whose code was sent
        let account = LinkAuthAccountStub()
        let (controller, _) = makeController(account: account)
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()

        // When the customer enters the right code
        account.confirmResult = .success(.init(consumerSession: LinkAuthStubs.session(current: .oneFactorAuth)))
        card.onCodeEntered?("123456")
        await settle()

        // Then verification finishes, and the host, knowing it came from the card, decides what replaces the card
        XCTAssertEqual(account.confirms, [.sms])
        XCTAssertEqual(controller.phase, .finished)
        XCTAssertEqual(host.collapses, 0)
        XCTAssertEqual(host.verifications, [true])
    }

    func testPayingWithLinkAfterClosingTheCardVerifiesInTheDialogWithTheSameCode() async throws {
        // Given a card whose code was sent, which the customer closed
        let account = LinkAuthAccountStub()
        let (controller, _) = makeController(account: account)
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()
        card.onClose?()
        let presenter = makePresenterInWindow()
        host.presenter = presenter
        XCTAssertTrue(controller.verifiesBeforeConfirming)

        // When they pay with Link
        let verification = Task { await controller.verifyBeforeConfirming() }
        try await waitUntil { presenter.presentedViewController != nil }
        XCTAssertTrue(controller.isPresentingUI)
        XCTAssertEqual(host.presentations, 1)
        XCTAssertFalse(controller.verifiesBeforeConfirming)
        XCTAssertEqual(loggedEvents(.linkEmbeddedInlineAuthDialogShown).map { $0.params["reason"] as? String }, ["confirm"])

        // ...and enter the code they were sent in the dialog
        account.confirmResult = .success(.init(consumerSession: LinkAuthStubs.session(current: .oneFactorAuth)))
        controller.coordinator.confirm(code: "123456")

        // Then the dialog closes and verification succeeds without sending another code
        let result = await verification.value
        XCTAssertEqual(result, .verified)
        XCTAssertNil(presenter.presentedViewController)
        XCTAssertFalse(controller.isPresentingUI)
        XCTAssertEqual(account.starts.count, 1)
        XCTAssertEqual(host.verifications, [false])
        XCTAssertEqual(controller.coordinator.analyticsSurface, .embeddedInline)
    }

    func testClosingTheDialogBeforePayingCancels() async throws {
        // Given a closed card, and the dialog opened to pay with Link
        let (controller, _) = makeController()
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()
        card.onClose?()
        let presenter = makePresenterInWindow()
        host.presenter = presenter
        let verification = Task { await controller.verifyBeforeConfirming() }
        try await waitUntil { presenter.presentedViewController != nil }

        // When the customer closes the dialog
        let dialog = try XCTUnwrap(presenter.presentedViewController as? LinkAuthFlowViewController)
        dialog.close()

        // Then paying is canceled, but the attempt stays alive for next time
        let result = await verification.value
        XCTAssertEqual(result, .canceled)
        XCTAssertEqual(controller.phase, .collapsed)
        XCTAssertFalse(controller.coordinator.isFinished)
        XCTAssertTrue(controller.verifiesBeforeConfirming)
        XCTAssertTrue(host.verifications.isEmpty)
    }

    func testPayingWithLinkVerifiesTheUsualWayWhenTheDialogCantBeShown() async throws {
        // Given the card is showing
        let (controller, _) = makeController()
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))

        // Then paying with Link doesn't use the dialog, which only takes over once the card is closed
        XCTAssertFalse(controller.verifiesBeforeConfirming)
        let resultWhileExpanded = await controller.verifyBeforeConfirming()
        XCTAssertEqual(resultWhileExpanded, .unavailable)

        // When the card is closed but there's nothing to present from
        card.onClose?()
        XCTAssertTrue(controller.verifiesBeforeConfirming)
        let resultWithoutPresenter = await controller.verifyBeforeConfirming()

        // Then the payment verifies the usual way, in the Link wallet
        XCTAssertEqual(resultWithoutPresenter, .unavailable)
        XCTAssertEqual(host.presentations, 0)
    }

    func testTappingTheCodeTypesInTheCardWhenTheLayoutCanKeepItVisible() async throws {
        // Given a card whose code was sent, near the top of a scrolling screen
        let (controller, _) = makeController()
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()
        placeInScrollingScreen(card)
        XCTAssertEqual(controller.codeEntry(), .inline)

        // When the customer taps the code
        card.onTapCode?()

        // Then they type in the card rather than a dialog
        XCTAssertTrue(card.isCodeFocused)
        XCTAssertEqual(host.presentations, 0)
        XCTAssertEqual(loggedEvents(.linkEmbeddedInlineAuthFocused).count, 1)

        // When the merchant's app ends editing
        let endEditing = card.onCodeEditingEnded
        var editingEndedCount = 0
        card.onCodeEditingEnded = {
            editingEndedCount += 1
            endEditing?()
        }
        card.window?.endEditing(true)

        // Then the card hears about it once
        XCTAssertFalse(card.isCodeFocused)
        XCTAssertEqual(editingEndedCount, 1)

        // When they tap the code again, then close the card
        card.onTapCode?()
        XCTAssertTrue(card.isCodeFocused)
        card.onClose?()

        // Then typing ends
        XCTAssertFalse(card.isCodeFocused)
        XCTAssertEqual(editingEndedCount, 2)
    }

    func testCodeEntryUsesTheDialogWhenTheCardCanNotTakeIt() async throws {
        // Given a card whose code was sent, in a scrolling screen
        let (controller, _) = makeController()
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()
        placeInScrollingScreen(card)

        // Then the server can send every code to the dialog
        controller.forcesDialog = true
        XCTAssertEqual(controller.codeEntry(), .dialog(.forcedByServer))
        controller.forcesDialog = false

        // ...and so does a card that isn't on screen
        card.removeFromSuperview()
        XCTAssertEqual(controller.codeEntry(), .dialog(.layout(.notInWindow)))
    }

    func testSwitchingToAnEmailCodeKeepsTypingInTheCard() async throws {
        // Given a card whose code was sent, in a scrolling screen, for an account whose email codes need no phone number match
        let (controller, account) = makeController()
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()
        placeInScrollingScreen(card)
        host.presenter = try XCTUnwrap(window?.rootViewController)

        // When the customer picks "Email code"
        card.onAction?(.email)
        await settle()

        // Then the email code is sent and typed in the card, without the dialog
        XCTAssertEqual(account.starts.map(\.type), [.sms, .email])
        XCTAssertEqual(controller.coordinator.screen, .otp)
        XCTAssertEqual(controller.codeEntry(), .inline)
        XCTAssertEqual(host.presentations, 0)
        XCTAssertNil(host.presenter?.presentedViewController)
    }

    func testSwitchingToAnEmailCodeThatNeedsAPhoneNumberMatchOpensTheDialog() async throws {
        // Given a card whose code was sent, for an account whose email codes need a phone number match
        let (controller, account) = makeController()
        account.authLookupSettings = .init(emailOtpRequiresAdditionalInfo: true)
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()
        let presenter = makePresenterInWindow()
        host.presenter = presenter

        // When the customer picks "Email code"
        card.onAction?(.email)
        await settle()

        // Then the phone number match continues in the dialog, before any email code is sent
        try await waitUntil { presenter.presentedViewController != nil }
        XCTAssertEqual(controller.coordinator.screen, .phoneMatch)
        XCTAssertEqual(account.starts.map(\.type), [.sms])
        XCTAssertEqual(host.presentations, 1)
        // ...and the card can't take that step
        XCTAssertEqual(controller.codeEntry(), .dialog(.unsupportedStep))
    }

    func testForcedDialogOpensWhenTheCodeIsTapped() async throws {
        let (controller, _) = makeController()
        controller.forcesDialog = true
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()
        let presenter = makePresenterInWindow()
        host.presenter = presenter

        card.onTapCode?()

        XCTAssertFalse(card.isCodeFocused)
        XCTAssertEqual(host.presentations, 1)
        XCTAssertTrue(controller.isPresentingUI)
        XCTAssertEqual(loggedEvents(.linkEmbeddedInlineAuthDialogShown).map { $0.params["reason"] as? String }, ["forced_by_server"])
        controller.invalidate()
        try await waitUntil { presenter.presentedViewController == nil }
    }

    func testTypedDigitsCarryIntoARebuiltCardUntilTheFieldIsCleared() async throws {
        // Given a card whose code was sent
        let account = LinkAuthAccountStub()
        let (controller, _) = makeController(account: account)
        let card = try XCTUnwrap(controller.makeCardView(appearance: .default))
        controller.elementBecameVisible()
        await settle()

        // When the customer types two digits, then an update rebuilds the list
        card.onCodeChanged?("12")
        let rebuiltCard = try XCTUnwrap(controller.makeCardView(appearance: .default))

        // Then the new card shows them, without submitting anything
        XCTAssertEqual(rebuiltCard.codeField.value, "12")
        XCTAssertTrue(account.confirms.isEmpty)

        // When they finish a wrong code, which clears the field
        rebuiltCard.onCodeChanged?("123456")
        rebuiltCard.onCodeEntered?("123456")
        await settle()
        let cardAfterWrongCode = try XCTUnwrap(controller.makeCardView(appearance: .default))

        // Then the digits aren't carried over again
        XCTAssertEqual(account.confirms.count, 1)
        XCTAssertEqual(cardAfterWrongCode.codeField.value, "")
    }

    func testShowingTheCardClaimsItForThisInstance() {
        let (controller, _) = makeController()
        XCTAssertEqual(EmbeddedLinkInlineAuthRegistry.ineligibleReason(email: "other@example.com"), .shownElsewhere)
        controller.invalidate()
        XCTAssertNil(EmbeddedLinkInlineAuthRegistry.ineligibleReason(email: "other@example.com"))
    }

    // MARK: - Helpers

    private func makeController(
        group: ExperimentGroup? = .treatment,
        account: LinkAuthAccountStub = LinkAuthAccountStub()
    ) -> (EmbeddedLinkInlineAuthController, LinkAuthAccountStub) {
        let linkAccount = PaymentSheetLinkAccount(
            email: "jane.diaz@example.com",
            session: LinkAuthStubs.session(),
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )
        let coordinator = LinkAuthFlowCoordinator(account: account, analyticsHelper: .init(analyticsClient: STPTestingAnalyticsClient()))
        coordinator.prepare()
        let experiment = group.flatMap {
            EmbeddedLinkInlineVerificationExperiment(
                elementsSession: STPElementsSession._testValue(experimentsData: ExperimentsData(arbId: "arb", experimentAssignments: [EmbeddedLinkInlineVerificationExperiment.experimentName: $0], allResponseFields: [:])),
                dimensions: [:]
            )
        }
        var configuration = EmbeddedPaymentElement.Configuration()
        // A test key, so no attestation is needed before sending.
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        let controller = EmbeddedLinkInlineAuthController(
            eligible: .init(linkAccount: linkAccount, coordinator: coordinator),
            experiment: experiment,
            configuration: configuration,
            linkBrand: .link,
            experimentAnalyticsHelper: ExperimentAnalyticsHelper(integrationShape: .embedded, analyticsClientV2: experimentAnalyticsClient),
            linkAnalyticsHelper: LinkAnalyticsHelper(analyticsClient: analyticsClient)
        )
        controller.host = host
        return (controller, account)
    }

    private func makePresenterInWindow() -> UIViewController {
        let window = UIWindow.makeForTesting()
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        self.window = window
        return presenter
    }

    private func loggedEvents(_ event: STPAnalyticEvent) -> [Analytic] {
        analyticsClient.events.filter { $0.event == event }
    }

    /// Puts the card near the top of a full-screen scroll view in a window.
    private func placeInScrollingScreen(_ card: UIView) {
        let presenter = makePresenterInWindow()
        let scrollView = UIScrollView()
        presenter.view.addAndPinSubview(scrollView)
        card.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 40),
            card.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -800),
        ])
        presenter.view.layoutIfNeeded()
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for condition")
                throw CancellationError()
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    /// Lets the send task and the stub's main-queue callbacks run.
    private func settle() async {
        for _ in 0..<6 {
            await Task.yield()
            await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        }
    }
}

@MainActor
private final class HostSpy: EmbeddedLinkInlineAuthControllerHost {
    var collapses = 0
    /// Whether each verification came from the card.
    var verifications: [Bool] = []
    var presentations = 0
    var presenter: UIViewController?

    func linkInlineAuthPresentingViewController() -> UIViewController? {
        presenter?.presentedViewController == nil ? presenter : nil
    }
    func linkInlineAuthWillPresent() { presentations += 1 }
    func linkInlineAuthDidCollapse() { collapses += 1 }
    func linkInlineAuthDidVerify(fromCard: Bool) { verifications.append(fromCard) }
}

@MainActor
final class EmbeddedVisibilityMonitorTests: XCTestCase {
    private var window: UIWindow!
    private var viewController: UIViewController!

    override func setUp() {
        super.setUp()
        viewController = UIViewController()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        window.rootViewController = viewController
        window.isHidden = false
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        super.tearDown()
    }

    func testVisibleView() {
        XCTAssertTrue(EmbeddedVisibilityMonitor.isOnScreen(addView(frame: CGRect(x: 0, y: 100, width: 320, height: 200))))
    }

    func testViewOutsideAWindow() {
        XCTAssertFalse(EmbeddedVisibilityMonitor.isOnScreen(UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))))
    }

    func testHiddenOrTransparentAncestor() {
        let container = UIView(frame: window.bounds)
        viewController.view.addSubview(container)
        let view = UIView(frame: CGRect(x: 0, y: 100, width: 320, height: 200))
        container.addSubview(view)
        container.isHidden = true
        XCTAssertFalse(EmbeddedVisibilityMonitor.isOnScreen(view))
        container.isHidden = false
        container.alpha = 0
        XCTAssertFalse(EmbeddedVisibilityMonitor.isOnScreen(view))
    }

    func testBelowTheFold() {
        // Only the top 40pt of a 300pt view is on screen
        XCTAssertFalse(EmbeddedVisibilityMonitor.isOnScreen(addView(frame: CGRect(x: 0, y: 600, width: 320, height: 300))))
        // The top 120pt of a tall view is enough
        XCTAssertTrue(EmbeddedVisibilityMonitor.isOnScreen(addView(frame: CGRect(x: 0, y: 520, width: 320, height: 400))))
    }

    func testClippedByAScrollView() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 300))
        viewController.view.addSubview(scrollView)
        let view = UIView(frame: CGRect(x: 0, y: 400, width: 320, height: 200))
        scrollView.addSubview(view)
        XCTAssertFalse(EmbeddedVisibilityMonitor.isOnScreen(view))
        scrollView.contentSize = CGSize(width: 320, height: 800)
        scrollView.contentOffset = CGPoint(x: 0, y: 300)
        XCTAssertTrue(EmbeddedVisibilityMonitor.isOnScreen(view))
    }

    func testCoveredByAPresentedViewController() {
        let view = addView(frame: CGRect(x: 0, y: 100, width: 320, height: 200))
        viewController.present(UIViewController(), animated: false)
        XCTAssertFalse(EmbeddedVisibilityMonitor.isOnScreen(view))
    }

    func testFiresOnce() {
        let view = addView(frame: CGRect(x: 0, y: 100, width: 320, height: 200))
        var isVisible = false
        var fires = 0
        let monitor = EmbeddedVisibilityMonitor(view: view, isVisible: { _ in isVisible }) { fires += 1 }
        monitor.viewDidMoveToWindow()
        XCTAssertEqual(fires, 0)
        isVisible = true
        monitor.check()
        monitor.check()
        monitor.viewDidMoveToWindow()
        XCTAssertEqual(fires, 1)
        XCTAssertTrue(monitor.hasFired)
    }

    private func addView(frame: CGRect) -> UIView {
        let view = UIView(frame: frame)
        viewController.view.addSubview(view)
        return view
    }
}

@MainActor
final class EmbeddedPaymentElementLinkInlineAuthTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // The card form's country field needs address specs.
        let addressSpecsLoaded = expectation(description: "address specs loaded")
        AddressSpecProvider.shared.loadAddressSpecs {
            addressSpecsLoaded.fulfill()
        }
        wait(for: [addressSpecsLoaded], timeout: 1)
        EmbeddedLinkInlineAuthRegistry.reset()
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = true
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
    }

    override func tearDown() {
        EmbeddedLinkInlineAuthRegistry.reset()
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = nil
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        LinkAccountContext.shared.account = nil
        // Selecting Link saves it as the default for customer-less sessions.
        CustomerPaymentOption.setLocalDefaultPaymentMethod(nil, forCustomer: nil)
        super.tearDown()
    }

    func testReturningCustomerSeesTheCardOnTopAndKeepsItAcrossUpdates() throws {
        // Given a returning Link customer who needs to verify
        let linkAccount = makeLinkAccountRequiringVerification()
        LinkAccountContext.shared.account = linkAccount
        let configuration = makeConfiguration()

        // When the element loads
        let element = EmbeddedPaymentElement(configuration: configuration, loadResult: makeLoadResult(isLinkEnabled: true), analyticsHelper: ._testValue(integrationShape: .embedded))

        // Then the Link row leads, expanded into the card
        let controller = try XCTUnwrap(element.linkInlineAuth)
        XCTAssertTrue(controller.isShowingCard)
        XCTAssertNotNil(element.embeddedPaymentMethodsView.linkInlineVerificationView)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.first?.type, .link)
        XCTAssertNil(element.paymentOption)
        XCTAssertTrue(controller.accountToPreserveOnUpdate === linkAccount)

        // When an update reloads the element
        element.applyLoadResult(makeLoadResult(isLinkEnabled: true), confirmationChallenge: nil, configuration: configuration)

        // Then the same attempt continues in the rebuilt list
        XCTAssertTrue(element.linkInlineAuth === controller)
        XCTAssertNotNil(element.embeddedPaymentMethodsView.linkInlineVerificationView)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.first?.type, .link)
    }

    func testAnUpdateThatRemovesLinkEndsTheAttempt() throws {
        LinkAccountContext.shared.account = makeLinkAccountRequiringVerification()
        let configuration = makeConfiguration()
        let element = EmbeddedPaymentElement(configuration: configuration, loadResult: makeLoadResult(isLinkEnabled: true), analyticsHelper: ._testValue(integrationShape: .embedded))
        let controller = try XCTUnwrap(element.linkInlineAuth)

        element.applyLoadResult(makeLoadResult(isLinkEnabled: false), confirmationChallenge: nil, configuration: configuration)

        XCTAssertEqual(controller.phase, .finished)
        XCTAssertNil(element.linkInlineAuth)
        XCTAssertNil(element.embeddedPaymentMethodsView.linkInlineVerificationView)
    }

    func testNewCustomersKeepTheRegularLinkRow() {
        LinkAccountContext.shared.account = nil
        let element = EmbeddedPaymentElement(configuration: makeConfiguration(), loadResult: makeLoadResult(isLinkEnabled: true), analyticsHelper: ._testValue(integrationShape: .embedded))
        XCTAssertNil(element.linkInlineAuth)
        XCTAssertNil(element.embeddedPaymentMethodsView.linkInlineVerificationView)
        XCTAssertNotEqual(element.embeddedPaymentMethodsView.rowButtons.first?.type, .link)
    }

    func testReturningCustomersWhoDontGetTheCardAreLoggedOncePerElement() {
        // Given a returning customer who needs to verify, with a merchant that opted out
        LinkAccountContext.shared.account = makeLinkAccountRequiringVerification()
        var configuration = makeConfiguration()
        configuration.allowsLinkInlineVerification = false
        let analyticsClient = STPTestingAnalyticsClient()

        // When the element loads, then updates
        let element = EmbeddedPaymentElement(configuration: configuration, loadResult: makeLoadResult(isLinkEnabled: true), analyticsHelper: ._testValue(integrationShape: .embedded, analyticsClient: analyticsClient))
        element.applyLoadResult(makeLoadResult(isLinkEnabled: true), confirmationChallenge: nil, configuration: configuration)

        // Then the reason is logged once
        XCTAssertNil(element.linkInlineAuth)
        let ineligible = analyticsClient.events.filter { $0.event == .linkEmbeddedInlineAuthIneligible }
        XCTAssertEqual(ineligible.map { $0.params["reason"] as? String }, ["disabled_by_merchant"])
    }

    func testCustomersWithoutALinkAccountArentLoggedAsIneligible() {
        LinkAccountContext.shared.account = nil
        let analyticsClient = STPTestingAnalyticsClient()
        _ = EmbeddedPaymentElement(configuration: makeConfiguration(), loadResult: makeLoadResult(isLinkEnabled: true), analyticsHelper: ._testValue(integrationShape: .embedded, analyticsClient: analyticsClient))
        XCTAssertFalse(analyticsClient.events.contains { $0.event == .linkEmbeddedInlineAuthIneligible })
    }

    func testPickingPaymentDetailsInTheLinkWalletSelectsLinkWithThem() throws {
        // Given a returning customer who verified from the card, with immediate row actions
        var immediateActions = 0
        var configuration = makeConfiguration()
        configuration.rowSelectionBehavior = .immediateAction { immediateActions += 1 }
        let (element, linkAccount) = makeElementVerifiedFromTheCard(configuration: configuration)
        let delegate = EmbeddedDelegateSpy()
        element.delegate = delegate
        XCTAssertTrue(element.linkRowOpensWallet)
        XCTAssertNil(element.paymentOption)

        // When they pick a card in the Link wallet
        let paymentDetails = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
        element.linkWalletDidFinish(with: makeConfirmOption(account: linkAccount, paymentDetails: paymentDetails), revertsSelectionOnClose: false)

        // Then Link is the only row, selected with that card, which the row shows, and the selection is reported once
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertEqual(linkRow.type, .link)
        XCTAssertTrue(linkRow.isDisplayingAccessoryView)
        XCTAssertEqual(linkRow.label.text, paymentDetails.paymentSheetLabel)
        XCTAssertEqual(sublabelText(of: linkRow), paymentDetails.paymentSheetSublabel)
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, paymentDetails.stripeID)
        XCTAssertEqual(element.paymentOption?.paymentMethodType, "link")
        XCTAssertEqual(delegate.paymentOptionUpdates, 1)
        XCTAssertEqual(immediateActions, 1)
    }

    func testClearingThePaymentOptionDropsThePickedLinkDetails() throws {
        // Given Link is selected with a card picked in the Link wallet
        let (element, linkAccount) = makeElementVerifiedFromTheCard()
        element.linkWalletDidFinish(with: makeConfirmOption(account: linkAccount), revertsSelectionOnClose: false)

        // When the payment option is cleared
        element.clearPaymentOption()

        // Then the rebuilt list's Link row goes back to showing the customer's email
        XCTAssertNil(element.linkConfirmOption)
        XCTAssertNil(element.paymentOption)
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.rowButtons.first)
        XCTAssertEqual(linkRow.type, .link)
        XCTAssertFalse(linkRow.isDisplayingAccessoryView)
        XCTAssertEqual(sublabelText(of: linkRow), linkAccount.email)
    }

    func testAnUpdateKeepsThePickedLinkDetails() throws {
        // Given Link is selected with a card picked in the Link wallet
        let configuration = makeConfiguration()
        let (element, linkAccount) = makeElementVerifiedFromTheCard(configuration: configuration)
        let paymentDetails = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
        element.linkWalletDidFinish(with: makeConfirmOption(account: linkAccount, paymentDetails: paymentDetails), revertsSelectionOnClose: false)

        // When an update reloads the element
        element.applyLoadResult(makeLoadResult(isLinkEnabled: true), confirmationChallenge: nil, configuration: configuration)

        // Then the rebuilt list still shows only Link, selected with the same card
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertEqual(linkRow.type, .link)
        XCTAssertTrue(linkRow.isDisplayingAccessoryView)
        XCTAssertEqual(linkRow.label.text, paymentDetails.paymentSheetLabel)
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, paymentDetails.stripeID)
    }

    func testAnUpdateAfterTheAccountChangesFallsBackToTheLinkWallet() throws {
        // Given Link is selected with a card picked in the Link wallet
        let configuration = makeConfiguration()
        let (element, linkAccount) = makeElementVerifiedFromTheCard(configuration: configuration)
        element.linkWalletDidFinish(with: makeConfirmOption(account: linkAccount), revertsSelectionOnClose: false)

        // When another surface signs in a different Link account, then an update reloads the element
        LinkAccountContext.shared.account = PaymentSheetLinkAccount(
            email: "someone.else@example.com",
            session: LinkAuthStubs.session(current: .oneFactorAuth),
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )
        element.applyLoadResult(makeLoadResult(isLinkEnabled: true), confirmationChallenge: nil, configuration: configuration)

        // Then Link stays selected but pays through the Link wallet, without the other account's card
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertEqual(linkRow.type, .link)
        XCTAssertNil(element.linkConfirmOption)
        XCTAssertNil(element._paymentOption?.currentLinkPaymentMethod)
        XCTAssertFalse(linkRow.isDisplayingAccessoryView)
    }

    func testTappingTheVerifiedLinkRowWaitsForTheWalletBeforeReportingLink() throws {
        // Given a customer who verified from the card, where the Link wallet can't be shown right now
        let (element, _) = makeElementVerifiedFromTheCard()
        element.presentingViewController = UIViewController()
        let delegate = EmbeddedDelegateSpy()
        element.delegate = delegate
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.rowButtons.first)

        // When they tap the Link row
        element.embeddedPaymentMethodsView.didTap(rowButton: linkRow)

        // Then nothing is selected or reported, since nothing was picked in the wallet
        XCTAssertNil(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertNil(element.paymentOption)
        XCTAssertEqual(delegate.paymentOptionUpdates, 0)
    }

    func testCancelingCardEditsAfterClosingTheLinkWalletRestoresTheAcceptedCard() throws {
        // Given a customer who verified from the card and continued with a card from the card form
        var configuration = makeConfiguration()
        configuration.billingDetailsCollectionConfiguration.address = .never
        let (element, _) = makeElementVerifiedFromTheCard(configuration: configuration)
        element.presentingViewController = UIViewController()
        let cardRow = try XCTUnwrap(element.embeddedPaymentMethodsView.rowButtons.first(where: { $0.type == .new(paymentMethodType: .stripe(.card)) }))
        element.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let cardForm = try XCTUnwrap(element.formCache[.stripe(.card)])
        cardForm.getTextFieldElement("Card number").setText("4242424242424242")
        cardForm.getTextFieldElement("MM / YY").setText("1232")
        cardForm.getTextFieldElement("CVC").setText("123")
        element.embeddedFormViewControllerDidContinue(try XCTUnwrap(element.selectedFormViewController))
        XCTAssertEqual(element.embeddedPaymentMethodsView.selectedRowChangeButtonState?.sublabel, "Visa •••• 4242")

        // When they tap the Link row and the wallet closes without a pick
        // (it can't be shown here, which takes the same path as closing it)
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.rowButtons.first(where: { $0.type == .link }))
        element.embeddedPaymentMethodsView.didTap(rowButton: linkRow)
        XCTAssertTrue(element.embeddedPaymentMethodsView.selectedRowButton === cardRow)

        // ...and they tap Change, clear the card number, and close the form
        element.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        try XCTUnwrap(element.formCache[.stripe(.card)]).getTextFieldElement("Card number").setText("")
        element.embeddedFormViewControllerDidCancel(try XCTUnwrap(element.selectedFormViewController))

        // Then the card row stays selected with the card they continued with
        XCTAssertTrue(element.embeddedPaymentMethodsView.selectedRowButton === cardRow)
        XCTAssertEqual(element.embeddedPaymentMethodsView.selectedRowChangeButtonState?.sublabel, "Visa •••• 4242")
        XCTAssertEqual(element.paymentOption?.paymentMethodType, "card")
    }

    func testTappingTheLinkRowAfterClosingTheCardOnlySelectsIt() throws {
        // Given a returning customer who closed the card without verifying
        LinkAccountContext.shared.account = makeLinkAccountRequiringVerification()
        let element = EmbeddedPaymentElement(configuration: makeConfiguration(), loadResult: makeLoadResult(isLinkEnabled: true), analyticsHelper: ._testValue(integrationShape: .embedded))
        element.presentingViewController = UIViewController()
        let delegate = EmbeddedDelegateSpy()
        element.delegate = delegate
        try XCTUnwrap(element.embeddedPaymentMethodsView.linkInlineVerificationView).onClose?()
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.rowButtons.first)
        XCTAssertFalse(linkRow.isHidden)

        // When they tap the Link row
        element.embeddedPaymentMethodsView.didTap(rowButton: linkRow)

        // Then Link is selected and pays through the Link wallet, which verifies with the code already sent
        XCTAssertFalse(element.linkRowOpensWallet)
        XCTAssertEqual(element.embeddedPaymentMethodsView.selectedRowButton?.type, .link)
        XCTAssertEqual(element.paymentOption?.paymentMethodType, "link")
        XCTAssertNil(element._paymentOption?.currentLinkPaymentMethod)
        XCTAssertEqual(delegate.paymentOptionUpdates, 1)
        XCTAssertEqual(element.linkInlineAuth?.verifiesBeforeConfirming, true)
    }

    /// An element whose card was shown and verified, which leaves the regular Link row at the top.
    private func makeElementVerifiedFromTheCard(
        configuration: EmbeddedPaymentElement.Configuration? = nil
    ) -> (EmbeddedPaymentElement, PaymentSheetLinkAccount) {
        let linkAccount = makeLinkAccountRequiringVerification()
        LinkAccountContext.shared.account = linkAccount
        let element = EmbeddedPaymentElement(configuration: configuration ?? makeConfiguration(), loadResult: makeLoadResult(isLinkEnabled: true), analyticsHelper: ._testValue(integrationShape: .embedded))
        XCTAssertTrue(element.placesLinkFirst)
        linkAccount.applyAuthResponse(.init(consumerSession: LinkAuthStubs.session(current: .oneFactorAuth)))
        element.linkInlineAuth?.invalidate()
        return (element, linkAccount)
    }

    private func makeConfirmOption(
        account: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
    ) -> PaymentSheet.LinkConfirmOption {
        .withPaymentDetails(brand: .link, account: account, paymentDetails: paymentDetails, confirmationExtras: nil, shippingAddress: nil)
    }

    private func sublabelText(of rowButton: RowButton) -> String? {
        (rowButton.sublabel as? RowButton.PlainSublabelView)?.textLabel.text
    }

    /// Link comes from the session; it's never a payment method row of its own.
    private func makeLoadResult(isLinkEnabled: Bool) -> PaymentSheetLoader.LoadResult {
        PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: isLinkEnabled ? ["card", "link"] : ["card"]),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical,
            customerProvider: CustomerProvider(customer: nil)
        )
    }

    private func makeConfiguration() -> EmbeddedPaymentElement.Configuration {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.allowsLinkInlineVerification = true
        return configuration
    }

    private func makeLinkAccountRequiringVerification() -> PaymentSheetLinkAccount {
        PaymentSheetLinkAccount(
            email: "jane.diaz@example.com",
            session: LinkAuthStubs.session(),
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false,
            supportedVerificationTypes: [.sms, .email]
        )
    }
}

@MainActor
private final class EmbeddedDelegateSpy: EmbeddedPaymentElementDelegate {
    var paymentOptionUpdates = 0

    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {}
    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        paymentOptionUpdates += 1
    }
}

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

    override func setUp() {
        super.setUp()
        EmbeddedLinkInlineAuthRegistry.reset()
    }

    override func tearDown() {
        EmbeddedLinkInlineAuthRegistry.reset()
        LinkAccountContext.shared.account = nil
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

    func testEnteringTheRightCodeCollapsesAndReportsVerification() async throws {
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

        // Then verification finishes and the host shows the Link row again
        XCTAssertEqual(account.confirms, [.sms])
        XCTAssertEqual(controller.phase, .finished)
        XCTAssertEqual(host.collapses, 1)
        XCTAssertEqual(host.verifications, 1)
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
            experimentAnalyticsHelper: ExperimentAnalyticsHelper(integrationShape: .embedded, analyticsClientV2: experimentAnalyticsClient)
        )
        controller.host = host
        return (controller, account)
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
    var verifications = 0
    var presentations = 0

    func linkInlineAuthPresentingViewController() -> UIViewController? { nil }
    func linkInlineAuthWillPresent() { presentations += 1 }
    func linkInlineAuthDidCollapse() { collapses += 1 }
    func linkInlineAuthDidVerify() { verifications += 1 }
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

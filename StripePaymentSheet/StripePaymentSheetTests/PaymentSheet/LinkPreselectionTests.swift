@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@_spi(InternalOnlyAPI) import StripeUICore
import XCTest

@MainActor
final class LinkPreselectionTests: STPSnapshotTestCase {
    override func setUp() async throws {
        try await super.setUp()
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        LinkAccountContext.shared.account = nil
        await AddressSpecProvider.shared.loadAddressSpecs()
    }

    override func tearDown() {
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        LinkAccountContext.shared.account = nil
        super.tearDown()
    }

    func testHorizontalFlowControllerPreselectsLink() {
        assertFlowControllerPreselectsLink(layout: .horizontal)
    }

    func testVerticalFlowControllerPreselectsLink() {
        assertFlowControllerPreselectsLink(layout: .vertical)
    }

    func testControlFlowControllerHasNoSelection() {
        let flowController = PaymentSheet.FlowController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(preselectLink: false),
            analyticsHelper: ._testValue()
        )
        XCTAssertNil(flowController.paymentOption)
    }

    // @iOS26
    func testEmbeddedPreselectsLink() {
        let embedded = EmbeddedPaymentElement(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(),
            analyticsHelper: ._testValue(integrationShape: .embedded)
        )
        XCTAssertEqual(embedded.embeddedPaymentMethodsView.selectedRowButton?.type, .link)
        guard case .link(.wallet) = embedded._paymentOption else {
            return XCTFail("Expected Link wallet selection")
        }
        XCTAssertEqual(embedded.paymentOption?.paymentMethodType, "link")
        XCTAssertEqual(embedded.paymentOption?.label, "Link")
        embedded.view.backgroundColor = embedded.configuration.appearance.colors.background
        STPSnapshotVerifyView(embedded.view, autoSizingHeightForWidth: 375)
    }

    func testEmbeddedPreservesPreviousSelectionOverLinkFallback() {
        let view = EmbeddedPaymentElement.makeView(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(),
            analyticsHelper: ._testValue(integrationShape: .embedded),
            previousSelection: .new(paymentMethodType: .stripe(.card))
        )
        XCTAssertEqual(view.selectedRowButton?.type, .new(paymentMethodType: .stripe(.card)))
    }

    func testEmbeddedControlHasNoSelection() {
        let view = EmbeddedPaymentElement.makeView(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(preselectLink: false),
            analyticsHelper: ._testValue(integrationShape: .embedded)
        )
        XCTAssertNil(view.selectedRowButton)
    }

    func testEmbeddedPreselectionReplacesUnavailableLastUsedApplePay() {
        CustomerPaymentOption.setDefaultPaymentMethod(.applePay, forCustomer: nil)
        let view = EmbeddedPaymentElement.makeView(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(),
            analyticsHelper: ._testValue(integrationShape: .embedded)
        )
        XCTAssertEqual(view.selectedRowButton?.type, .link)
    }

    func testExperimentSelectedLinkStillPresentsPaymentOptionsFirst() {
        assertInitialPresentation(preselectLink: true)
    }

    func testExperimentSelectedLinkWithRegisteredAccountStillPresentsPaymentOptionsFirst() {
        LinkAccountContext.shared.account = LinkStubs.account()
        assertInitialPresentation(preselectLink: true)
    }

    func testLastUsedLinkStillPresentsPaymentOptionsFirst() {
        LinkAccountContext.shared.account = LinkStubs.account()
        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: nil)
        assertInitialPresentation(preselectLink: false)
    }

    func testFlowControllerRebuildPreservesExperimentSelection() {
        // Given a load-time Link fallback
        let flowController = PaymentSheet.FlowController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(),
            analyticsHelper: ._testValue(integrationShape: .flowController)
        )

        // When wallet visibility rebuilds the payment options controller
        flowController.walletButtonsViewState = .hidden

        // Then Link is still the payment option returned to the merchant
        XCTAssertEqual(flowController.paymentOption?.paymentMethodType, "link")
        XCTAssertEqual(flowController.paymentOption?.label, "Link")
        XCTAssertTrue(flowController.viewController.loadResult.preselectLink)
    }

    private func assertInitialPresentation(preselectLink: Bool) {
        // Given a selected Link wallet with native Link available
        let previousOverride = PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
        defer { PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = previousOverride }
        let flowController = PaymentSheet.FlowController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(preselectLink: preselectLink),
            analyticsHelper: ._testValue(integrationShape: .flowController)
        )
        let presenter = PresentationCapturingViewController()

        // When the merchant presents payment options for the first time
        flowController.presentPaymentOptions(from: presenter, completion: { (_: Bool) in })

        // Then preselection does not change the existing presentation behavior
        XCTAssertNotNil(presenter.capturedViewController)
        XCTAssertFalse(presenter.capturedViewController is LinkBottomSheetViewController)
        XCTAssertFalse(presenter.capturedViewController is LinkNativeSheetContainerViewController)
    }

    private func assertFlowControllerPreselectsLink(layout: PaymentSheet.PaymentMethodLayout.ResolvedLayout) {
        // Given a load-time Link fallback and no saved methods or Apple Pay
        let flowController = PaymentSheet.FlowController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(layout: layout),
            analyticsHelper: ._testValue(integrationShape: .flowController)
        )

        // Then the initial merchant-facing payment option is Link, without persisting a last-used method
        XCTAssertEqual(flowController.paymentOption?.paymentMethodType, "link")
        XCTAssertEqual(flowController.paymentOption?.label, "Link")
        XCTAssertNil(CustomerPaymentOption.localDefaultPaymentMethod(for: nil))

        // When the payment options view is loaded
        flowController.viewController.loadViewIfNeeded()

        // Then rendering preserves the merchant-facing selection
        XCTAssertEqual(flowController.paymentOption?.paymentMethodType, "link")
        XCTAssertEqual(flowController.paymentOption?.label, "Link")
    }

    private func makeLoadResult(
        layout: PaymentSheet.PaymentMethodLayout.ResolvedLayout = .vertical,
        preselectLink: Bool = true
    ) -> PaymentSheetLoader.LoadResult {
        .init(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "link"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: nil,
            paymentMethodOrientation: layout,
            customerProvider: CustomerProvider(customer: nil),
            preselectLink: preselectLink
        )
    }
}

private final class PresentationCapturingViewController: UIViewController {
    var capturedViewController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        capturedViewController = viewControllerToPresent
        completion?()
    }
}

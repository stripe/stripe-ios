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

    // @iOS26
    func testHorizontalFlowControllerPreselectsLink() {
        assertFlowControllerPreselectsLink(layout: .horizontal)
    }

    // @iOS26
    func testVerticalFlowControllerPreselectsLink() {
        assertFlowControllerPreselectsLink(layout: .vertical)
    }

    func testControlFlowControllerHasNoSelection() {
        let flowController = PaymentSheet.FlowController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(preselectLink: false),
            analyticsHelper: ._testValue()
        )
        XCTAssertNil(flowController.internalPaymentOption)
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
        XCTAssertNotNil(embedded.paymentOption)
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

    func testExperimentSelectedLinkPresentsNativeLinkImmediately() {
        assertInitialPresentation(preselectLink: true, expectsLink: true)
    }

    func testLastUsedLinkStillPresentsPaymentOptionsFirst() {
        LinkAccountContext.shared.account = LinkStubs.account()
        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: nil)
        assertInitialPresentation(preselectLink: false, expectsLink: false)
    }

    func testFlowControllerRebuildPreservesExperimentSelection() {
        assertInitialPresentation(preselectLink: true, rebuild: true, expectsLink: true)
    }

    func testPreselectedLinkRespectsNativeLinkAvailability() {
        assertInitialPresentation(preselectLink: true, isNativeLinkAvailable: false, expectsLink: false)
    }

    private func assertInitialPresentation(
        preselectLink: Bool,
        isNativeLinkAvailable: Bool = true,
        rebuild: Bool = false,
        expectsLink: Bool
    ) {
        // Given a selected Link wallet before any payment options have been presented
        let previousOverride = PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = isNativeLinkAvailable
        defer { PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = previousOverride }
        let flowController = PaymentSheet.FlowController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(preselectLink: preselectLink),
            analyticsHelper: ._testValue(integrationShape: .flowController)
        )
        if rebuild {
            flowController.walletButtonsViewState = .hidden
        }
        let presenter = PresentationCapturingViewController()

        // When the merchant presents payment options for the first time
        flowController.presentPaymentOptions(from: presenter, completion: { (_: Bool) in })

        // Then only the experiment selection immediately opens native Link
        XCTAssertNotNil(presenter.capturedViewController)
        let presentedLink = presenter.capturedViewController is LinkBottomSheetViewController
            || presenter.capturedViewController is LinkNativeSheetContainerViewController
        XCTAssertEqual(presentedLink, expectsLink)
    }

    private func assertFlowControllerPreselectsLink(layout: PaymentSheet.PaymentMethodLayout.ResolvedLayout) {
        // Given a load-time Link fallback and no saved methods or Apple Pay
        let flowController = PaymentSheet.FlowController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(layout: layout),
            analyticsHelper: ._testValue(integrationShape: .flowController)
        )

        // Then the merchant can pay with Link immediately, without persisting a last-used method
        guard case .link(.wallet) = flowController.internalPaymentOption else {
            return XCTFail("Expected Link wallet selection")
        }
        XCTAssertNotNil(flowController.paymentOption)
        XCTAssertNil(CustomerPaymentOption.localDefaultPaymentMethod(for: nil))
        flowController.viewController.loadViewIfNeeded()
        guard case .link(.wallet) = flowController.internalPaymentOption else {
            return XCTFail("Expected Link wallet selection after rendering")
        }
        let bottomSheet = BottomSheetViewController(
            contentViewController: flowController.viewController,
            appearance: .default,
            didCancelNative3DS2: {}
        )
        bottomSheet.view.setNeedsLayout()
        bottomSheet.view.layoutIfNeeded()
        let height = bottomSheet.view.systemLayoutSizeFitting(.init(width: 375, height: UIView.noIntrinsicMetric)).height
        bottomSheet.view.frame = .init(x: 0, y: 0, width: 375, height: height)
        STPSnapshotVerifyView(bottomSheet.view)
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

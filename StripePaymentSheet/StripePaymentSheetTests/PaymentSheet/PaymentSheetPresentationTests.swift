//
//  PaymentSheetPresentationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/10/26.
//

@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import UIKit
import XCTest

#if !os(visionOS)
final class PaymentSheetPresentationTests: XCTestCase {

    @MainActor
    func testNativeSheetResizesToScrollableContentAtRegularWidth() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Trait overrides require iOS 17.") }
        // Given the regular-width presentation used by an unfolded phone
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        presenter.traitOverrides.horizontalSizeClass = .regular
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await AddressSpecProvider.shared.loadAddressSpecs()
        let paymentMethodTypes: [STPPaymentMethodType] = [
            .card, .cashApp, .klarna, .affirm, .USBankAccount, .afterpayClearpay, .payPal,
            .revolutPay, .alipay, .bancontact, .EPS, .iDEAL, .SEPADebit, .OXXO,
        ]
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: paymentMethodTypes),
            elementsSession: ._testValue(paymentMethodTypes: paymentMethodTypes.compactMap { STPPaymentMethod.string(from: $0) }),
            savedPaymentMethods: [],
            paymentMethodTypes: paymentMethodTypes.map { .stripe($0) },
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        var configuration = PaymentSheet.Configuration()
        configuration.applePay = nil
        configuration.link = .init(display: .never)
        let content = PaymentSheetVerticalViewController(
            configuration: configuration,
            loadResult: loadResult,
            isFlowController: false,
            analyticsHelper: ._testValue()
        )
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: "pi_test_secret_test", configuration: configuration)
        let sheet = NativeSheetContainerViewController(
            contentViewController: paymentSheet.loadingViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let presented = expectation(description: "Regular-width native sheet presented")

        // When replacing the loading spinner with content taller than the available sheet
        presenter.presentAsSheet(sheet) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)
        let presentedSheet = try XCTUnwrap(presenter.presentedViewController as? NativeSheetContainerViewController)
        let sheetPresentationController = try XCTUnwrap(presentedSheet.sheetPresentationController)
        XCTAssertEqual(sheetPresentationController.selectedDetentIdentifier, NativeSheetContainerViewController.contentDetentIdentifier)
        let contentVisible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            content.view.window != nil && content.view.alpha == 1
        }, object: nil)
        sheet.setViewControllers([content])

        // Then resizing completes, the viewport stays capped, and the app can dismiss the sheet
        await fulfillment(of: [contentVisible], timeout: 3)
        XCTAssertGreaterThan(sheet.scrollView.contentSize.height, sheet.scrollView.bounds.height)
        XCTAssertLessThanOrEqual(sheet.scrollView.frame.maxY, sheet.view.bounds.maxY + 0.5)
        let dismissed = expectation(description: "Regular-width native sheet dismissed")
        presenter.dismiss(animated: false) { dismissed.fulfill() }
        await fulfillment(of: [dismissed], timeout: 3)
    }

    @MainActor
    func testPresentAsSheetUsesNativeSheetBehavior() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = NativeSheetContainerViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        var presentedViewController: UIViewController?
        let presentingViewController = PresentationCapturingViewController {
            presentedViewController = $0
        }

        // When
        presentingViewController.presentAsSheet(sheetViewController)

        // Then
        XCTAssertIdentical(presentedViewController, sheetViewController)
        XCTAssertEqual(sheetViewController.modalPresentationStyle, .pageSheet)
        XCTAssertTrue(sheetViewController.isModalInPresentation)

        let sheetPresentationController = try XCTUnwrap(sheetViewController.sheetPresentationController)
        XCTAssertEqual(sheetPresentationController.detents.count, 1)
        if #available(iOS 16.0, *) {
            XCTAssertEqual(
                sheetPresentationController.detents.first?.identifier,
                NativeSheetContainerViewController.contentDetentIdentifier
            )
            XCTAssertEqual(
                sheetPresentationController.selectedDetentIdentifier,
                NativeSheetContainerViewController.contentDetentIdentifier
            )
        } else {
            XCTAssertEqual(sheetPresentationController.selectedDetentIdentifier, .large)
        }
        XCTAssertFalse(sheetPresentationController.prefersGrabberVisible)
        XCTAssertEqual(sheetPresentationController.preferredCornerRadius, sheetViewController.appearance.sheetCornerRadius)
        XCTAssertFalse(sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge)
        XCTAssertFalse(sheetPresentationController.prefersEdgeAttachedInCompactHeight)
    }

    @MainActor
    func testNativeSheetUsesItsOwnCornerRadius() throws {
        // Given a different legacy sheet's global appearance
        let previousAppearance = BottomSheetTransitioningDelegate.appearance
        defer { BottomSheetTransitioningDelegate.appearance = previousAppearance }
        BottomSheetTransitioningDelegate.appearance.sheetCornerRadius = 48
        let presenter = PresentationCapturingViewController { _ in }

        for radius: CGFloat in [0, 24] {
            var appearance = PaymentSheet.Appearance.default
            appearance.sheetCornerRadius = radius
            let sheet = NativeSheetContainerViewController(
                contentViewController: NativeSheetStubContentViewController(),
                appearance: appearance,
                isTestMode: true,
                didCancelNative3DS2: {}
            )

            // When presenting a native sheet
            presenter.presentAsSheet(sheet)

            // Then its own configured radius is applied, independently of the legacy global
            let presentationController = try XCTUnwrap(sheet.sheetPresentationController)
            XCTAssertEqual(presentationController.preferredCornerRadius, radius)
        }
    }

    @MainActor
    func testNativeSheetUsesOverriddenCornerRadius() throws {
        let sheet = LinkCornerRadiusSheetViewController(
            contentViewController: NativeSheetStubContentViewController(),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )

        PresentationCapturingViewController { _ in }.presentAsSheet(sheet)

        XCTAssertEqual(try XCTUnwrap(sheet.sheetPresentationController).preferredCornerRadius, LinkUI.largeCornerRadius)
    }

    @MainActor
    func testContentDetentMeasuresCurrentNavigationBar() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Content-sized detents are used on iOS 16 and later.") }
        let initialContent = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 70)
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        sheet.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        sheet.prepareForPresentation(in: 375)
        let context = SheetDetentResolutionContext()

        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: context)), 270, accuracy: 0.5)

        // When moving to content with a different bar, the detent measures the replacement
        sheet.pushContentViewController(MeasuredSheetContentViewController(contentHeight: 300, navigationBarHeight: 90))
        sheet.view.layoutIfNeeded()

        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: context)), 390, accuracy: 0.5)
    }

    @MainActor
    func testNativeGlassContentTracksActualNavigationBarHeight() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Glass navigation bars require iOS 26.") }
        var appearance = PaymentSheet.Appearance.default
        appearance.navigationBarStyle = .glass
        let initialContent = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 90, appearance: appearance)
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: appearance,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        sheet.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        sheet.prepareForPresentation(in: 375)

        XCTAssertEqual(initialContent.view.convert(.zero, to: sheet.scrollView).y, 90, accuracy: 0.5)

        let replacement = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 110, appearance: appearance)
        sheet.pushContentViewController(replacement)
        sheet.view.layoutIfNeeded()

        XCTAssertEqual(replacement.view.convert(.zero, to: sheet.scrollView).y, 110, accuracy: 0.5)
        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: SheetDetentResolutionContext())), 310, accuracy: 0.5)
    }

    @MainActor
    func testOffscreenContentReplacementDoesNotManufactureAppearanceCallbacks() async {
        // Given
        let content = NativeSheetStubContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: NativeSheetStubContentViewController(),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )

        // When replacing content before the sheet is presented
        sheet.setViewControllers([content])

        // Then UIKit has not yet delivered the content's first appearance
        XCTAssertEqual(content.didAppearCount, 0)

        // When presenting the prepared sheet
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presented = expectation(description: "Prepared content presented")
        presenter.presentAsSheet(sheet) { presented.fulfill() }

        // Then the content appears exactly once through UIKit's presentation
        await fulfillment(of: [presented], timeout: 3)
        XCTAssertEqual(content.didAppearCount, 1)
    }

    @MainActor
    func testPopReusesContainedContentViewController() {
        // Given
        let initialContent = NativeSheetStubContentViewController()
        let pushedContent = NativeSheetStubContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        sheet.pushContentViewController(pushedContent)
        XCTAssertIdentical(initialContent.parent, sheet)
        XCTAssertIdentical(pushedContent.parent, sheet)
        var completionCount = 0

        // When
        let poppedContent = sheet.popContentViewController {
            completionCount += 1
        }

        // Then the retained controller is reused without adding it as a child again
        XCTAssertIdentical(poppedContent, pushedContent)
        XCTAssertNil(pushedContent.parent)
        XCTAssertIdentical(initialContent.parent, sheet)
        XCTAssertEqual(sheet.children.count, 1)
        XCTAssertEqual(completionCount, 1)
    }

    @MainActor
    func testNativeSheetIgnoresInteractiveDismissalAttempts() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = NativeSheetContainerViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        var presentedViewController: UIViewController?
        PresentationCapturingViewController { presentedViewController = $0 }.presentAsSheet(sheetViewController)
        let presentationController = try XCTUnwrap(presentedViewController?.presentationController)
        let delegate = try XCTUnwrap(presentationController.delegate)

        // When UIKit requests interactive dismissal
        let shouldDismiss = delegate.presentationControllerShouldDismiss?(presentationController)

        // Then the sheet stays open without forwarding dismissal to its content
        XCTAssertEqual(shouldDismiss, false)
        XCTAssertEqual(contentViewController.dismissalAttemptCount, 0)

        // When UIKit reports a blocked swipe or outside-tap dismissal attempt
        delegate.presentationControllerDidAttemptToDismiss?(presentationController)

        // Then the content still receives no dismissal request
        XCTAssertEqual(contentViewController.dismissalAttemptCount, 0)
    }

    @MainActor
    func testSwitchingNestedContentInvalidatesContentDetent() {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = DetentInvalidationSpyViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let containerView = DynamicHeightContainerView()
        contentViewController.view.addSubview(containerView)
        contentViewController.add(
            childViewController: UIViewController(),
            containerView: containerView
        )

        // When
        contentViewController.switchContentIfNecessary(
            to: UIViewController(),
            containerView: containerView
        )

        // Then
        XCTAssertEqual(sheetViewController.invalidationCount, 1)
    }

    @MainActor
    func testSelectingVerticalPaymentMethodInvalidatesContentDetent() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = DetentInvalidationSpyViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let delegate = VerticalPaymentMethodListDelegateStub()
        let paymentMethodListViewController = VerticalPaymentMethodListViewController(
            initialSelection: nil,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.affirm)],
            shouldShowApplePay: false,
            shouldShowLink: false,
            savedPaymentMethodAccessoryType: nil,
            overrideHeaderView: nil,
            appearance: .default,
            currency: "usd",
            amount: 1_000,
            incentive: nil,
            delegate: delegate
        )
        contentViewController.addChild(paymentMethodListViewController)
        paymentMethodListViewController.didMove(toParent: contentViewController)
        let affirmRow = try XCTUnwrap(paymentMethodListViewController.rowButtons.first)

        // When
        paymentMethodListViewController.didTap(rowButton: affirmRow, selection: affirmRow.type)

        // Then
        XCTAssertEqual(sheetViewController.invalidationCount, 1)
    }

    @MainActor
    func testNativeSheetDoesNotAddBottomSafeAreaPadding() async throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Content-sized detents require iOS 16.") }
        // Given content whose existing bottom padding is included in its natural height
        let content = MeasuredSheetContentViewController(contentHeight: 200)
        let sheet = NativeSheetContainerViewController(
            contentViewController: content,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presented = expectation(description: "Content-sized native sheet presented")

        // When UIKit presents the sheet on a device with a home indicator
        presenter.presentAsSheet(sheet) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)
        sheet.view.layoutIfNeeded()

        // Then the content reaches the sheet's bottom, as it does in the legacy container
        XCTAssertEqual(sheet.scrollView.frame.maxY, sheet.view.bounds.maxY, accuracy: 0.5)
        let contentFrame = content.view.convert(content.view.bounds, to: sheet.view)
        XCTAssertEqual(contentFrame.maxY, sheet.view.bounds.maxY, accuracy: 0.5)
        XCTAssertEqual(sheet.scrollView.bounds.height, 200, accuracy: 0.5)
        let dismissed = expectation(description: "Native sheet dismissed")
        presenter.dismiss(animated: false) { dismissed.fulfill() }
        await fulfillment(of: [dismissed], timeout: 3)
    }

    @MainActor
    func testScrollViewAvoidsOnlyVisibleKeyboardArea() throws {
        // Given
        let sheetViewController = NativeSheetContainerViewController(
            contentViewController: NativeSheetStubContentViewController(),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )

        // When
        sheetViewController.loadViewIfNeeded()

        // Then
        let keyboardAvoidanceConstraint = try XCTUnwrap(sheetViewController.view.constraints.first {
            $0.firstItem === sheetViewController.scrollView
                && $0.firstAttribute == .bottom
                && $0.secondItem === sheetViewController.view.keyboardLayoutGuide
                && $0.secondAttribute == .top
        })
        XCTAssertEqual(keyboardAvoidanceConstraint.priority, .defaultLow)
    }
}

// Captures presentation configuration without starting a UIKit transition.
private final class PresentationCapturingViewController: UIViewController {

    private let presentationHandler: (UIViewController) -> Void

    init(presentationHandler: @escaping (UIViewController) -> Void) {
        self.presentationHandler = presentationHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentationHandler(viewControllerToPresent)
        completion?()
    }
}

private final class NativeSheetStubContentViewController: UIViewController, BottomSheetContentViewController {

    lazy var navigationBar = SheetNavigationBar(isTestMode: true, appearance: .default)
    let requiresFullScreen = false
    private(set) var dismissalAttemptCount = 0
    private(set) var didAppearCount = 0

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppearCount += 1
    }

    func didTapOrSwipeToDismiss() {
        dismissalAttemptCount += 1
    }
}

private final class DetentInvalidationSpyViewController: NativeSheetContainerViewController {

    private(set) var invalidationCount = 0

    override func invalidateContentDetent() {
        invalidationCount += 1
    }
}

private final class LinkCornerRadiusSheetViewController: NativeSheetContainerViewController {

    override var sheetCornerRadius: CGFloat? {
        LinkUI.largeCornerRadius
    }
}

private final class MeasuredSheetContentViewController: UIViewController, BottomSheetContentViewController {

    let navigationBar: SheetNavigationBar
    let requiresFullScreen = false
    private let contentHeight: CGFloat
    private(set) var didAppearCount = 0
    var onDidAppear: (() -> Void)?

    init(contentHeight: CGFloat = 200, navigationBarHeight: CGFloat = 52, appearance: PaymentSheet.Appearance = .default) {
        self.contentHeight = contentHeight
        navigationBar = FixedHeightSheetNavigationBar(height: navigationBarHeight, appearance: appearance)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppearCount += 1
        onDidAppear?()
    }

    func didTapOrSwipeToDismiss() {}
}

private final class FixedHeightSheetNavigationBar: SheetNavigationBar {

    private let height: CGFloat

    init(height: CGFloat, appearance: PaymentSheet.Appearance) {
        self.height = height
        super.init(isTestMode: true, appearance: appearance)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}

@available(iOS 16.0, *)
private final class SheetDetentResolutionContext: NSObject, UISheetPresentationControllerDetentResolutionContext {

    let containerTraitCollection = UITraitCollection()
    let maximumDetentValue: CGFloat = 1000
}

private final class VerticalPaymentMethodListDelegateStub: VerticalPaymentMethodListViewControllerDelegate {

    func willDisplayForm(_ rowButtonType: RowButtonType) -> Bool {
        return false
    }

    func didTapPaymentMethod(_ selection: RowButtonType) {}

    func didTapSavedPaymentMethodAccessoryButton() {}
}
#endif

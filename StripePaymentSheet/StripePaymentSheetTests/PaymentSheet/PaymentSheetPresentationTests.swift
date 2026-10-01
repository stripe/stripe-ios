//
//  PaymentSheetPresentationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/10/26.
//

@_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import UIKit
import XCTest

#if !os(visionOS)
final class PaymentSheetPresentationTests: XCTestCase {

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
        let navigationController = try XCTUnwrap(presentedViewController as? UINavigationController)
        XCTAssertIdentical(navigationController.topViewController, sheetViewController)
        XCTAssertIdentical(navigationController.bottomSheetController, sheetViewController)
        XCTAssertIdentical(contentViewController.navigationBar.systemNavigationItem, sheetViewController.navigationItem)
        XCTAssertEqual(navigationController.modalPresentationStyle, .automatic)

        let sheetPresentationController = try XCTUnwrap(navigationController.sheetPresentationController)
        XCTAssertIdentical(sheetPresentationController.delegate, sheetViewController)
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
        XCTAssertTrue(sheetPresentationController.prefersGrabberVisible)
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
        var presentedViewController: UIViewController?
        let presenter = PresentationCapturingViewController { presentedViewController = $0 }

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
            let presentationController = try XCTUnwrap(presentedViewController?.sheetPresentationController)
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

        var presentedViewController: UIViewController?
        PresentationCapturingViewController { presentedViewController = $0 }.presentAsSheet(sheet)

        XCTAssertEqual(try XCTUnwrap(presentedViewController?.sheetPresentationController).preferredCornerRadius, LinkUI.largeCornerRadius)
    }

    @MainActor
    func testContentDetentMeasuresSystemNavigationBar() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Content-sized detents are used on iOS 16 and later.") }
        // A taller legacy bar must not affect sizing once UIKit owns the navigation bar.
        let initialContent = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 70)
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let navigationController = UINavigationController(rootViewController: sheet)
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        sheet.prepareForPresentation(in: 375)
        let context = SheetDetentResolutionContext()
        let navigationBarHeight = navigationController.navigationBar.sizeThatFits(CGSize(width: 375, height: 0)).height

        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: context)), 200 + navigationBarHeight, accuracy: 0.5)

        // When moving to content with a different custom bar, only the UIKit bar contributes height
        sheet.pushContentViewController(MeasuredSheetContentViewController(contentHeight: 300, navigationBarHeight: 90))
        sheet.view.layoutIfNeeded()

        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: context)), 300 + navigationBarHeight, accuracy: 0.5)
        XCTAssertNil(initialContent.navigationBar.systemNavigationItem)
    }

    @MainActor
    func testNativeGlassContentUsesNavigationControllerSafeArea() throws {
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
        let navigationController = UINavigationController(rootViewController: sheet)
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        sheet.prepareForPresentation(in: 375)

        XCTAssertEqual(initialContent.view.convert(.zero, to: sheet.view).y, sheet.view.safeAreaLayoutGuide.layoutFrame.minY, accuracy: 0.5)

        let replacement = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 110, appearance: appearance)
        sheet.pushContentViewController(replacement)
        sheet.view.layoutIfNeeded()

        XCTAssertEqual(replacement.view.convert(.zero, to: sheet.view).y, sheet.view.safeAreaLayoutGuide.layoutFrame.minY, accuracy: 0.5)
        let navigationBarHeight = navigationController.navigationBar.sizeThatFits(CGSize(width: 375, height: 0)).height
        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: SheetDetentResolutionContext())), 200 + navigationBarHeight, accuracy: 0.5)
    }

    @MainActor
    func testEarlyContentUpdatesWaitForPresentationAndCoalesce() async throws {
        let initialContent = MeasuredSheetContentViewController()
        let skippedContent = MeasuredSheetContentViewController()
        let finalContent = MeasuredSheetContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presented = expectation(description: "Native sheet presentation completed")
        let updated = expectation(description: "Final content appeared once")
        updated.assertForOverFulfill = true
        var presentationCompleted = false
        finalContent.onDidAppear = {
            XCTAssertTrue(presentationCompleted)
            updated.fulfill()
        }

        // When loading changes the content twice during a real UIKit presentation
        presenter.presentAsSheet(sheet) {
            presentationCompleted = true
            presented.fulfill()
        }
        XCTAssertTrue(sheet.rootParent.isBeingPresented)
        sheet.setViewControllers([skippedContent])
        sheet.setViewControllers([finalContent])

        // Then the appearing child remains attached until UIKit has finished its transition
        XCTAssertIdentical(initialContent.parent, sheet)
        XCTAssertNil(skippedContent.parent)
        XCTAssertNil(finalContent.parent)
        await fulfillment(of: [presented, updated], timeout: 3)
        XCTAssertEqual(initialContent.didAppearCount, 1)
        XCTAssertEqual(skippedContent.didAppearCount, 0)
        XCTAssertEqual(finalContent.didAppearCount, 1)
        XCTAssertNil(initialContent.parent)
        XCTAssertIdentical(finalContent.parent, sheet)
    }

    @MainActor
    func testEarlyPushThenPopCompletesWithoutChangingVisibleContent() async {
        let initialContent = MeasuredSheetContentViewController()
        let skippedContent = MeasuredSheetContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let popped = expectation(description: "Pending pop completed exactly once")
        popped.assertForOverFulfill = true
        var presentationCompleted = false

        presenter.presentAsSheet(sheet) { presentationCompleted = true }
        sheet.pushContentViewController(skippedContent)
        XCTAssertIdentical(sheet.popContentViewController {
            XCTAssertTrue(presentationCompleted)
            popped.fulfill()
        }, skippedContent)

        await fulfillment(of: [popped], timeout: 3)
        XCTAssertEqual(initialContent.didAppearCount, 1)
        XCTAssertEqual(skippedContent.didAppearCount, 0)
        XCTAssertIdentical(initialContent.parent, sheet)
        XCTAssertNil(skippedContent.parent)
    }

    @MainActor
    func testEarlyPopKeepsAppearingChildAttachedUntilPresentationCompletes() async {
        let previousContent = MeasuredSheetContentViewController()
        let initialContent = MeasuredSheetContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: previousContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        sheet.pushContentViewController(initialContent)
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let popped = expectation(description: "Pop after native presentation")

        presenter.presentAsSheet(sheet)
        XCTAssertTrue(sheet.rootParent.isBeingPresented)
        _ = sheet.popContentViewController { popped.fulfill() }

        XCTAssertIdentical(initialContent.parent, sheet)
        await fulfillment(of: [popped], timeout: 3)
        XCTAssertNil(initialContent.parent)
        XCTAssertIdentical(previousContent.parent, sheet)
    }

    @MainActor
    func testOffscreenContentReplacementDoesNotManufactureAppearanceCallbacks() async {
        let content = MeasuredSheetContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: MeasuredSheetContentViewController(),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )

        sheet.setViewControllers([content])
        XCTAssertEqual(content.didAppearCount, 0)

        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presented = expectation(description: "Prepared content presented")
        presenter.presentAsSheet(sheet) { presented.fulfill() }

        await fulfillment(of: [presented], timeout: 3)
        XCTAssertEqual(content.didAppearCount, 1)
    }

    @MainActor
    func testInteractiveDismissalWaitsForDismissalAttemptToFinish() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = NativeSheetContainerViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        sheetViewController.modalPresentationStyle = .pageSheet
        let presentationController = try XCTUnwrap(sheetViewController.sheetPresentationController)

        // When
        let shouldDismiss = sheetViewController.presentationControllerShouldDismiss(presentationController)

        // Then
        XCTAssertFalse(shouldDismiss)
        XCTAssertEqual(contentViewController.dismissalAttemptCount, 0)

        // When
        sheetViewController.presentationControllerDidAttemptToDismiss(presentationController)

        // Then
        XCTAssertEqual(contentViewController.dismissalAttemptCount, 1)
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

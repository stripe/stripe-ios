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
        XCTAssertIdentical(presentedViewController, sheetViewController)
        XCTAssertEqual(sheetViewController.modalPresentationStyle, .pageSheet)
        XCTAssertTrue(sheetViewController.isModalInPresentation)

        let sheetPresentationController = try XCTUnwrap(sheetViewController.sheetPresentationController)
        XCTAssertEqual(sheetPresentationController.detents.count, 1)
        XCTAssertEqual(sheetPresentationController.selectedDetentIdentifier, .large)
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

            // Then its own configured radius is applied independently of the legacy global
            let presentationController = try XCTUnwrap(sheet.sheetPresentationController)
            XCTAssertEqual(presentationController.preferredCornerRadius, radius)
        }
    }

    @MainActor
    func testNativeSheetUsesOverriddenCornerRadius() throws {
        // Given
        let sheet = LinkCornerRadiusSheetViewController(
            contentViewController: NativeSheetStubContentViewController(),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )

        // When
        PresentationCapturingViewController { _ in }.presentAsSheet(sheet)

        // Then
        XCTAssertEqual(
            try XCTUnwrap(sheet.sheetPresentationController).preferredCornerRadius,
            LinkUI.largeCornerRadius
        )
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

private final class LinkCornerRadiusSheetViewController: NativeSheetContainerViewController {

    override var sheetCornerRadius: CGFloat? {
        LinkUI.largeCornerRadius
    }
}
#endif

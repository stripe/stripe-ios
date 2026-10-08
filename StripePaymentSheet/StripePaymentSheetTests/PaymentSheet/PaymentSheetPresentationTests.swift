//
//  PaymentSheetPresentationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/10/26.
//

@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
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
    func testNativeContentFitsBelowCurrentNavigationBar() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Content-sized detents are used on iOS 16 and later.") }
        var navigationBarStyles: [PaymentSheet.Appearance.NavigationBarStyle] = [.plain]
        if #available(iOS 26.0, *) {
            navigationBarStyles.append(.glass)
        }

        for navigationBarStyle in navigationBarStyles {
            // Given content below a custom navigation bar
            var appearance = PaymentSheet.Appearance.default
            appearance.navigationBarStyle = navigationBarStyle
            let initialContent = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 90, appearance: appearance)
            let sheet = NativeSheetContainerViewController(
                contentViewController: initialContent,
                appearance: appearance,
                didCancelNative3DS2: {}
            )
            sheet.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
            sheet.prepareForPresentation(in: 375)

            XCTAssertEqual(sheet.scrollView.frame.minY, 90, accuracy: 0.5)
            XCTAssertEqual(initialContent.view.convert(.zero, to: sheet.scrollView).y, 0, accuracy: 0.5)
            XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: SheetDetentResolutionContext())), 290, accuracy: 0.5)

            // When replacing the content with a taller navigation bar
            let replacement = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 110, appearance: appearance)
            sheet.pushContentViewController(replacement)
            sheet.view.layoutIfNeeded()

            // Then the content stays below the bar and its height is counted once
            XCTAssertEqual(sheet.scrollView.frame.minY, 110, accuracy: 0.5)
            XCTAssertEqual(replacement.view.convert(.zero, to: sheet.scrollView).y, 0, accuracy: 0.5)
            XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: SheetDetentResolutionContext())), 310, accuracy: 0.5)
        }
    }

    @MainActor
    func testNativeSheetIgnoresInteractiveDismissalAttempts() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = NativeSheetContainerViewController(
            contentViewController: contentViewController,
            appearance: .default,
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

    lazy var navigationBar = SheetNavigationBar(appearance: .default)
    let requiresFullScreen = false
    private(set) var dismissalAttemptCount = 0

    func didTapOrSwipeToDismiss() {
        dismissalAttemptCount += 1
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

    func didTapOrSwipeToDismiss() {}
}

private final class FixedHeightSheetNavigationBar: SheetNavigationBar {

    private let height: CGFloat

    init(height: CGFloat, appearance: PaymentSheet.Appearance) {
        self.height = height
        super.init(appearance: appearance)
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

#endif

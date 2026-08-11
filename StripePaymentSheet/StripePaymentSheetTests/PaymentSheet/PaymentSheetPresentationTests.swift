//
//  PaymentSheetPresentationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/10/26.
//

@testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import UIKit
import XCTest

final class PaymentSheetPresentationTests: XCTestCase {

    @MainActor
    func testPresentAsSheetUsesNativeSheetBehavior() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = PaymentSheetContainerViewController(
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

        let sheetPresentationController = try XCTUnwrap(sheetViewController.sheetPresentationController)
        XCTAssertEqual(sheetPresentationController.detents.count, 1)
        if #available(iOS 17.0, *) {
            XCTAssertEqual(
                sheetPresentationController.detents.first?.identifier,
                PaymentSheetContainerViewController.contentDetentIdentifier
            )
            XCTAssertEqual(
                sheetPresentationController.selectedDetentIdentifier,
                PaymentSheetContainerViewController.contentDetentIdentifier
            )
        } else {
            XCTAssertEqual(sheetPresentationController.selectedDetentIdentifier, .large)
        }
        XCTAssertTrue(sheetPresentationController.prefersGrabberVisible)
        XCTAssertNil(sheetPresentationController.preferredCornerRadius)
        XCTAssertFalse(sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge)
        XCTAssertFalse(sheetPresentationController.prefersEdgeAttachedInCompactHeight)
    }

    @MainActor
    func testInteractiveDismissalWaitsForDismissalAttemptToFinish() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = PaymentSheetContainerViewController(
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
        let sheetViewController = PaymentSheetContainerViewController(
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

private final class DetentInvalidationSpyViewController: PaymentSheetContainerViewController {

    private(set) var invalidationCount = 0

    override func invalidateContentDetent() {
        invalidationCount += 1
    }
}

private final class VerticalPaymentMethodListDelegateStub: VerticalPaymentMethodListViewControllerDelegate {

    func willDisplayForm(_ rowButtonType: RowButtonType) -> Bool {
        return false
    }

    func didTapPaymentMethod(_ selection: RowButtonType) {}

    func didTapSavedPaymentMethodAccessoryButton() {}
}

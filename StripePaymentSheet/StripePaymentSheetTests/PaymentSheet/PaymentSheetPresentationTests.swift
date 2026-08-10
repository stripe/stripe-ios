//
//  PaymentSheetPresentationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/10/26.
//

@testable import StripePaymentSheet
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
        XCTAssertEqual(sheetPresentationController.detents.count, 2)
        XCTAssertEqual(
            sheetPresentationController.detents.first?.identifier,
            PaymentSheetContainerViewController.contentDetentIdentifier
        )
        XCTAssertEqual(sheetPresentationController.detents.last?.identifier, .large)
        XCTAssertEqual(
            sheetPresentationController.selectedDetentIdentifier,
            PaymentSheetContainerViewController.contentDetentIdentifier
        )
        XCTAssertTrue(sheetPresentationController.prefersGrabberVisible)
        XCTAssertNil(sheetPresentationController.preferredCornerRadius)
        XCTAssertTrue(sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge)
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

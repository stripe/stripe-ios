//
//  PaneLayoutViewTests.swift
//  StripeFinancialConnections
//
//  Created by George Birch on 11/18/26.
//

@testable import StripeFinancialConnections
import UIKit
import XCTest

final class PaneLayoutViewTests: XCTestCase {

    func testKeepingFooterAboveKeyboardDoesNotBreakConstraints() throws {
        // Fail on any constraint UIKit breaks, using the callback behind the example app's broken-constraint alerts
        let selector = NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:")
        let method = try XCTUnwrap(class_getInstanceMethod(UIView.self, selector))
        let originalImplementation = method_getImplementation(method)
        typealias ConstraintCallback = @convention(c) (UIView, Selector, AnyObject, NSLayoutConstraint, NSArray) -> Void
        let originalCallback = unsafeBitCast(originalImplementation, to: ConstraintCallback.self)
        let callback: @convention(block) (UIView, AnyObject, NSLayoutConstraint, NSArray) -> Void = { view, engine, constraint, conflicts in
            XCTFail("Broken constraint: \(constraint)")
            originalCallback(view, selector, engine, constraint, conflicts)
        }
        let implementation = imp_implementationWithBlock(callback)
        method_setImplementation(method, implementation)
        defer {
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(implementation)
        }

        // Given a full-width pane in the key window that keeps its footer above the keyboard
        // (PaneLayoutView treats a pane narrower than the key window as a form sheet and leaves its footer alone)
        let windowScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = windowScene.map { UIWindow(windowScene: $0) } ?? UIWindow()
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let containerView: UIView = viewController.view
        let footerView = UIView()
        footerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        let paneLayoutView = PaneLayoutView(contentView: UIView(), footerView: footerView, keepFooterAboveKeyboard: true)
        paneLayoutView.addTo(view: containerView)
        containerView.layoutIfNeeded()
        let safeAreaBottom = containerView.safeAreaLayoutGuide.layoutFrame.maxY

        // When the keyboard shows
        let keyboardHeight: CGFloat = 300
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(
                    cgRect: CGRect(x: 0, y: window.bounds.height - keyboardHeight, width: window.bounds.width, height: keyboardHeight)
                ),
            ]
        )
        containerView.layoutIfNeeded()

        // Then the footer moves above the keyboard, overlapping it only by the footer's own padding
        let footerBottomAboveKeyboard = safeAreaBottom - (keyboardHeight - Constants.Layout.defaultVerticalPadding * 2)
        XCTAssertEqual(footerView.convert(footerView.bounds, to: containerView).maxY, footerBottomAboveKeyboard, accuracy: 0.5)

        // When the keyboard hides
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil, userInfo: [:])
        containerView.layoutIfNeeded()

        // Then the footer returns to the bottom of the pane
        XCTAssertEqual(footerView.convert(footerView.bounds, to: containerView).maxY, safeAreaBottom, accuracy: 0.5)
    }
}

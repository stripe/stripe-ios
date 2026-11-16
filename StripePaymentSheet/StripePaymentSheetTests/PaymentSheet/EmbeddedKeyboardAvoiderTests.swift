//
//  EmbeddedKeyboardAvoiderTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import UIKit
import XCTest

@MainActor
final class EmbeddedKeyboardAvoiderTests: XCTestCase {
    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        window = UIWindow.makeForTesting()
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        super.tearDown()
    }

    // MARK: - Geometry

    private let screen = EmbeddedKeyboardAvoider.ScrollGeometry(boundsHeight: 800, contentOffsetY: 0, contentHeight: 2000, adjustedInsetTop: 0, adjustedInsetBottom: 0)

    func testVisibleTargetNeedsNoAdjustment() {
        let plan = EmbeddedKeyboardAvoider.plan(geometry: screen, target: CGRect(x: 0, y: 100, width: 300, height: 100), keyboardMinY: 500, margin: 16)
        XCTAssertNil(plan)
    }

    func testTargetBehindTheKeyboardScrollsUpAboveIt() {
        // A target from 450 to 550 with the keyboard starting at 500 scrolls until its bottom margin clears 500
        let plan = EmbeddedKeyboardAvoider.plan(geometry: screen, target: CGRect(x: 0, y: 450, width: 300, height: 100), keyboardMinY: 500, margin: 16)
        XCTAssertEqual(plan, .init(contentOffsetY: 66, extraBottomInset: 0))
    }

    func testTargetAboveTheVisibleAreaScrollsDown() {
        var geometry = screen
        geometry.contentOffsetY = 300
        geometry.adjustedInsetTop = 100
        let plan = EmbeddedKeyboardAvoider.plan(geometry: geometry, target: CGRect(x: 0, y: 350, width: 300, height: 50), keyboardMinY: .greatestFiniteMagnitude, margin: 16)
        XCTAssertEqual(plan, .init(contentOffsetY: 234, extraBottomInset: 0))
    }

    func testTooTallTargetKeepsItsTopVisible() {
        let plan = EmbeddedKeyboardAvoider.plan(geometry: screen, target: CGRect(x: 0, y: 400, width: 300, height: 600), keyboardMinY: 500, margin: 16)
        XCTAssertEqual(plan, .init(contentOffsetY: 384, extraBottomInset: 0))
    }

    func testShortContentGetsTemporaryBottomInset() {
        // The content can't scroll at all, so the whole scroll distance comes from added inset
        var geometry = screen
        geometry.contentHeight = 800
        let plan = EmbeddedKeyboardAvoider.plan(geometry: geometry, target: CGRect(x: 0, y: 650, width: 300, height: 100), keyboardMinY: 500, margin: 16)
        XCTAssertEqual(plan, .init(contentOffsetY: 266, extraBottomInset: 266))
    }

    func testExistingKeyboardInsetIsRespected() {
        // A host that already insets for the keyboard, like SwiftUI, lets the content scroll that far without extra inset
        var geometry = screen
        geometry.contentHeight = 800
        geometry.adjustedInsetBottom = 344
        let plan = EmbeddedKeyboardAvoider.plan(geometry: geometry, target: CGRect(x: 0, y: 650, width: 300, height: 100), keyboardMinY: 500, margin: 16)
        XCTAssertEqual(plan?.extraBottomInset, 0)
    }

    func testCanFit() {
        XCTAssertTrue(EmbeddedKeyboardAvoider.canFit(targetHeight: 200, margin: 16, visibleTop: 100, visibleBottom: 332))
        XCTAssertFalse(EmbeddedKeyboardAvoider.canFit(targetHeight: 200, margin: 16, visibleTop: 100, visibleBottom: 331))
    }

    // MARK: - Decision

    func testDecidesInlineInsideAScrollView() {
        let target = addTarget(height: 200, at: 700, inScrollView: true)
        XCTAssertEqual(EmbeddedKeyboardAvoider(targetView: target, accessoryHeight: 44).decide(), .inline)
    }

    func testDecidesDialogWithoutAScrollViewWhenTheKeyboardWouldCoverTheTarget() {
        let low = addTarget(height: 200, at: 600, inScrollView: false)
        XCTAssertEqual(EmbeddedKeyboardAvoider(targetView: low, accessoryHeight: 44).decide(), .dialog(.noScrollView))

        let high = addTarget(height: 200, at: 80, inScrollView: false)
        XCTAssertEqual(EmbeddedKeyboardAvoider(targetView: high, accessoryHeight: 44).decide(), .inline)
    }

    func testDecidesDialogWhenTheTargetCanNotFitAboveTheKeyboard() {
        let target = addTarget(height: 600, at: 100, inScrollView: true)
        XCTAssertEqual(EmbeddedKeyboardAvoider(targetView: target, accessoryHeight: 44).decide(), .dialog(.doesNotFit))
    }

    func testDecidesDialogOutsideAWindow() {
        XCTAssertEqual(EmbeddedKeyboardAvoider(targetView: UIView(), accessoryHeight: 44).decide(), .dialog(.notInWindow))
    }

    // MARK: - Adjusting

    func testScrollsAboveTheKeyboardAndRemovesItsInsetAfterwards() throws {
        // Given a target at the bottom of content that can't scroll on its own
        let target = addTarget(height: 150, at: 650, inScrollView: true, contentHeight: 844)
        let scrollView = try XCTUnwrap(target.superview as? UIScrollView)
        let avoider = EmbeddedKeyboardAvoider(targetView: target, accessoryHeight: 44)

        // When the keyboard appears
        avoider.activate()
        postKeyboardFrame(CGRect(x: 0, y: 500, width: 390, height: 344))

        // Then the content scrolls until the target sits above it, with inset added to make room
        XCTAssertEqual(scrollView.contentOffset.y, 316, accuracy: 0.5)
        XCTAssertEqual(scrollView.contentInset.bottom, 316, accuracy: 0.5)

        // When editing ends
        avoider.deactivate()

        // Then the added inset is removed
        XCTAssertEqual(scrollView.contentInset.bottom, 0, accuracy: 0.5)
        XCTAssertFalse(avoider.isActive)
    }

    func testAKeyboardFrameTheWindowCanNotPlaceIsIgnored() throws {
        // Given a window without a scene, which can't convert the keyboard's screen frame
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let scrollView = UIScrollView(frame: window.bounds)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentSize = window.bounds.size
        let target = UIView(frame: CGRect(x: 0, y: 650, width: 390, height: 150))
        scrollView.addSubview(target)
        window.addSubview(scrollView)
        let avoider = EmbeddedKeyboardAvoider(targetView: target, accessoryHeight: 44)

        // When a keyboard frame arrives
        avoider.activate()
        postKeyboardFrame(CGRect(x: 0, y: 500, width: 390, height: 344))
        avoider.deactivate()

        // Then nothing moves, and the next prediction isn't thrown off: a target near the top of a scene-backed window still fits
        XCTAssertEqual(scrollView.contentOffset.y, 0)
        XCTAssertEqual(EmbeddedKeyboardAvoider(targetView: addTarget(height: 200, at: 100, inScrollView: true), accessoryHeight: 44).decide(), .inline)
    }

    func testIgnoresTheKeyboardUntilActivated() throws {
        let target = addTarget(height: 150, at: 650, inScrollView: true, contentHeight: 844)
        let scrollView = try XCTUnwrap(target.superview as? UIScrollView)
        _ = EmbeddedKeyboardAvoider(targetView: target, accessoryHeight: 44)
        postKeyboardFrame(CGRect(x: 0, y: 500, width: 390, height: 344))
        XCTAssertEqual(scrollView.contentOffset.y, 0)
        XCTAssertEqual(scrollView.contentInset.bottom, 0)
    }

    // MARK: - Helpers

    /// Adds a target view at a vertical position in the window, inside a full-window scroll view or directly in the window.
    private func addTarget(height: CGFloat, at y: CGFloat, inScrollView: Bool, contentHeight: CGFloat = 2000) -> UIView {
        let target = UIView(frame: CGRect(x: 0, y: y, width: 390, height: height))
        if inScrollView {
            let scrollView = UIScrollView(frame: window.bounds)
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.contentSize = CGSize(width: 390, height: contentHeight)
            scrollView.addSubview(target)
            window.addSubview(scrollView)
        } else {
            window.addSubview(target)
        }
        return target
    }

    private func postKeyboardFrame(_ frame: CGRect) {
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: frame,
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
                UIResponder.keyboardAnimationCurveUserInfoKey: UIView.AnimationCurve.easeInOut.rawValue,
            ]
        )
    }
}

extension UIWindow {
    /// A phone-sized window attached to the test host's scene, so it can convert screen coordinates like the keyboard's frame.
    @MainActor
    static func makeForTesting() -> UIWindow {
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow()
        }
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        return window
    }
}

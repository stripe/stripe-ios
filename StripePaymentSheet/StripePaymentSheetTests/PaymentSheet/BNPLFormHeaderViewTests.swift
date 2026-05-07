//
//  BNPLFormHeaderViewTests.swift
//  StripePaymentSheetTests
//

import XCTest
import UIKit

@_spi(STP) @testable import StripePaymentSheet

@MainActor
final class BNPLFormHeaderViewTests: XCTestCase {

    func testAlwaysDarkStyle_AppliesToHeaderAndInfoModal() throws {
        let (headerView, rootViewController, _) = makeHeaderView(style: .alwaysDark)

        XCTAssertEqual(headerView.overrideUserInterfaceStyle, .dark)

        let didHandleTap = headerView.textView(
            UITextView(),
            shouldInteractWith: headerView.infoUrl,
            in: NSRange(location: 0, length: 0),
            interaction: .invokeDefaultAction
        )

        XCTAssertFalse(didHandleTap)

        let infoModal = try XCTUnwrap(rootViewController.presentedViewController as? PMMEInfoModal)
        infoModal.loadViewIfNeeded()
        XCTAssertEqual(infoModal.overrideUserInterfaceStyle, .dark)
    }

    func testAlwaysLightStyle_AppliesToHeaderAndInfoModal() throws {
        let (headerView, rootViewController, _) = makeHeaderView(style: .alwaysLight)

        XCTAssertEqual(headerView.overrideUserInterfaceStyle, .light)

        let didHandleTap = headerView.textView(
            UITextView(),
            shouldInteractWith: headerView.infoUrl,
            in: NSRange(location: 0, length: 0),
            interaction: .invokeDefaultAction
        )

        XCTAssertFalse(didHandleTap)

        let infoModal = try XCTUnwrap(rootViewController.presentedViewController as? PMMEInfoModal)
        infoModal.loadViewIfNeeded()
        XCTAssertEqual(infoModal.overrideUserInterfaceStyle, .light)
    }

    private func makeHeaderView(
        style: PaymentSheet.UserInterfaceStyle
    ) -> (BNPLFormHeaderView, UIViewController, UIWindow) {
        let headerView = BNPLFormHeaderView(
            appearance: .default,
            style: style,
            promotion: "Split your purchase into monthly payments",
            learnMoreText: "Learn more",
            infoUrl: URL(string: "https://example.com/affirm")!
        )
        let rootViewController = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        UIView.setAnimationsEnabled(false)
        addTeardownBlock {
            UIView.setAnimationsEnabled(true)
            window.isHidden = true
        }

        rootViewController.view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
        ])
        rootViewController.view.layoutIfNeeded()

        return (headerView, rootViewController, window)
    }
}

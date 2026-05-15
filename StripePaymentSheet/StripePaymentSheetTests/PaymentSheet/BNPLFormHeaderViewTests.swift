//
//  BNPLFormHeaderViewTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

@MainActor
final class BNPLFormHeaderViewTests: STPSnapshotTestCase {
    func testDefaultAppearance() {
        let (headerView, _, _) = makeHeaderView()

        verify(headerView)
    }

    func testAlwaysDarkStyleSnapshot() {
        let (headerView, _, _) = makeHeaderView(style: .alwaysDark)

        verify(headerView)
    }

    func testCustomAppearance() {
        var appearance = PaymentSheet.Appearance.default
        appearance.colors.background = .systemYellow.withAlphaComponent(0.15)
        appearance.colors.primary = .systemGreen
        appearance.colors.text = .systemBrown

        let (headerView, _, _) = makeHeaderView(appearance: appearance)

        verify(headerView)
    }

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
        appearance: PaymentSheet.Appearance = .default,
        style: PaymentSheet.UserInterfaceStyle = .automatic
    ) -> (BNPLFormHeaderView, UIViewController, UIWindow) {
        let headerView = BNPLFormHeaderView(
            appearance: appearance,
            style: style,
            promotion: "Split your purchase into monthly payments",
            learnMoreText: "Learn more",
            infoUrl: URL(string: "https://example.com/affirm")!
        )
        let rootViewController = UIViewController()
        headerView.backgroundColor = appearance.colors.background
        rootViewController.view.backgroundColor = appearance.colors.background
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

    private func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 320)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

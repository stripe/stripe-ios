//
//  BNPLFormHeaderViewTests.swift
//  StripePaymentSheetTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

@MainActor
final class BNPLFormHeaderViewTests: XCTestCase {
    func testDarkMode_AppliesToInfoModal() throws {
        let (headerView, rootViewController, _) = makeHeaderView(interfaceStyle: .dark)

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

    func testLightMode_AppliesToInfoModal() throws {
        let (headerView, rootViewController, _) = makeHeaderView(interfaceStyle: .light)

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
        interfaceStyle: UIUserInterfaceStyle = .unspecified
    ) -> (BNPLFormHeaderView, UIViewController, UIWindow) {
        let promotionsHelper = PaymentMethodMessagingPromotionsHelper._testValueInTreatment()
        let headerView = BNPLFormHeaderView(
            appearance: appearance,
            paymentMethod: .stripe(.affirm),
            promotionsHelper: promotionsHelper
        )!
        let rootViewController = UIViewController()
        rootViewController.overrideUserInterfaceStyle = interfaceStyle
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
}

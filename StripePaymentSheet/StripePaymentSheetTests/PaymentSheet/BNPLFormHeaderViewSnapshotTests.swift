//
//  BNPLFormHeaderViewSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@_spi(STP) import StripeUICore
import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

@MainActor
final class BNPLFormHeaderViewSnapshotTests: STPSnapshotTestCase {
    func testDefaultAppearance() {
        let (headerView, _, _) = makeHeaderView()

        verify(headerView)
    }

    func testAlwaysDarkStyleSnapshot() {
        let (headerView, _, _) = makeHeaderView(interfaceStyle: .dark)

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

    private func makeHeaderView(
        appearance: PaymentSheet.Appearance = .default,
        interfaceStyle: UIUserInterfaceStyle = .unspecified
    ) -> (BNPLFormHeaderView, UIViewController, UIWindow) {
        let promotionsHelper = PaymentMethodMessagingPromotionsHelper._testValueInTreatment()
        let headerView = BNPLFormHeaderView(
            appearance: appearance,
            paymentMethod: .stripe(.affirm),
            promotionsHelper: promotionsHelper,
            fallback: SubtitleElement(view: UIView(), isHorizontalMode: false)
        )
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

//
//  WalletHeaderViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet

class WalletHeaderViewSnapshotTests: STPSnapshotTestCase {

    func testApplePayButton() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .applePay,
            delegate: nil
        )
        verify(headerView)
    }

    func testApplePayButtonWithCustomCta() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .applePay,
            applePayButtonType: .buy,
            delegate: nil
        )
        verify(headerView)
    }

    func testLinkButton() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .link,
            delegate: nil
        )
        verify(headerView)
    }

    // Tests UI elements that adapt their color based on the `PaymentSheet.Appearance`
    func testAdaptiveElements() {
        var darkMode = false

        var appearance = PaymentSheet.Appearance()
        appearance.colors.background = UIColor.init(dynamicProvider: { _ in
            if darkMode {
                return .black
            }

            return .white
        })

        appearance.cornerRadius = 0
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .applePay,
            appearance: appearance,
            delegate: nil
        )

        verify(headerView, identifier: "Light")

        darkMode = true
        headerView.traitCollectionDidChange(nil)

        verify(headerView, identifier: "Dark")
    }

    // Tests UI elements that adapt their color based on the `PaymentSheet.Appearance`
    func testAdaptiveElementsWithCustomApplePayCta() {
        var darkMode = false

        var appearance = PaymentSheet.Appearance()
        appearance.colors.background = UIColor.init(dynamicProvider: { _ in
            if darkMode {
                return .black
            }

            return .white
        })

        appearance.cornerRadius = 0
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .applePay,
            appearance: appearance,
            applePayButtonType: .buy,
            delegate: nil
        )

        verify(headerView, identifier: "Light")

        darkMode = true
        headerView.traitCollectionDidChange(nil)

        verify(headerView, identifier: "Dark")
    }

    func testAllButtons() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            delegate: nil
        )
        verify(headerView)

        headerView.showsCardPaymentMessage = true
        verify(headerView, identifier: "Card only")
    }

    func testAllButtonsWithCustomApplePayCta() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            applePayButtonType: .buy,
            delegate: nil
        )
        verify(headerView)

        headerView.showsCardPaymentMessage = true
        verify(headerView, identifier: "Card only")
    }

    func testCustomFont() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))

        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            appearance: appearance,
            delegate: nil
        )

        verify(headerView)
    }

    func testCustomFontScales() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        appearance.font.sizeScaleFactor = 1.25

        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            appearance: appearance,
            delegate: nil
        )

        verify(headerView)
    }

    func testCustomCornerRadius() {
        var appearance = PaymentSheet.Appearance.default
        appearance.cornerRadius = 14.5

        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            appearance: appearance,
            delegate: nil
        )

        verify(headerView)
    }

    func testAllButtonsSetupIntent() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            isPaymentIntent: false,
            delegate: nil
        )
        verify(headerView)

        headerView.showsCardPaymentMessage = true
        verify(headerView, identifier: "Card only")
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
